import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as ch;
import '../engine/chess_engine.dart';
import '../engine/powerup_engine.dart';
import '../engine/ai_engine.dart';
import '../services/game_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../services/settings_service.dart';
import '../models/powerup.dart';
import '../utils/constants.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/powerup_bar.dart';
import '../widgets/player_info_bar.dart';
import '../widgets/timer_widget.dart';
import '../widgets/particle_overlay.dart';
import '../widgets/animated_background.dart';
import '../widgets/card_reveal_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/active_effects_hud.dart';
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
  final int aiDepth;

  const GameScreen({
    super.key,
    required this.matchId,
    required this.playerUid,
    required this.isMultiplayer,
    this.initialFen,
    this.playerColor,
    this.aiDepth = GameConstants.aiMediumDepth,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // ── Engine & services ────────────────────────────────────────────────────────
  final ChessEngine _engine = ChessEngine();
  final PowerupEngine _powerupEngine = PowerupEngine();
  late final AIEngine _aiEngine;
  final GameService _gameService = GameService();
  final DatabaseService _dbService = DatabaseService();
  final SoundService _soundService = SoundService();
  final GlobalKey _boardKey = GlobalKey();

  // ── Board state ──────────────────────────────────────────────────────────────
  bool _isWhiteOrientation = true;
  String? _myColor; // Role not yet assigned
  String _opponentName = 'Opponent';
  String? _selectedSquare;
  List<String> _highlightedSquares = [];
  List<String> _lastMoveSquares = [];
  String? _hoveredSquare;

  // ── Powerup state ────────────────────────────────────────────────────────────
  List<ActiveEffect> _activeEffects = [];
  List<PowerupType> _myPowerups = [];
  List<PowerupType> _opponentPowerups = [];
  final List<String> _myCapturedPieces = [];
  final List<String> _opponentCapturedPieces = [];
  PowerupType? _pendingTargetPowerup;
  final List<String> _pendingSwapTargets = [];

  // ── Timer ────────────────────────────────────────────────────────────────────
  int _myTimeLeft = GameConstants.defaultTimeSeconds;
  int _opponentTimeLeft = GameConstants.defaultTimeSeconds;
  Timer? _clockTimer;

  // ── Game status ──────────────────────────────────────────────────────────────
  bool _isGameOver = false;
  bool _hasLost = false;
  StreamSubscription? _matchSub;
  bool _multiplayerClockStarted = false;
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
  
  // ── Screen Shake ────────────────────────────────────────────────────────────
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _aiEngine = AIEngine(depth: widget.aiDepth);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.isMultiplayer) {
      _setupMultiplayer();
    } else {
      _setupSingleplayer();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _matchSub?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (SettingsService().animIntensity > 0) {
      _shakeController.forward(from: 0.0);
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
    debugPrint('[SYNC] Initializing multiplayer match: ${widget.matchId}');
    _gameService.initialize(widget.matchId);
    _matchSub = _gameService.streamMatchData().listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        debugPrint('[SYNC] No match data found at Matches/${widget.matchId}');
        return;
      }
      
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final myUid = widget.playerUid.trim();
      debugPrint('[SYNC] Data received. MyUID: $myUid');
      
      // Try multiple ways to find the role
      String? foundColor;
      String? oppName;

      final blackId = (data['BlackID'] ?? '').toString().trim();
      final whiteId = (data['WhiteID'] ?? '').toString().trim();
      debugPrint('[SYNC] Match Roles - White: $whiteId, Black: $blackId');

      if (myUid == blackId) {
        foundColor = 'black';
        oppName = data['WhiteName']?.toString();
      } else if (myUid == whiteId) {
        foundColor = 'white';
        oppName = data['BlackName']?.toString();
      } 
      
      if (foundColor == null) {
        if (myUid.toLowerCase() == blackId.toLowerCase()) {
          foundColor = 'black';
          oppName = data['WhiteName']?.toString();
        } else if (myUid.toLowerCase() == whiteId.toLowerCase()) {
          foundColor = 'white';
          oppName = data['BlackName']?.toString();
        }
      }

      if (foundColor != null) {
        if (_myColor != foundColor) {
          debugPrint('[SYNC] Assigned color: $foundColor');
          setState(() {
            _myColor = foundColor;
            _isWhiteOrientation = foundColor == 'white';
          });
        }
        _opponentName = oppName ?? 'Opponent';
      } else {
        debugPrint('[SYNC] CRITICAL: UID Mismatch. My=$myUid is neither White=$whiteId nor Black=$blackId');
      }

      final incomingFen = data['FEN'] as String?;
      final incomingFrom = data['LastMoveFrom'] as String?;
      final incomingTo = data['LastMoveTo'] as String?;

      if (incomingFen != null &&
          incomingFen.isNotEmpty &&
          incomingFen != _engine.fen) {
        debugPrint('[SYNC] FEN Update: $incomingFen');
        setState(() {
          _engine.loadFen(incomingFen);
          if (incomingFrom != null && incomingTo != null) {
            _lastMoveSquares = [incomingFrom, incomingTo];
          } else {
            _lastMoveSquares = [];
          }
        });
      }

      setState(() {
        if (_myColor != null) {
          final myKey = _myColor == 'white' ? 'White' : 'Black';
          final oppKey = _myColor == 'white' ? 'Black' : 'White';
          _myTimeLeft = (data['TimeLeft$myKey'] as num?)?.toInt() ?? GameConstants.defaultTimeSeconds;
          _opponentTimeLeft = (data['TimeLeft$oppKey'] as num?)?.toInt() ?? GameConstants.defaultTimeSeconds;
        }

        final status = data['GameStatus'] as String? ?? 'Active';
        if (status == 'Finished' && !_isGameOver) {
          final wonBy = data['WonBy'] as String?;
          _isGameOver = true;
          _clockTimer?.cancel();
          _showGameOverRemote(wonBy);
        } else {
          _isGameOver = status != 'Active';
          if (_isGameOver) _clockTimer?.cancel();
        }

        if (_myColor != null && data['Powerups'] != null) {
          _parsePowerupsFromDb(data['Powerups'] as Map<dynamic, dynamic>);
        }
      });

      if (!_isGameOver && widget.isMultiplayer && _myColor != null) {
        if (!_multiplayerClockStarted) {
          _multiplayerClockStarted = true;
          _startClock();
        }
      }
    }, onError: (err) {
      debugPrint('[SYNC] Firebase Stream Error: $err');
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
    if (_isGameOver || _myColor == null) return;
    if (!widget.isMultiplayer && _engine.turnColor != _myColor) return; // Wait for AI
    if (widget.isMultiplayer && _engine.turnColor != _myColor) return;

    // Targeted powerup pending
    if (_pendingTargetPowerup != null) {
      if (_pendingTargetPowerup! == PowerupType.swap) {
        final piece = _engine.getPiece(square);
        if (piece != null && piece.type.name != 'k') {
          setState(() {
            if (!_pendingSwapTargets.contains(square)) {
              _pendingSwapTargets.add(square);
            }
          });
          if (_pendingSwapTargets.length == 2) {
            _executePowerup(_pendingTargetPowerup!, targetSquare: _pendingSwapTargets[0], targetSquare2: _pendingSwapTargets[1]);
            setState(() { 
              _pendingTargetPowerup = null; 
              _pendingSwapTargets.clear();
            });
          }
        } else {
          _showSnack('Cannot select a king for swap!', AppColors.accentRed);
        }
        return;
      } else {
        _executePowerup(_pendingTargetPowerup!, targetSquare: square);
        setState(() { _pendingTargetPowerup = null; });
        return;
      }
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

  (int, int) _getVisualPosForSquare(String square, bool isWhiteOrientation) {
    int col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    int rank = int.parse(square[1]);
    int row = 8 - rank;
    if (!isWhiteOrientation) {
      row = 7 - row;
      col = 7 - col;
    }
    return (row, col);
  }

  void _executeMove(String from, String to, String? promo) {
    final move = _engine.makeMove(from, to, promotion: promo, activeEffects: _activeEffects);
    if (move == null) return;

    setState(() {
      _selectedSquare = null;
      _highlightedSquares = [];
      _lastMoveSquares = [from, to];
    });

    // Powerup roll on capture
    final captured = move.captured;
    if (captured != null) {
      _triggerShake();
      _addCaptureEffect(to);
      _soundService.play(SoundEvent.capture);
      _myCapturedPieces.add(captured.toString());
      final newPu = _powerupEngine.rollPowerup(captured.toString());
      if (newPu != null && _myPowerups.length < GameConstants.maxPowerupsHeld) {
        setState(() => _myPowerups.add(newPu));
        showCardReveal(context, newPu);
        _soundService.play(SoundEvent.powerupGet);
        _addPowerupEffect(newPu.tier.color, square: to, count: newPu.tier.level * 10 + 10);
      }
    } else {
      _soundService.play(SoundEvent.move);
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

    if (_engine.gameOver) { 
      _syncState(); // Sync final move before ending
      _handleGameOver('checkmate'); 
      return; 
    }
    if (_engine.inCheck) _soundService.play(SoundEvent.check);

    _syncState();
    if (!widget.isMultiplayer && _engine.turnColor != _myColor) {
      Future.delayed(const Duration(milliseconds: 400), _doAiTurn);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AI TURN
  // ─────────────────────────────────────────────────────────────────────────────

  void _doAiTurn() async {
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

    final best = await _aiEngine.getBestMove(_engine);
    if (best == null) return;

    final move = _engine.makeMove(best.from, best.to, activeEffects: _activeEffects);
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
      Future.delayed(const Duration(milliseconds: 400), _doAiTurn);
    }
    
    // Check if after reverting/undoing it's the AI's turn
    if (!widget.isMultiplayer && _engine.turnColor != _myColor && !_isGameOver) {
      Future.delayed(const Duration(milliseconds: 400), _doAiTurn);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // POWERUP USAGE
  // ─────────────────────────────────────────────────────────────────────────────



  void _handlePowerupTap(PowerupType p) {
    if (_isGameOver || _engine.turnColor != _myColor) return;
    
    // Clear any existing pending powerup first to prevent state pollution
    setState(() => _pendingTargetPowerup = null);

    if (p.isTargeted) {
      // Enter targeting mode
      setState(() => _pendingTargetPowerup = p);
      _showSnack('Select a target square for ${p.name}', AppColors.accentAmber);
    } else {
      _executePowerup(p);
    }
  }

  void _executePowerup(PowerupType p, {String? targetSquare, String? targetSquare2}) {
    // Check if sabotaged (enemy disabled our powerup usage)
    final isSabotaged = _activeEffects.any((e) =>
        e.type == PowerupType.sabotage);
    if (isSabotaged) {
      _showSnack('Power-ups are sabotaged! Cannot use.', AppColors.accentRed);
      return;
    }

    _triggerShake();
    
    // Execution attempt
    final res = _powerupEngine.applyPowerup(
      type: p,
      engine: _engine,
      playerColor: _myColor!,
      targetSquare: targetSquare,
      targetSquare2: targetSquare2,
      capturedPieces: _myCapturedPieces,
    );

    // Clear pending state after execution attempt
    setState(() => _pendingTargetPowerup = null);

    if (!res.success) {
      if (res.requiresTarget) {
        // Re-set pending target mode if target is still needed
        setState(() => _pendingTargetPowerup = p);
        _showSnack(res.message, AppColors.accentAmber);
      } else {
        _showSnack(res.message, AppColors.accentRed);
      }
      return;
    }

    _addPowerupEffect(p.tier.color, square: targetSquare ?? targetSquare2);
    _soundService.play(SoundEvent.powerupUse);

    setState(() {
      _myPowerups.remove(p);
      if (res.activeEffect != null) _activeEffects.add(res.activeEffect!);
      if (res.timeBonus > 0) _myTimeLeft += res.timeBonus;
      if (res.timePenalty > 0) _opponentTimeLeft -= res.timePenalty;
      if (res.highlightSquares != null) {
        _highlightedSquares = [..._highlightedSquares, ...res.highlightSquares!];
      }
      // Extra turn from freeze or double move
      if (p == PowerupType.freeze ||
          p == PowerupType.doubleMove) {
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

    // If a powerup caused it to become the AI's turn (e.g. they gained a turn)
    if (!widget.isMultiplayer && _engine.turnColor != _myColor && !_isGameOver) {
      Future.delayed(const Duration(milliseconds: 400), _doAiTurn);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SYNC & GAME OVER
  // ─────────────────────────────────────────────────────────────────────────────

  void _syncState() {
    if (!widget.isMultiplayer) return;
    debugPrint('[SYNC] Sending move state... Turn: ${_engine.turnColor}');
    
    String? fromSq;
    String? toSq;
    if (_lastMoveSquares.length >= 2) {
      fromSq = _lastMoveSquares[0];
      toSq = _lastMoveSquares[1];
    }
    
    _gameService.sendMove(
      fen: _engine.fen,
      turn: _engine.turnColor,
      timeLeftBlack: _myColor == 'black' ? _myTimeLeft : _opponentTimeLeft,
      timeLeftWhite: _myColor == 'white' ? _myTimeLeft : _opponentTimeLeft,
      lastMoveFrom: fromSq,
      lastMoveTo: toSq,
    );
    _gameService.updatePowerups(
      color: _myColor!,
      held: _myPowerups,
      active: _activeEffects,
    );
  }

  void _handleGameOver(String reason) {
    if (_isGameOver) return;
    setState(() => _isGameOver = true);
    _clockTimer?.cancel();
    _soundService.play(SoundEvent.gameOver);

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

    final eloDelta = wonBy == 'me' ? 15 : (wonBy == 'Draw' ? 0 : -15);
    if (widget.isMultiplayer) {
      _gameService.endGame(status: 'Finished', wonBy: wonBy == 'me' ? _myColor! : (wonBy == 'opponent' ? (_myColor == 'white' ? 'black' : 'white') : 'draw'));
      _dbService.updateMatchStats(
        uid: widget.playerUid,
        isWin: wonBy == 'me',
        isDraw: wonBy == 'Draw',
        eloChange: eloDelta,
      );
    }

    _showGameOverDialog(resultText, eloDelta);
  }

  void _showGameOverRemote(String? wonByColor) {
    String resultText;
    int eloDelta = 0;

    if (wonByColor == 'draw') {
      resultText = 'Game Over — Draw';
      eloDelta = 0;
    } else if (wonByColor == _myColor) {
      resultText = '🏆 You Win!';
      eloDelta = 15;
    } else {
      resultText = '💀 You Lost!';
      eloDelta = -15;
      setState(() => _hasLost = true);
    }

    _showGameOverDialog(resultText, eloDelta);
  }

  void _showGameOverDialog(String text, int eloChange) {
    final eloText = eloChange > 0 ? '+$eloChange Elo' : (eloChange < 0 ? '$eloChange Elo' : '0 Elo');
    final eloColor = eloChange > 0 ? AppColors.accentGreen : (eloChange < 0 ? AppColors.accentRed : Colors.white70);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadius)),
        title: Column(
          children: [
            Text(text, style: AppTextStyles.heading2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(eloText, style: AppTextStyles.heading3.copyWith(color: eloColor)),
          ],
        ),
        content: Text('Return to lobby?', style: AppTextStyles.body, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () { 
              // Immediate return to lobby
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('CONTINUE', style: AppTextStyles.button.copyWith(color: AppColors.accentCyan)),
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
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            final dx = math.sin(_shakeController.value * math.pi * 6) * 8.0 * (1 - _shakeController.value);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;
                
                // Optimized board size for corner HUD layout
                final maxBoardHeight = availableHeight - 240.0; // Increased subtraction for more clearance
                final maxBoardWidth = availableWidth - 100.0;
                final boardSize = (math.min(maxBoardWidth, maxBoardHeight) * 0.9).clamp(150.0, 750.0);

                return SafeArea(
                  child: Stack(
                    children: [
                      // ── 1. Central Content: Board & Effects ──────────────────────────
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Active Effects HUD (Floating/Small Row) ───────────
                            if (_activeEffects.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ActiveEffectsHud(activeEffects: _activeEffects),
                              ),

                            // ── Turn Indicator ───────────────────────────────────────
                            if (!_isGameOver && _myColor != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (_engine.turnColor == _myColor ? AppColors.accentCyan : AppColors.accentRed).withAlpha(40),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: (_engine.turnColor == _myColor ? AppColors.accentCyan : AppColors.accentRed).withAlpha(120),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _engine.turnColor == _myColor ? Icons.bolt : Icons.hourglass_empty,
                                        size: 16,
                                        color: _engine.turnColor == _myColor ? AppColors.accentCyan : AppColors.accentRed,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _engine.turnColor == _myColor ? 'YOUR TURN' : 'OPPONENT TURN',
                                        style: AppTextStyles.caption.copyWith(
                                          color: _engine.turnColor == _myColor ? AppColors.accentCyan : AppColors.accentRed,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true)).boxShadow(
                                  begin: const BoxShadow(color: Colors.transparent),
                                  end: BoxShadow(
                                    color: (_engine.turnColor == _myColor ? AppColors.accentCyan : AppColors.accentRed).withAlpha(100),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  duration: 1.5.seconds,
                                ),
                              ),

                            // ── Chess Board ───────────────────────────────────────
                            TweenAnimationBuilder<double>(
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
                                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
                                  border: Border.all(color: AppColors.boardBorder, width: 4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              child: DragTarget<PowerupType>(
                                key: _boardKey,
                                onWillAcceptWithDetails: (details) => !_isGameOver && _engine.turnColor == _myColor,
                                onMove: (details) {
                                  final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  
                                  // details.offset is global top-left of feedback
                                  // Center is at 48, 66 relative to card top-left
                                  final localPos = box.globalToLocal(details.offset + const Offset(48, 66));
                                  final square = _offsetToSquare(localPos, boardSize);
                                  if (_hoveredSquare != square) {
                                    setState(() => _hoveredSquare = square);
                                  }
                                },
                                onLeave: (data) => setState(() => _hoveredSquare = null),
                                onAcceptWithDetails: (details) {
                                  final RenderBox? box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  
                                  final centerOffset = details.offset + const Offset(48, 66);
                                  final localPos = box.globalToLocal(centerOffset);
                                  final square = _offsetToSquare(localPos, boardSize);
                                  _executePowerup(details.data, targetSquare: square);
                                  setState(() => _hoveredSquare = null);
                                },
                                builder: (context, candidateData, rejectedData) {
                                  // Preview logic
                                  List<String> previewSquares = [];
                                  if (candidateData.isNotEmpty && _hoveredSquare != null) {
                                    final p = candidateData.first!;
                                    if (p == PowerupType.blackHole || p == PowerupType.fortress) {
                                      previewSquares = PowerupEngine.getFortressZone(_hoveredSquare!);
                                    } else if (p == PowerupType.wall) {
                                      previewSquares = PowerupEngine.getWallZone(_hoveredSquare!);
                                    } else {
                                      previewSquares = [_hoveredSquare!];
                                    }
                                  }

                                  return SizedBox(
                                    width: boardSize,
                                    height: boardSize,
                                    child: RepaintBoundary(
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
                                            highlightedSquares: [..._highlightedSquares, ...previewSquares],
                                            lastMoveSquares: _lastMoveSquares,
                                            hoveredSquare: _hoveredSquare,
                                          ),
                                          if (candidateData.isNotEmpty && _hoveredSquare != null)
                                            // Special preview tint for the zone
                                            ...previewSquares.map((sq) {
                                              final (vr, vc) = _getVisualPosForSquare(sq, _isWhiteOrientation);
                                              final sqSize = boardSize / 8;
                                              return Positioned(
                                                left: vc * sqSize,
                                                top: vr * sqSize,
                                                width: sqSize,
                                                height: sqSize,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: candidateData.first!.tier.color.withAlpha(100),
                                                    border: Border.all(color: candidateData.first!.tier.color, width: 4),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: candidateData.first!.tier.color.withAlpha(150),
                                                        blurRadius: 15,
                                                        spreadRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                          if (candidateData.isNotEmpty && _hoveredSquare == null)
                                            const SizedBox.shrink(), // Remove entire board glow
                                          ParticleOverlay(
                                            effects: _recentEffects,
                                            boardSize: boardSize,
                                            isWhiteOrientation: _isWhiteOrientation,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                            
                            // Spacing for powerup bar at bottom
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),

                      // ── 2. Top-Right: Opponent Info & Timer ──────────────────────────
                      Positioned(
                        top: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            PlayerInfoBar(
                              fallbackName: widget.isMultiplayer 
                                  ? _opponentName 
                                  : (widget.aiDepth == GameConstants.aiEasyDepth 
                                      ? 'AI (Easy)' 
                                      : (widget.aiDepth == GameConstants.aiHardDepth 
                                          ? 'AI (Hard)' 
                                          : 'AI (Medium)')),
                              capturedPieces: _opponentCapturedPieces,
                              isTop: true,
                            ),
                            const SizedBox(height: 8),
                            TimerWidget(
                              timeInSeconds: _opponentTimeLeft,
                              isRunning: !_isGameOver && _engine.turnColor != _myColor,
                            ),
                          ],
                        ),
                      ),

                      // ── 3. Bottom-Left: Player Info & Timer ──────────────────────────
                      Positioned(
                        bottom: 24,
                        left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TimerWidget(
                              timeInSeconds: _myTimeLeft,
                              isRunning: !_isGameOver && _engine.turnColor == _myColor,
                            ),
                            const SizedBox(height: 8),
                            PlayerInfoBar(
                              fallbackName: 'You',
                              capturedPieces: _myCapturedPieces,
                              isTop: false,
                            ),
                          ],
                        ),
                      ),

                      // ── 4. Bottom-Center: Powerup Bar ───────────────────────────────
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              SizedBox(
                                width: math.min(boardSize + 100, availableWidth - 32),
                                child: PowerupBar(
                                  heldPowerups: _myPowerups,
                                  isMyTurn: !_isGameOver &&
                                      _engine.turnColor == _myColor &&
                                      _pendingTargetPowerup == null,
                                  onPowerupTap: _handlePowerupTap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.isMultiplayer && _myColor == null)
                        Container(
                          color: Colors.black.withAlpha(200),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(color: AppColors.accentCyan),
                                const SizedBox(height: 24),
                                Text('Syncing game data...', style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                                const SizedBox(height: 8),
                                Text(
                                  'Your side (White or Black) is set automatically from the match.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}
