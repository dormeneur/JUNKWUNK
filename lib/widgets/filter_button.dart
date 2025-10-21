import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const FilterButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.white,
          foregroundColor: isSelected ? AppColors.white : AppColors.primary,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXL,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.greyLight,
              width: AppBorders.borderWidthThin,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.fontSizeMD,
            fontWeight: isSelected ? AppTypography.semiBold : AppTypography.medium,
          ),
        ),
      ),
    );
  }
}
