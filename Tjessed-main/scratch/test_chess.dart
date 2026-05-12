import 'package:chess/chess.dart';

void main() {
  Chess game = Chess();
  
  // Test move returns bool
  var m1 = game.move({'from': 'e2', 'to': 'e4'});
  print('move() return: $m1 (${m1.runtimeType})');
  
  // History
  var h = game.history;
  var state = h.last;
  Move? mv = state.move;
  if (mv != null) {
    print('from: ${mv.fromAlgebraic}  to: ${mv.toAlgebraic}');
    print('piece: ${mv.piece}  captured: ${mv.captured}  promotion: ${mv.promotion}');
    print('flags: ${mv.flags}');
  }

  // generate_moves returns List<Move>
  var verboseMoves = game.generate_moves({'legal': true});
  print('\nTotal legal moves: ${verboseMoves.length}');
  if (verboseMoves.isNotEmpty) {
    Move first = verboseMoves.first;
    print('First: from=${first.fromAlgebraic} to=${first.toAlgebraic} piece=${first.piece}');
  }

  // Piece constructor order: Piece(PieceType, Color)
  game.put(Piece(PieceType.QUEEN, Color.WHITE), 'd5');
  var q = game.get('d5');
  print('\nPiece at d5: type=${q?.type} color=${q?.color}');
  
  var removed = game.remove('d5');
  print('Removed type: ${removed?.type}');

  // Check undo
  game.move({'from': 'e7', 'to': 'e5'});
  var undone = game.undo_move();
  print('\nUndo returned: $undone (${undone.runtimeType})');

  // moves() - string list
  var strMoves = game.moves();
  print('\nmoves() first 3: ${strMoves.take(3).toList()}');
  
  // FEN
  print('\nFEN: ${game.fen}');
  
  // Turn
  print('Turn: ${game.turn}  (Color.WHITE=${Color.WHITE}, Color.BLACK=${Color.BLACK})');
  
  // in_check, game_over
  print('in_check: ${game.in_check}  game_over: ${game.game_over}');
  
  // piece.type gives PieceType - how to compare?
  var p = game.get('e4');
  if (p != null) {
    print('\nPiece at e4 type: ${p.type}  is PAWN: ${p.type == PieceType.PAWN}');
    print('Type toString: ${p.type.toString()}');
    print('Type name: ${p.type.name}');
  }
}
