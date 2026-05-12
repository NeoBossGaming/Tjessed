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

          // Staleness check: skip entries that haven't been updated for > 30s
          int? oppTimestamp = oppData['Timestamp'] as int?;
          if (oppTimestamp != null) {
            int now = DateTime.now().millisecondsSinceEpoch;
            // Note: ServerValue.timestamp and local time might drift, but 30s is a safe margin
            if ((now - oppTimestamp).abs() > 30000) {
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
          // KEY FIX: Only the player whose UID sorts first creates the match.
          // The other player waits for MatchId via listenForMatch().
          // This prevents both players from racing to create the same match.
          if (player.uid.compareTo(bestOpponentId) < 0) {
            debugPrint(
                'I am the match creator (${player.uid} < $bestOpponentId)');
            await _createMatch(player, bestOpponentId);
          } else {
            debugPrint(
                'Waiting for opponent to create match ($bestOpponentId < ${player.uid})');
            // Do nothing — the other player will create the match
            // and our listenForMatch() stream will pick it up.
          }
        }
      } catch (e) {
        debugPrint('[MATCHMAKING] Search error: $e');
      }
    });
  }

  Future<void> _createMatch(PlayerModel player1, String player2) async {
    debugPrint('[MATCHMAKING] _createMatch called: ${player1.uid} vs $player2');
    // Stop searching immediately
    _isSearching = false;
    _queueSubscription?.cancel();
    _queueSubscription = null;
    _searchTimer?.cancel();
    _searchTimer = null;

    String matchId = _uuid.v4();

    try {
      debugPrint('[MATCHMAKING] Initiating transaction on opponent node: Matchmaking/$player2');
      // 1. Transaction only on opponent's node to prevent root null locks
      DatabaseReference oppRef = _db.ref('Matchmaking/$player2');
      
      final result = await oppRef.runTransaction((Object? value) {
        debugPrint('[MATCHMAKING] Transaction callback triggered. Value: $value');
        if (value == null) {
           debugPrint('[MATCHMAKING] Opponent node is null. Aborting to prevent data wipe.');
           return Transaction.abort();
        }
        if (value is! Map) {
          debugPrint('[MATCHMAKING] Opponent node is not a Map. Aborting.');
          return Transaction.abort();
        }

        Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value);
        if (data['Status'] != 'searching') {
          debugPrint('[MATCHMAKING] Opponent status is ${data['Status']}, not searching. Aborting.');
          return Transaction.abort();
        }

        data['Status'] = 'matched';
        data['MatchId'] = matchId;
        debugPrint('[MATCHMAKING] Transaction logic succeeding, returning new data.');
        return Transaction.success(data);
      });

      debugPrint('[MATCHMAKING] Transaction finished. Committed: ${result.committed}');
      
      // If result was successful but value was null, it means it returned null and committed the null, wiping out the node.
      // But we returned success(value) when null. If it was truly null on the server, it committed null (did nothing).
      // We must check if we actually wrote the 'matched' status.
      bool lockedOpponent = false;
      if (result.committed && result.snapshot.value is Map) {
        final snapData = result.snapshot.value as Map;
        if (snapData['MatchId'] == matchId) {
           lockedOpponent = true;
        }
      }

      if (lockedOpponent) {
        debugPrint('[MATCHMAKING] Successfully locked opponent. Creating match: $matchId');

        // 2. Update my own status
        await _db.ref('Matchmaking/${player1.uid}').update({
          'Status': 'matched',
          'MatchId': matchId,
        });

        debugPrint('[MATCHMAKING] Updated my own status to matched.');

        // 3. Initialize the match record
        await _db.ref('Matches/$matchId').set({
          "Black Player ID": player2,
          "White Player ID": player1.uid,
          "Game Status": "Active",
          "Moves": "",
          "Time Started": DateTime.now().toIso8601String(),
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
    } catch (e) {
      debugPrint('[MATCHMAKING] Match creation failed: $e');
      startSearching(player1);
    }
  }
}
