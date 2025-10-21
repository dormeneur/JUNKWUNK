import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

/// Reusable card widget for mediator pages
/// Provides consistent styling across all mediator screens
class MediatorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  const MediatorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppBorders.borderRadiusLG,
          boxShadow: AppShadows.shadow3,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTypography.fontSize3XL,
                fontWeight: AppTypography.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              description,
              style: const TextStyle(
                fontSize: AppTypography.fontSizeLG,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.borderRadiusMD,
                  ),
                  elevation: 2,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: AppTypography.fontSizeLG,
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
