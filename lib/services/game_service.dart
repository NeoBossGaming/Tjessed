import 'package:firebase_database/firebase_database.dart';
import '../models/powerup.dart';

class GameService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  late DatabaseReference _matchRef;

  void initialize(String matchId) {
    _matchRef = _db.ref('Matches/$matchId');
  }

  Stream<DatabaseEvent> streamMatchData() => _matchRef.onValue;

  Future<void> sendMove({
    required String fen,
    required String turn,
    required int timeLeftBlack,
    required int timeLeftWhite,
    String? lastMoveFrom,
    String? lastMoveTo,
  }) async {
    final updates = <String, dynamic>{
      'FEN': fen,
      'Turn': turn,
      'TimeLeftBlack': timeLeftBlack,
      'TimeLeftWhite': timeLeftWhite,
      'LastSync': ServerValue.timestamp,
    };
    if (lastMoveFrom != null) updates['LastMoveFrom'] = lastMoveFrom;
    if (lastMoveTo != null) updates['LastMoveTo'] = lastMoveTo;
    
    await _matchRef.update(updates);
  }

  Future<void> updatePowerups({
    required String color,
    required List<PowerupType> held,
    required List<ActiveEffect> active,
  }) async {
    final heldNames = held.map((p) => p.name).toList();
    final activeData = active.map((e) => e.toJson()).toList();
    final key = color == 'white' ? 'White' : 'Black';

    await _matchRef.child('Powerups/$key').update({
      'held': heldNames,
      'active': activeData,
    });
  }

  Future<void> endGame({required String status, required String wonBy}) async {
    await _matchRef.update({'GameStatus': status, 'WonBy': wonBy});
  }
}
