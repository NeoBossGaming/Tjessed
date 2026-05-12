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
  Timer? _searchTimer;
  bool _isSearching = false;

  /// Join the matchmaking queue
  Future<void> joinQueue(PlayerModel player) async {
    DatabaseReference ref = _db.ref('Matchmaking/${player.uid}');
    await ref.set({
      'Elo': player.elo,
      'Timestamp': ServerValue.timestamp,
      'Username': player.username,
      'Status': 'searching',
    });

    // Handle disconnecting while in queue
    ref.onDisconnect().remove();
  }

  /// Leave the matchmaking queue
  Future<void> leaveQueue(String uid) async {
    _isSearching = false;
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _searchTimer?.cancel();
    _searchTimer = null;
    try {
      await _db.ref('Matchmaking/$uid').remove();
    } catch (e) {
      debugPrint('Error leaving queue: $e');
    }
  }

  /// Listen for a match — waits for MatchId to appear on our node
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
    _isSearching = true;
    int searchRadius = GameConstants.eloMatchRange;
    final searchStartTime = DateTime.now();

    // Auto-cancel after 60 seconds to prevent zombie searches
    _searchTimer = Timer(const Duration(seconds: 60), () {
      debugPrint('Matchmaking timed out after 60 seconds');
      _isSearching = false;
      _queueSubscription?.cancel();
      _queueSubscription = null;
    });

    _queueSubscription =
        Stream.periodic(const Duration(seconds: 2)).listen((_) async {
      if (!_isSearching) {
        _queueSubscription?.cancel();
        return;
      }

      // Expand search radius if taking too long
      final elapsed = DateTime.now().difference(searchStartTime).inSeconds;
      if (elapsed > GameConstants.matchmakingTimeoutSeconds) {
        searchRadius = GameConstants.eloMatchExpandedRange;
      }

      try {
        DataSnapshot queueSnap = await _db.ref('Matchmaking').get();
        if (!queueSnap.exists || queueSnap.value == null) return;

        // Guard: value might not be a Map (e.g., if only one entry exists
        // and the node is structured oddly)
        if (queueSnap.value is! Map) return;

        Map<dynamic, dynamic> queue =
            queueSnap.value as Map<dynamic, dynamic>;

        String? bestOpponentId;
        int minEloDiff = 9999;

        for (var entry in queue.entries) {
          String oppId = entry.key.toString();
          if (oppId == player.uid) continue;

          // Guard: entry value might not be a Map
          if (entry.value is! Map) continue;
          Map<dynamic, dynamic> oppData = entry.value as Map<dynamic, dynamic>;

        // Staleness check: skip entries that haven't been updated for > 2 mins
          int? oppTimestamp = oppData['Timestamp'] as int?;
          if (oppTimestamp != null) {
            int now = DateTime.now().millisecondsSinceEpoch;
            // Increased margin to 2 minutes to handle clock drift
            if ((now - oppTimestamp).abs() > 120000) {
              continue; 
            }
          }

          // Only match with players who are still searching
          if (oppData['Status'] != 'searching') continue;

          int oppElo = oppData['Elo'] as int? ?? 1500;
          int eloDiff = (player.elo - oppElo).abs();

          if (eloDiff <= searchRadius && eloDiff < minEloDiff) {
            minEloDiff = eloDiff;
            bestOpponentId = oppId;
          }
        }

        if (bestOpponentId != null) {
          if (player.uid.compareTo(bestOpponentId) < 0) {
            String oppName = queue[bestOpponentId]?['Username'] ?? 'Opponent';
            debugPrint('[MATCHMAKING] I am the creator: ${player.uid} vs $bestOpponentId ($oppName)');
            await _createMatch(player, bestOpponentId, oppName);
          }
        }
      } catch (e) {
        debugPrint('[MATCHMAKING] Search error: $e');
      }
    });
  }

  Future<void> _createMatch(PlayerModel player1, String player2, String player2Name) async {
    _isSearching = false;
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _searchTimer?.cancel();
    _searchTimer = null;

    String matchId = _uuid.v4();
    debugPrint('[MATCHMAKING] Creating match $matchId for ${player1.uid} and $player2');

    try {
      DatabaseReference oppRef = _db.ref('Matchmaking/$player2');
      
      final result = await oppRef.runTransaction((Object? value) {
        // Handle the initial null when local cache is empty
        if (value == null) {
           return Transaction.success(value);
        }
        
        if (value is! Map) return Transaction.abort();

        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        if (data['Status'] != 'searching') {
          return Transaction.abort();
        }

        data['Status'] = 'matched';
        data['MatchId'] = matchId;
        return Transaction.success(data);
      });

      if (result.committed && result.snapshot.value is Map) {
        final snapData = result.snapshot.value as Map;
        if (snapData['MatchId'] == matchId) {
          // Successfully locked opponent
          await _db.ref('Matchmaking/${player1.uid}').update({
            'Status': 'matched',
            'MatchId': matchId,
          });

        debugPrint('[MATCHMAKING] Updated my own status to matched.');

        // 3. Initialize the match record
        await _db.ref('Matches/$matchId').set({
          "BlackID": player2,
          "BlackName": player2Name,
          "WhiteID": player1.uid,
          "WhiteName": player1.username,
          "GameStatus": "Active",
          "Moves": "",
          "TimeStarted": DateTime.now().toIso8601String(),
          "TimeLeftBlack": GameConstants.defaultTimeSeconds,
          "TimeLeftWhite": GameConstants.defaultTimeSeconds,
          "WonBy": "",
          "Mode": "powerup",
          "Powerups": {
            "White": {"held": [], "active": []},
            "Black": {"held": [], "active": []},
          },
          "FEN": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
          "Turn": "white",
          "MoveCount": 0,
        });
        
        debugPrint('[MATCHMAKING] Initialized match data in Matches/$matchId.');

        // Clean up matchmaking entries after match is created
        Future.delayed(const Duration(seconds: 3), () {
          debugPrint('[MATCHMAKING] Cleaning up Matchmaking nodes for ${player1.uid} and $player2.');
          _db.ref('Matchmaking/${player1.uid}').remove();
          _db.ref('Matchmaking/$player2').remove();
        });
      } else {
        debugPrint('[MATCHMAKING] Match transaction was not committed — opponent unavailable');
        // Restart searching properly since the stream was cancelled
        startSearching(player1);
      }
    } else {
      debugPrint('[MATCHMAKING] Transaction failed or snapshot empty');
      startSearching(player1);
    }
  } catch (e) {
    debugPrint('[MATCHMAKING] Match creation failed: $e');
    startSearching(player1);
  }
}
}
