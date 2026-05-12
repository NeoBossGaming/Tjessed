import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/player_model.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_background.dart';

class LeaderboardScreen extends StatefulWidget {
  final String currentPlayerUid;
  const LeaderboardScreen({super.key, required this.currentPlayerUid});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseService _db = DatabaseService();
  List<PlayerModel> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    final results = await _db.getLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboard = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Global Leaderboard', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLeaderboard,
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
              : _leaderboard.isEmpty
                  ? Center(child: Text('No players found yet.', style: AppTextStyles.body))
                  : RefreshIndicator(
                      onRefresh: _fetchLeaderboard,
                      color: AppColors.accentCyan,
                      backgroundColor: AppColors.background,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final player = _leaderboard[index];
                          final isMe = player.uid == widget.currentPlayerUid;
                          final rank = index + 1;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildLeaderboardTile(player, rank, isMe),
                          ).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                        },
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(PlayerModel player, int rank, bool isMe) {
    Color rankColor = AppColors.textSecondary;
    Widget? rankIcon;

    if (rank == 1) {
      rankColor = AppColors.accentAmber;
      rankIcon = const Icon(Icons.emoji_events, color: AppColors.accentAmber, size: 20);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFC0C0C0), size: 18);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankIcon = const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 16);
    }

    return GlassContainer(
      opacity: isMe ? 0.25 : 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: isMe ? Border.all(color: AppColors.accentCyan.withAlpha(150), width: 1.5) : null,
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: rankIcon ?? Text('#$rank', style: AppTextStyles.heading3.copyWith(color: rankColor)),
          ),
          
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe ? AppColors.goldGradient : AppColors.primaryGradient,
            ),
            child: Center(
              child: Text(
                player.username[0].toUpperCase(),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.username + (isMe ? ' (YOU)' : ''),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                    color: isMe ? AppColors.accentCyan : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${player.matchesWon} Wins • ${player.matchesPlayed} Matches',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          
          // Elo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.elo}',
                style: AppTextStyles.heading3.copyWith(color: AppColors.accentAmber),
              ),
              Text('ELO', style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}
