import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import '../engine/chess_engine.dart';
import '../engine/powerup_engine.dart';
import '../engine/ai_engine.dart';
import '../services/game_service.dart';
import '../services/database_service.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/powerup_bar.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/timer_widget.dart';
import '../widgets/vfx_overlay.dart';
import '../widgets/particle_overlay.dart';
import '../widgets/animated_background.dart';
import '../widgets/card_reveal_overlay.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GAME SCREEN  (Singleplayer + Multiplayer)
// ─────────────────────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final String matchId;
  final String playerUid;
  final bool isMultiplayer;
  final String? initialFen;
  final String? playerColor;

  const GameScreen({
    super.key,
    required this.matchId,
    required this.playerUid,
    required this.isMultiplayer,
    this.initialFen,
    this.playerColor,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ── Engine & services ────────────────────────────────────────────────────────
  final ChessEngine _engine = ChessEngine();
  final PowerupEngine _powerupEngine = PowerupEngine();
  final AIEngine _aiEngine = AIEngine();
  final GameService _gameService = GameService();
  final DatabaseService _dbService = DatabaseService();

  // ── Board state ──────────────────────────────────────────────────────────────
  bool _isWhiteOrientation = true;
  String _myColor = 'white';
  String? _selectedSquare;
  List<String> _highlightedSquares = [];
  List<String> _lastMoveSquares = [];

  // ── Powerup state ────────────────────────────────────────────────────────────
  List<ActiveEffect> _activeEffects = [];
  List<PowerupType> _myPowerups = [];
  List<PowerupType> _opponentPowerups = [];
  final List<String> _myCapturedPieces = [];
  final List<String> _opponentCapturedPieces = [];
  PowerupType? _pendingTargetPowerup;

  // ── Timer ────────────────────────────────────────────────────────────────────
  int _myTimeLeft = GameConstants.defaultTimeSeconds;
  int _opponentTimeLeft = GameConstants.defaultTimeSeconds;
  Timer? _clockTimer;

  // ── Game status ──────────────────────────────────────────────────────────────
  bool _isGameOver = false;
  bool _hasLost = false;
  StreamSubscription? _matchSub;
  final List<TransientEffect> _recentEffects = [];
  final Uuid _uuid = const Uuid();

  void _addCaptureEffect(String square) {
    final rand = math.Random();
    final particles = List.generate(15, (_) {
      final angle = rand.nextDouble() * math.pi * 2;
      return Particle(
        math.cos(angle),
        math.sin(angle),
        rand.nextDouble() * 2 + 1,
        rand.nextDouble() * 4 + 2,
        AppColors.accentAmber,
      );
    });
    setState(() {
      _recentEffects.add(TransientEffect(
        id: _uuid.v4(),
        type: 'capture',
        square: square,
        particles: particles,
        lifespanMs: 600,
      ));
    });
  }

  void _addPowerupEffect(Color color, {String? square, int count = 20}) {
    final rand = math.Random();
    final particles = List.generate(count, (_) {
      final angle = rand.nextDouble() * math.pi * 2;
      return Particle(
        math.cos(angle),
        math.sin(angle),
        rand.nextDouble() * 2 + 1,
        rand.nextDouble() * 3 + 1,
        color,
      );
    });
    setState(() {
      _recentEffects.add(TransientEffect(
        id: _uuid.v4(),
        type: 'powerup',
        square: square,
        color: color,
        particles: particles,
        lifespanMs: 800,
      ));
    });
  }

  // ── Extra-move flag ─────────────────────────────────────────────────────────
  bool _hasExtraTurn = false;

  @override
  void initState() {
    super.initState();
    if (widget.isMultiplayer) {
      _setupMultiplayer();
    } else {
      _setupSingleplayer();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SETUP
  // ─────────────────────────────────────────────────────────────────────────────

  void _setupSingleplayer() {
    _myColor = widget.playerColor ?? 'white';
    _isWhiteOrientation = _myColor == 'white';
    if (widget.initialFen != null) {
      _engine.loadFen(widget.initialFen!);
    }
    _startClock();

    // If it's the AI's turn right from the start, trigger it.
    if (_engine.turnColor != _myColor) {
      Future.delayed(const Duration(milliseconds: 600), _doAiTurn);
    }
  }

  void _setupMultiplayer() {
    _gameService.initialize(widget.matchId);
    _matchSub = _gameService.streamMatchData().listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return;
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      // Determine my colour on first data
      if (data['Black Player ID'] == widget.playerUid && _myColor != 'black') {
        setState(() {
          _myColor = 'black';
          _isWhiteOrientation = false;
        });
      }

      final incomingFen = data['FEN'] as String?;
      if (incomingFen != null && incomingFen.isNotEmpty && incomingFen != _engine.fen) {
        _engine.loadFen(incomingFen);
      }

      setState(() {
        _myTimeLeft = data['TimeLeft${_myColor == 'white' ? 'White' : 'Black'}'] as int? ??
            GameConstants.defaultTimeSeconds;
        _opponentTimeLeft = data['TimeLeft${_myColor == 'white' ? 'Black' : 'White'}'] as int? ??
            GameConstants.defaultTimeSeconds;

        final status = data['Game Status'] as String? ?? 'Active';
        _isGameOver = status != 'Active';
        if (_isGameOver) _clockTimer?.cancel();

        // Sync powerups
        if (data['Powerups'] != null) {
          _parsePowerupsFromDb(data['Powerups'] as Map<dynamic, dynamic>);
        }
      });

      if (!_isGameOver) _startClock();
    });
  }

  void _parsePowerupsFromDb(Map<dynamic, dynamic> pData) {
    final myKey = _myColor == 'white' ? 'White' : 'Black';
    final oppKey = _myColor == 'white' ? 'Black' : 'White';

    _myPowerups = _parseHeld(pData[myKey]);
    _opponentPowerups = _parseHeld(pData[oppKey]);

    _activeEffects.clear();
    for (final k in ['White', 'Black']) {
      final active = pData[k]?['active'];
      if (active is List) {
        for (var a in active) {
          if (a is Map) _activeEffects.add(ActiveEffect.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
  }

  List<PowerupType> _parseHeld(dynamic data) {
    if (data == null) return [];
    final held = data['held'];
    if (held is! List) return [];
    return held
        .map((n) => PowerupType.fromName(n as String))
        .whereType<PowerupType>()
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CLOCK
  // ─────────────────────────────────────────────────────────────────────────────

  void _startClock() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isGameOver) { t.cancel(); return; }
      setState(() {
        if (_engine.turnColor == _myColor) {
          if (--_myTimeLeft <= 0) _handleGameOver('timeout_me');
        } else {
          if (--_opponentTimeLeft <= 0) _handleGameOver('timeout_opp');
        }
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SQUARE TAPS & MOVES
  // ─────────────────────────────────────────────────────────────────────────────

  void _handleSquareTap(String square) {
    if (_isGameOver) return;
    if (!widget.isMultiplayer && _engine.turnColor != _myColor) return; // Wait for AI
    if (widget.isMultiplayer && _engine.turnColor != _myColor) return;

    // Targeted powerup pending
    if (_pendingTargetPowerup != null) {
      _executePowerup(_pendingTargetPowerup!, targetSquare: square);
      setState(() { _pendingTargetPowerup = null; });
      return;
    }

    final piece = _engine.getPiece(square);

    if (_selectedSquare == null) {
      // Select a piece of ours
      if (piece != null && _isPieceOurs(piece)) {
        setState(() {
          _selectedSquare = square;
          _highlightedSquares = _engine.getLegalDestinations(square, activeEffects: _activeEffects);
        });
      }
    } else {
      if (_highlightedSquares.contains(square)) {
        // Check pawn promotion
        String? promo;
        final selPiece = _engine.getPiece(_selectedSquare!);
        if (selPiece != null && selPiece.type.name == 'p') {
          final toRank = int.parse(square[1]);
          if (toRank == 1 || toRank == 8) promo = 'q'; // Auto-queen for now
        }
        _executeMove(_selectedSquare!, square, promo);
      } else if (piece != null && _isPieceOurs(piece)) {
        // Re-select
        setState(() {
          _selectedSquare = square;
          _highlightedSquares = _engine.getLegalDestinations(square, activeEffects: _activeEffects);
        });
      } else {
        setState(() { _selectedSquare = null; _highlightedSquares = []; });
      }
    }
  }

  bool _isPieceOurs(ch.Piece piece) =>
      (piece.color == ch.Color.WHITE) == (_myColor == 'white');

  String _offsetToSquare(Offset localPos, double boardSize) {
    final sqSize = boardSize / 8;
    int col = (localPos.dx / sqSize).floor().clamp(0, 7);
    int row = (localPos.dy / sqSize).floor().clamp(0, 7);
    if (!_isWhiteOrientation) {
      row = 7 - row;
      col = 7 - col;
    }
    final file = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rank = 8 - row;
    return '$file$rank';
  }

  void _executeMove(String from, String to, String? promo) {
    final move = _engine.makeMove(from, to, promotion: promo);
    if (move == null) return;

    setState(() {
      _selectedSquare = null;
      _highlightedSquares = [];
      _lastMoveSquares = [from, to];
    });

    // Powerup roll on capture
    final captured = move.captured;
    if (captured != null) {
      _addCaptureEffect(to);
      _myCapturedPieces.add(captured.toString());
      final newPu = _powerupEngine.rollPowerup(captured.toString());
      if (newPu != null && _myPowerups.length < GameConstants.maxPowerupsHeld) {
        setState(() => _myPowerups.add(newPu));
        showCardReveal(context, newPu);
        _addPowerupEffect(newPu.tier.color, square: to, count: newPu.tier.level * 10 + 10);
      }
    }

    // Tick down effects and handle expirations (e.g., Crown Thief restore)
    final expiring = _activeEffects.where((e) => e.turnsRemaining <= 1).toList();
    setState(() => _activeEffects = PowerupEngine.tickEffects(_activeEffects));
    PowerupEngine.handleExpiredEffects(expiring, _engine);

    // Extra turn handling
    if (_hasExtraTurn) {
      _engine.swapTurn(); // Take turn back
      setState(() => _hasExtraTurn = false);
      _showSnack('Extra Turn!', AppColors.accentCyan);
    }

    if (_engine.gameOver) { _handleGameOver('checkmate'); return; }

    _syncState();
    if (!widget.isMultiplayer && _engine.turnColor != _myColor) {
      Future.delayed(const Duration(milliseconds: 600), _doAiTurn);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AI TURN
  // ─────────────────────────────────────────────────────────────────────────────

  void _doAiTurn() {
    if (_isGameOver || _engine.turnColor == _myColor) return;

    // AI powerup usage
    bool aiGetsExtraTurn = false;
    final aiPu = _aiEngine.decidePowerupUsage(_opponentPowerups, _engine);
    if (aiPu != null && !aiPu.isTargeted) {
      _addPowerupEffect(aiPu.tier.color); // Spawns in center
      setState(() => _opponentPowerups.remove(aiPu));
      final res = _powerupEngine.applyPowerup(
        type: aiPu,
        engine: _engine,
        playerColor: _myColor == 'white' ? 'black' : 'white',
      );
      if (res.activeEffect != null) setState(() => _activeEffects.add(res.activeEffect!));
      if (res.timeBonus > 0) setState(() => _opponentTimeLeft += res.timeBonus);
      if (aiPu == PowerupType.freeze || aiPu == PowerupType.doubleMove) {
        aiGetsExtraTurn = true;
      }
    }

    final best = _aiEngine.getBestMove(_engine);
    if (best == null) return;

    final move = _engine.makeMove(best.from, best.to);
    if (move == null) return;

    setState(() => _lastMoveSquares = [best.from, best.to]);

    final captured = move.captured;
    if (captured != null) {
      _addCaptureEffect(best.to);
      _opponentCapturedPieces.add(captured.toString());
      final newPu = _powerupEngine.rollPowerup(captured.toString());
      if (newPu != null && _opponentPowerups.length < GameConstants.maxPowerupsHeld) {
        setState(() => _opponentPowerups.add(newPu));
        _addPowerupEffect(newPu.tier.color, square: best.to, count: newPu.tier.level * 10 + 10);
      }
    }

    setState(() => _activeEffects = PowerupEngine.tickEffects(_activeEffects));
    if (_engine.gameOver) { _handleGameOver('checkmate'); return; }

    if (aiGetsExtraTurn) {
      _engine.swapTurn(); // Take turn back for AI
      _showSnack('Opponent takes an extra turn!', AppColors.accentRed);
      Future.delayed(const Duration(milliseconds: 600), _doAiTurn);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // POWERUP USAGE
  // ─────────────────────────────────────────────────────────────────────────────



  void _executePowerup(PowerupType p, {String? targetSquare}) {
    // Check if sabotaged (enemy disabled our powerup usage)
    final isSabotaged = _activeEffects.any((e) =>
        e.type == PowerupType.sabotage);
    if (isSabotaged) {
      _showSnack('Power-ups are sabotaged! Cannot use.', AppColors.accentRed);
      return;
    }

    final res = _powerupEngine.applyPowerup(
      type: p,
      engine: _engine,
      playerColor: _myColor,
      targetSquare: targetSquare,
      capturedPieces: _myCapturedPieces,
    );

    if (!res.success) {
      if (res.requiresTarget) {
        // Set pending target mode for targeted power-ups
        setState(() => _pendingTargetPowerup = p);
        _showSnack(res.message, AppColors.accentAmber);
      } else {
        _showSnack(res.message, AppColors.accentRed);
      }
      return;
    }

    _addPowerupEffect(p.tier.color, square: targetSquare);

    setState(() {
      _myPowerups.remove(p);
      if (res.activeEffect != null) _activeEffects.add(res.activeEffect!);
      if (res.timeBonus > 0) _myTimeLeft += res.timeBonus;
      if (res.timePenalty > 0) _opponentTimeLeft -= res.timePenalty;
      if (res.highlightSquares != null) {
        _highlightedSquares = [..._highlightedSquares, ...res.highlightSquares!];
      }
      // Extra turn from freeze, double move, or mirror dimension
      if (p == PowerupType.freeze ||
          p == PowerupType.doubleMove ||
          p == PowerupType.mirrorDimension) {
        _hasExtraTurn = true;
      }
      if (res.removesEnemyPowerup && _opponentPowerups.isNotEmpty) {
        _opponentPowerups.removeLast();
      }
    });

    // Check if the powerup caused checkmate (e.g., Black Hole, Exile)
    if (_engine.gameOver) {
      _handleGameOver('checkmate');
      return;
    }

    _showSnack(res.message, p.tier.color);
    if (widget.isMultiplayer) _dbService.incrementPowerupsUsed(widget.playerUid);
    _syncState();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SYNC & GAME OVER
  // ─────────────────────────────────────────────────────────────────────────────

  void _syncState() {
    if (!widget.isMultiplayer) return;
    _gameService.sendMove(
      san: _engine.getHistoryString(),
      fen: _engine.fen,
      turn: _engine.turnColor,
      moveCount: _engine.getHistory().length,
      timeLeftBlack: _myColor == 'black' ? _myTimeLeft : _opponentTimeLeft,
      timeLeftWhite: _myColor == 'white' ? _myTimeLeft : _opponentTimeLeft,
    );
    _gameService.updatePowerups(
      color: _myColor,
      held: _myPowerups,
      active: _activeEffects,
    );
  }

  void _handleGameOver(String reason) {
    if (_isGameOver) return;
    setState(() => _isGameOver = true);
    _clockTimer?.cancel();

    String resultText;
    String wonBy = 'Draw';

    if (reason == 'checkmate') {
      wonBy = _engine.turnColor == _myColor ? 'opponent' : 'me';
      resultText = wonBy == 'me' ? '🏆 You Win!' : '💀 You Lost!';
    } else if (reason == 'timeout_me') {
      resultText = '⏱ Time Out — You Lost!';
      wonBy = 'opponent';
    } else if (reason == 'timeout_opp') {
      resultText = '⏱ Opponent timed out — You Win!';
      wonBy = 'me';
    } else {
      resultText = 'Game Over — Draw';
    }

    if (wonBy == 'opponent') {
      setState(() => _hasLost = true);
    }

    if (widget.isMultiplayer) {
      _gameService.endGame(status: 'Finished', wonBy: wonBy == 'me' ? _myColor : (wonBy == 'opponent' ? (_myColor == 'white' ? 'black' : 'white') : 'draw'));
      _dbService.updateMatchStats(
        uid: widget.playerUid,
        isWin: wonBy == 'me',
        isDraw: wonBy == 'Draw',
        eloChange: wonBy == 'me' ? 15 : (wonBy == 'Draw' ? 0 : -15),
      );
    }

    _showGameOverDialog(resultText);
  }

  void _showGameOverDialog(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadius)),
        title: Text(text, style: AppTextStyles.heading2, textAlign: TextAlign.center),
        content: Text('Return to lobby?', style: AppTextStyles.body, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: Text('LOBBY', style: AppTextStyles.button.copyWith(color: AppColors.accentCyan)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _clockTimer?.cancel();
    _matchSub?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final boardSize = math.min(screenW * 0.95, screenH * 0.55).clamp(200.0, 520.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 60,
        title: Text(widget.isMultiplayer ? 'Ranked Match' : 'vs AI', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_pendingTargetPowerup != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Chip(
                label: Text('Targeting: ${_pendingTargetPowerup!.name}'),
                backgroundColor: _pendingTargetPowerup!.tier.color.withAlpha(60),
                onDeleted: () => setState(() => _pendingTargetPowerup = null),
              ),
            ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Opponent Row ────────────────────────────────────────────────────
            PlayerInfoBar(
              fallbackName: widget.isMultiplayer ? 'Opponent' : 'AI Master',
              capturedPieces: _opponentCapturedPieces,
              isTop: true,
            ),

            // ── Timers ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TimerWidget(
                    timeInSeconds: _opponentTimeLeft,
                    isRunning: !_isGameOver && _engine.turnColor != _myColor,
                  ),
                  // Opponent powerup icons
                  Row(
                    children: _opponentPowerups
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Icon(p.icon, color: p.tier.color.withAlpha(180), size: 18),
                            ))
                        .toList(),
                  ),
                  TimerWidget(
                    timeInSeconds: _myTimeLeft,
                    isRunning: !_isGameOver && _engine.turnColor == _myColor,
                  ),
                ],
              ),
            ),

            // ── Board ───────────────────────────────────────────────────────────
            Expanded(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: _hasLost ? 1.0 : 0.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Container(
                      foregroundDecoration: value > 0 ? BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.accentRed.withAlpha((value * 127).toInt()),
                            AppColors.accentRed.withAlpha((value * 204).toInt()),
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                      ) : null,
                      child: Transform.scale(
                        scale: 1.0 - (value * 0.05),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: boardSize,
                    height: boardSize,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                      border: Border.all(color: AppColors.boardBorder, width: 3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SizedBox(
                      width: boardSize,
                      height: boardSize,
                      child: DragTarget<PowerupType>(
                        onWillAcceptWithDetails: (details) => !_isGameOver && _engine.turnColor == _myColor,
                        onAcceptWithDetails: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final localPos = box.globalToLocal(details.offset);
                          final square = _offsetToSquare(localPos, boardSize);
                          _executePowerup(details.data, targetSquare: square);
                        },
                        builder: (context, candidateData, rejectedData) {
                          return SizedBox(
                            width: boardSize,
                            height: boardSize,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                ChessBoardWidget(
                                  engine: _engine,
                                  size: boardSize,
                                  isWhiteOrientation: _isWhiteOrientation,
                                  onMove: (from, to, promo) => _executeMove(from, to, promo),
                                  onSquareTap: _handleSquareTap,
                                  activeEffects: _activeEffects,
                                  selectedSquare: _selectedSquare,
                                  highlightedSquares: _highlightedSquares,
                                  lastMoveSquares: _lastMoveSquares,
                                ),
                                if (candidateData.isNotEmpty)
                                  Positioned.fill(
                                    child: Container(
                                      color: candidateData.first!.tier.color.withAlpha(40),
                                      child: Center(
                                        child: Icon(
                                          candidateData.first!.icon,
                                          color: candidateData.first!.tier.color.withAlpha(100),
                                          size: 100,
                                        ),
                                      ),
                                    ),
                                  ),
                                VfxOverlay(
                                  activeEffects: _activeEffects,
                                  boardSize: boardSize,
                                  isWhiteOrientation: _isWhiteOrientation,
                                ),
                                ParticleOverlay(
                                  effects: _recentEffects,
                                  boardSize: boardSize,
                                  isWhiteOrientation: _isWhiteOrientation,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── My Powerups ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: PowerupBar(
                heldPowerups: _myPowerups,
                isMyTurn: !_isGameOver &&
                    _engine.turnColor == _myColor &&
                    _pendingTargetPowerup == null,
              ),
            ),

            // ── My Info ─────────────────────────────────────────────────────────
            PlayerInfoBar(
              fallbackName: 'You',
              capturedPieces: _myCapturedPieces,
              isTop: false,
            ),
          ],
        ),
      ),
    ));
  }
}

