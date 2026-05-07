import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/player_model.dart';
import '../utils/constants.dart';

class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();
  
  StreamSubscription? _queueSubscription;

  /// Join the matchmaking queue
  Future<void> joinQueue(PlayerModel player) async {
    DatabaseReference ref = _db.ref('Matchmaking/${player.uid}');
    await ref.set({
      'Elo': player.elo,
      'Timestamp': ServerValue.timestamp,
      'Username': player.username,
      'Status': 'searching'
    });

    // Handle disconnecting while in queue
    ref.onDisconnect().remove();
  }

  /// Leave the matchmaking queue
  Future<void> leaveQueue(String uid) async {
    _queueSubscription?.cancel();
    await _db.ref('Matchmaking/$uid').remove();
  }

  /// Listen for a match
  Stream<String?> listenForMatch(String uid) {
    return _db.ref('Matchmaking/$uid/MatchId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return event.snapshot.value.toString();
      }
      return null;
    });
  }

  /// Periodically check for opponents in the queue
  void startSearching(PlayerModel player) {
    int searchRadius = GameConstants.eloMatchRange;
    int searchStartTime = DateTime.now().millisecondsSinceEpoch;

    _queueSubscription = Stream.periodic(const Duration(seconds: 3)).listen((_) async {
      // Expand search radius if taking too long
      int elapsed = DateTime.now().millisecondsSinceEpoch - searchStartTime;
      if (elapsed > GameConstants.matchmakingTimeoutSeconds * 1000) {
        searchRadius = GameConstants.eloMatchExpandedRange;
      }

      DataSnapshot queueSnap = await _db.ref('Matchmaking').get();
      if (!queueSnap.exists) return;

      Map<dynamic, dynamic> queue = queueSnap.value as Map<dynamic, dynamic>;
      
      String? bestOpponentId;
      int minEloDiff = 9999;

      for (var entry in queue.entries) {
        String oppId = entry.key;
        if (oppId == player.uid) continue;

        Map<dynamic, dynamic> oppData = entry.value;
        if (oppData['Status'] != 'searching') continue;

        int oppElo = oppData['Elo'] as int? ?? 1500;
        int eloDiff = (player.elo - oppElo).abs();

        if (eloDiff <= searchRadius && eloDiff < minEloDiff) {
          minEloDiff = eloDiff;
          bestOpponentId = oppId;
        }
      }

      if (bestOpponentId != null) {
        // Found an opponent, attempt to create match
        await _createMatch(player.uid, bestOpponentId);
      }
    });
  }

  Future<void> _createMatch(String player1, String player2) async {
    _queueSubscription?.cancel();

    // Use transaction to avoid race conditions
    DatabaseReference mRef = _db.ref('Matchmaking');
    
    bool success = false;
    String matchId = _uuid.v4();

    try {
      await mRef.runTransaction((Object? value) {
        // Firebase might call this with null initially even if data exists on the server.
        // We should return success(value) to allow it to retry with actual data.
        if (value == null) {
          return Transaction.success(value);
        }
        
        Map<dynamic, dynamic> queue;
        try {
          queue = Map<dynamic, dynamic>.from(value as Map);
        } catch (e) {
          debugPrint('Transaction failed: Invalid queue data format');
          return Transaction.abort();
        }
        
        // Ensure both players are still in queue and searching
        if (!queue.containsKey(player1) || !queue.containsKey(player2)) {
          debugPrint('Transaction failed: One or both players left the queue');
          return Transaction.abort();
        }
        
        var p1Data = queue[player1] as Map?;
        var p2Data = queue[player2] as Map?;

        if (p1Data == null || p2Data == null || 
            p1Data['Status'] != 'searching' || p2Data['Status'] != 'searching') {
          debugPrint('Transaction failed: Players are no longer searching');
          return Transaction.abort();
        }

        // Lock them
        p1Data['Status'] = 'matched';
        p2Data['Status'] = 'matched';
        p1Data['MatchId'] = matchId;
        p2Data['MatchId'] = matchId;

        success = true;
        return Transaction.success(queue);
      });

      if (success) {
        // Initialize the match record
        await _db.ref('Matches/$matchId').set({
          "Black Player ID": player2,
          "White Player ID": player1,
          "Game Status": "Active",
          "Moves": "",
          "Time Started": DateTime.now().toIso8601String(),
          "TimeLeftBlack": GameConstants.defaultTimeSeconds,
          "TimeLeftWhite": GameConstants.defaultTimeSeconds,
          "WonBy": "",
          "Mode": "powerup",
          "Powerups": {
            "White": {"held": [], "active": {}},
            "Black": {"held": [], "active": {}}
          },
          "FEN": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
          "Turn": "white",
          "MoveCount": 0
        });
      }
    } catch (e) {
      debugPrint('Match creation failed: $e');
    }
  }
}
