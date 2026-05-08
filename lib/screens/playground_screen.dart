import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import '../engine/chess_engine.dart';
import '../utils/constants.dart';
import '../widgets/chess_piece_widget.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_background.dart';
import 'game_screen.dart';

class PlaygroundScreen extends StatefulWidget {
  final String playerUid;
  const PlaygroundScreen({super.key, required this.playerUid});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final ChessEngine _engine = ChessEngine();
  String _selectedPalettePiece = 'p';
  String _selectedPaletteColor = 'white';

  @override
  void initState() {
    super.initState();
    _engine.loadFen('8/8/8/8/8/8/8/8 w - - 0 1'); // Start empty
  }

  void _resetBoard() {
    setState(() => _engine.reset());
  }

  void _clearBoard() {
    setState(() => _engine.loadFen('8/8/8/8/8/8/8/8 w - - 0 1'));
  }

  void _playVsAi(String color) {
    // Basic validation: must have both kings
    final pieces = _engine.getBoardPieces();
    bool whiteKing = pieces.values.any((p) => p.type == 'k' && p.color == 'white');
    bool blackKing = pieces.values.any((p) => p.type == 'k' && p.color == 'black');

    if (!whiteKing || !blackKing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both kings must be present on the board!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          matchId: 'PLAYGROUND_${DateTime.now().millisecondsSinceEpoch}',
          playerUid: widget.playerUid,
          isMultiplayer: false,
          initialFen: _engine.fen,
          playerColor: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Sandbox Playground', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Turn Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Side to move: ', style: AppTextStyles.body),
                    const SizedBox(width: 8),
                    ToggleButtons(
                      isSelected: [_engine.turnColor == 'white', _engine.turnColor == 'black'],
                      onPressed: (index) {
                        setState(() {
                          if (index == 0 && _engine.turnColor != 'white') _engine.swapTurn();
                          if (index == 1 && _engine.turnColor != 'black') _engine.swapTurn();
                        });
                      },
                      color: AppColors.textSecondary,
                      selectedColor: AppColors.background,
                      fillColor: AppColors.accentCyan,
                      borderRadius: BorderRadius.circular(8),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('WHITE')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('BLACK')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.boardBorder, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final squareSize = constraints.maxWidth / 8;
                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                              itemCount: 64,
                              itemBuilder: (context, index) {
                                final row = index ~/ 8;
                                final col = index % 8;
                                final square = gridToSquare(row, col);
                                final isLight = (row + col) % 2 == 0;
                                final piece = _engine.getPiece(square);

                                return DragTarget<Map<String, String>>(
                                  onAcceptWithDetails: (details) {
                                    setState(() {
                                      _engine.putPiece(details.data['type']!, details.data['color']!, square);
                                    });
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (piece != null) {
                                            _engine.removePiece(square);
                                          } else {
                                            _engine.putPiece(_selectedPalettePiece, _selectedPaletteColor, square);
                                          }
                                        });
                                      },
                                      child: Container(
                                        color: isLight ? AppColors.getBoardLight('Pastel') : AppColors.getBoardDark('Pastel'),
                                        child: piece != null
                                            ? ChessPieceWidget(pieceType: piece.type.name, color: piece.color == ch.Color.WHITE ? 'white' : 'black', size: squareSize * 0.9)
                                            : (candidateData.isNotEmpty ? Icon(Icons.add, color: AppColors.accentCyan.withAlpha(50)) : null),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Palette
              _buildPalette(),
              const SizedBox(height: 16),
              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearBoard,
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed),
                            child: const Text('CLEAR'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetBoard,
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary),
                            child: const Text('RESET'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _playVsAi('white'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.backgroundEnd, foregroundColor: AppColors.textPrimary),
                            child: const Text('PLAY AS WHITE'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _playVsAi('black'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.textPrimary, foregroundColor: AppColors.backgroundEnd),
                            child: const Text('PLAY AS BLACK'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPalette() {
    final pieceTypes = ['p', 'n', 'b', 'r', 'q', 'k'];
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['white', 'black'].map((c) {
              final isSelected = _selectedPaletteColor == c;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c.toUpperCase()),
                  selected: isSelected,
                  onSelected: (val) { if (val) setState(() => _selectedPaletteColor = c); },
                  selectedColor: AppColors.accentCyan.withAlpha(100),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: pieceTypes.map((t) {
              final isSelected = _selectedPalettePiece == t;
              return Draggable<Map<String, String>>(
                data: {'type': t, 'color': _selectedPaletteColor},
                feedback: Opacity(opacity: 0.8, child: ChessPieceWidget(pieceType: t, color: _selectedPaletteColor, size: 50)),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPalettePiece = t),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: isSelected ? Border.all(color: AppColors.accentCyan, width: 2) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ChessPieceWidget(pieceType: t, color: _selectedPaletteColor, size: 36),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
