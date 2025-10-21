import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const AppBarWidget({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: AppTypography.fontSize2XL,
          fontWeight: AppTypography.bold,
        ),
      ),
      centerTitle: true,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      leading: leading,
      actions: actions,
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
