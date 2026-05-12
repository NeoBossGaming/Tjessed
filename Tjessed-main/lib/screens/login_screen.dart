import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/glass_container.dart';
import '../widgets/animated_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      _showError('Login failed: ${_friendlyError(e.toString())}');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    try {
      await _auth.register(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      _showError('Register failed: ${_friendlyError(e.toString())}');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) return 'Wrong email or password.';
    if (raw.contains('email-already-in-use')) return 'Email already registered.';
    if (raw.contains('weak-password')) return 'Password too weak (min 6 chars).';
    if (raw.contains('invalid-email')) return 'Invalid email format.';
    return raw;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.accentRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassContainer(
                opacity: 0.15,
                padding: const EdgeInsets.all(AppDimensions.paddingLarge * 1.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.castle, size: 72, color: AppColors.accentCyan)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 2.seconds, color: Colors.white),
                    const SizedBox(height: 12),
                    Text('Ultimate Chess', style: AppTextStyles.heading1),
                    Text('Powered by Powerups', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 36),
                    _buildField('Email', Icons.email, _emailCtrl, false),
                    const SizedBox(height: 16),
                    _buildField('Password', Icons.lock, _passCtrl, true),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator(color: AppColors.accentCyan)
                        : Column(
                            children: [
                              _buildButton('LOGIN', AppColors.accentCyan, AppColors.background, _signIn),
                              const SizedBox(height: 16),
                              _buildButton('REGISTER', Colors.transparent, AppColors.accentCyan, _register,
                                  border: true),
                            ],
                          ),
                  ],
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, bool obscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.textMuted.withAlpha(100)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: BorderSide(color: AppColors.textMuted.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          borderSide: const BorderSide(color: AppColors.accentCyan),
        ),
        filled: true,
        fillColor: AppColors.surfaceLight,
      ),
    );
  }

  Widget _buildButton(String label, Color bg, Color fg, VoidCallback onTap, {bool border = false}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: border ? 0 : 8,
          shadowColor: bg.withAlpha(120),
          side: border ? const BorderSide(color: AppColors.accentCyan, width: 1.5) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall)),
        ),
        onPressed: onTap,
        child: Text(label, style: AppTextStyles.button.copyWith(color: fg)),
      ),
    );
  }
}
