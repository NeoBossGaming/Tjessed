import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/matchmaking_service.dart';
import '../models/player_model.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_background.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';
import 'playground_screen.dart';
import 'dart:async';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final MatchmakingService _matchmaking = MatchmakingService();

  PlayerModel? playerProfile;
  StreamSubscription? _matchSub;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      _db.streamPlayerProfile(user.uid).listen((profile) async {
        if (profile == null) {
          // If profile is missing in DB, recreate it automatically
          await _auth.initializeUserData(user.uid, user.email?.split('@')[0] ?? 'Player');
          // No need to setState here, the stream will emit again once it's created.
        } else {
          if (mounted) setState(() => playerProfile = profile);
        }
      }, onError: (e) {
        debugPrint('Error streaming profile: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading profile: $e', style: AppTextStyles.body)),
          );
        }
      });
    }
  }

  void _findMatch() async {
    if (playerProfile == null) return;

    setState(() => isSearching = true);
    await _matchmaking.joinQueue(playerProfile!);
    _matchmaking.startSearching(playerProfile!);

    _matchSub = _matchmaking.listenForMatch(playerProfile!.uid).listen((matchId) {
      if (matchId != null) {
        _matchSub?.cancel();
        if (mounted) {
          setState(() => isSearching = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                matchId: matchId,
                playerUid: playerProfile!.uid,
                isMultiplayer: true,
              ),
            ),
          );
        }
      }
    });
  }

  void _cancelSearch() async {
    if (playerProfile != null) {
      await _matchmaking.leaveQueue(playerProfile!.uid);
    }
    _matchSub?.cancel();
    if (mounted) setState(() => isSearching = false);
  }

  void _playVsAi() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadius)),
        title: Text("Select AI Difficulty", style: AppTextStyles.heading2, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyOption("Easy", "600 ELO", AppColors.accentGreen, GameConstants.aiEasyDepth),
            const SizedBox(height: 12),
            _buildDifficultyOption("Medium", "1200 ELO", AppColors.accentAmber, GameConstants.aiMediumDepth),
            const SizedBox(height: 12),
            _buildDifficultyOption("Hard", "1800 ELO", AppColors.accentRed, GameConstants.aiHardDepth),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String title, String subtitle, Color color, int depth) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              matchId: 'SP_${DateTime.now().millisecondsSinceEpoch}',
              playerUid: playerProfile?.uid ?? 'SP_USER',
              isMultiplayer: false,
              aiDepth: depth,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          border: Border.all(color: color.withAlpha(100), width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading3.copyWith(color: color)),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Main Lobby", style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.accentRed),
            onPressed: _auth.signOut,
          )
        ],
      ),
      body: AnimatedBackground(
        child: Center(
          child: playerProfile == null
              ? const CircularProgressIndicator(color: AppColors.accentCyan)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile Card
                      GlassContainer(
                        opacity: 0.15,
                        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: AppColors.surface,
                                child: Text(
                                  playerProfile!.username[0].toUpperCase(),
                                  style: AppTextStyles.heading1.copyWith(color: AppColors.accentCyan, fontSize: 36),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(playerProfile!.username, style: AppTextStyles.heading2),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStat("Elo", playerProfile!.elo.toString(), AppColors.accentAmber),
                                  _buildStat("Won", playerProfile!.matchesWon.toString(), AppColors.accentGreen),
                                  _buildStat("Played", playerProfile!.matchesPlayed.toString(), AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 40),

                      // Play Buttons
                      if (isSearching)
                        GlassContainer(
                          opacity: 0.1,
                          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: AppColors.accentCyan)
                                  .animate(onPlay: (c) => c.repeat())
                                  .shimmer(duration: 1.seconds, color: Colors.white),
                              const SizedBox(height: 16),
                              Text("Searching for opponent...", style: AppTextStyles.body),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceLight,
                                  foregroundColor: AppColors.accentRed,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall)),
                                  side: const BorderSide(color: AppColors.accentRed, width: 1.5),
                                ),
                                onPressed: _cancelSearch,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  child: Text("CANCEL"),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade()
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accentCyan.withAlpha(80),
                                      blurRadius: 20,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentCyan,
                                    foregroundColor: AppColors.background,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadius)),
                                  ),
                                  icon: const Icon(Icons.people),
                                  label: Text("FIND ONLINE MATCH", style: AppTextStyles.heading3.copyWith(color: AppColors.background)),
                                  onPressed: _findMatch,
                                ),
                              ),
                            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surfaceLight,
                                  foregroundColor: AppColors.textPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadius)),
                                  side: BorderSide(color: AppColors.textMuted.withAlpha(100)),
                                ),
                                icon: const Icon(Icons.smart_toy),
                                label: Text("PLAY VS AI", style: AppTextStyles.heading3),
                                onPressed: _playVsAi,
                              ),
                            ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                            const SizedBox(height: 12),
                            // New Action Buttons Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSmallActionButton(
                                    icon: Icons.leaderboard,
                                    label: "RANKS",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(currentPlayerUid: playerProfile!.uid))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSmallActionButton(
                                    icon: Icons.grid_view_rounded,
                                    label: "SANDBOX",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaygroundScreen(playerUid: playerProfile!.uid))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSmallActionButton(
                                    icon: Icons.settings,
                                    label: "SETTINGS",
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                                  ),
                                ),
                              ],
                            ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSmallActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      child: GlassContainer(
        opacity: 0.1,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentCyan, size: 28),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: AppTextStyles.heading2.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
