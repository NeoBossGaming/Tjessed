import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final AuthService _auth = AuthService();

  String _selectedTheme = 'Classic Wood';
  String _selectedPieceStyle = 'Solid';
  bool _soundEnabled = true;
  double _animIntensity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _selectedTheme = _settings.boardTheme;
      _selectedPieceStyle = _settings.pieceStyle;
      _soundEnabled = _settings.soundEnabled;
      _animIntensity = _settings.animIntensity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            children: [
              _buildSectionTitle('Appearance'),
              _buildThemePicker(),
              const SizedBox(height: 16),
              _buildPieceStylePicker(),
              const SizedBox(height: 32),
              _buildSectionTitle('Audio & Effects'),
              _buildSoundToggle(),
              const SizedBox(height: 16),
              _buildAnimSlider(),
              const SizedBox(height: 32),
              _buildSectionTitle('Account'),
              _buildSignOutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accentCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    ).animate().fade().slideX(begin: -0.1, end: 0);
  }

  Widget _buildThemePicker() {
    final themes = ['Classic Wood', 'Dark Neon', 'Pastel', 'Ocean'];
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Board Theme', style: AppTextStyles.body),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: themes.map((theme) {
              final isSelected = _selectedTheme == theme;
              return ChoiceChip(
                label: Text(theme),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() => _selectedTheme = theme);
                    _settings.setBoardTheme(theme);
                  }
                },
                selectedColor: AppColors.accentCyan.withAlpha(100),
                backgroundColor: AppColors.surface,
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? AppColors.accentCyan : AppColors.textPrimary,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceStylePicker() {
    final styles = ['Solid', 'Outlined'];
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Piece Style', style: AppTextStyles.body),
          DropdownButton<String>(
            value: _selectedPieceStyle,
            dropdownColor: AppColors.background,
            style: AppTextStyles.body,
            underline: Container(height: 1, color: AppColors.accentCyan),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedPieceStyle = val);
                _settings.setPieceStyle(val);
              }
            },
            items: styles.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundToggle() {
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Sound Effects', style: AppTextStyles.body),
          Switch(
            value: _soundEnabled,
            activeThumbColor: AppColors.accentCyan,
            onChanged: (val) {
              setState(() => _soundEnabled = val);
              _settings.setSoundEnabled(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimSlider() {
    return GlassContainer(
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Animation Intensity', style: AppTextStyles.body),
              Text('${(_animIntensity * 100).toInt()}%', style: AppTextStyles.bodySmall),
            ],
          ),
          Slider(
            value: _animIntensity,
            min: 0.0,
            max: 1.0,
            activeColor: AppColors.accentCyan,
            onChanged: (val) {
              setState(() => _animIntensity = val);
              _settings.setAnimIntensity(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentRed.withAlpha(30),
        foregroundColor: AppColors.accentRed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          side: const BorderSide(color: AppColors.accentRed, width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        _auth.signOut();
        Navigator.pop(context);
      },
      child: const Text('SIGN OUT'),
    );
  }
}
