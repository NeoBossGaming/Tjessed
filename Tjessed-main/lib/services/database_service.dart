import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/player_model.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Get player profile by UID
  Future<PlayerModel?> getPlayerProfile(String uid) async {
    try {
      DataSnapshot snap = await _db.ref('Accounts/$uid').get();
      if (snap.exists && snap.value != null) {
        return PlayerModel.fromJson(uid, snap.value as Map<dynamic, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting player profile: $e');
      return null;
    }
  }

  /// Stream player profile updates
  Stream<PlayerModel?> streamPlayerProfile(String uid) {
    return _db.ref('Accounts/$uid').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return PlayerModel.fromJson(uid, event.snapshot.value as Map<dynamic, dynamic>);
      }
      return null;
    });
  }

  /// Update match stats (win/loss/played and Elo)
  Future<void> updateMatchStats({
    required String uid,
    required bool isWin,
    required bool isDraw,
    required int eloChange,
  }) async {
    DatabaseReference ref = _db.ref('Accounts/$uid');
    
    // Use transaction for atomic updates
    await ref.runTransaction((Object? value) {
      if (value == null) {
        return Transaction.abort();
      }

      Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(value as Map);
      
      data['Matches Played'] = (data['Matches Played'] as int? ?? 0) + 1;
      
      if (isWin) {
        data['Matches Won'] = (data['Matches Won'] as int? ?? 0) + 1;
      } else if (!isDraw) {
        data['Matches Lost'] = (data['Matches Lost'] as int? ?? 0) + 1;
      }

      int currentElo = data['Elo'] as int? ?? 1500;
      data['Elo'] = currentElo + eloChange;

      return Transaction.success(data);
    });
  }

  /// Update powerups used stat
  Future<void> incrementPowerupsUsed(String uid) async {
    DatabaseReference ref = _db.ref('Accounts/$uid/Stats/PowerupsUsed');
    await ref.runTransaction((Object? value) {
      int current = value as int? ?? 0;
      return Transaction.success(current + 1);
    });
  }

  /// Get leaderboard (top 50 players by Elo)
  Future<List<PlayerModel>> getLeaderboard() async {
    try {
      // Fetch top 50 by Elo. limitToLast returns highest values since they're sorted ASC.
      DataSnapshot snap = await _db.ref('Accounts')
          .orderByChild('Elo')
          .limitToLast(50)
          .get();
      
      if (snap.exists && snap.value != null) {
        Map<dynamic, dynamic> data = snap.value as Map<dynamic, dynamic>;
        List<PlayerModel> list = [];
        data.forEach((key, value) {
          list.add(PlayerModel.fromJson(key.toString(), value as Map<dynamic, dynamic>));
        });
        // Firebase returns in ascending order, we want descending for leaderboard
        list.sort((a, b) => b.elo.compareTo(a.elo));
        return list;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }
}
