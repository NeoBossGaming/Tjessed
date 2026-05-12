import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PremiumLoadingIndicator extends StatelessWidget {
  const PremiumLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.accentCyan,
        backgroundColor: AppColors.surfaceLight,
        strokeWidth: 3,
      ),
    );
  }
}
