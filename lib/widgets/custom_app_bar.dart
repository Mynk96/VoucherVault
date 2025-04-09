import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final double elevation;
  final Color? backgroundColor;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    this.title,
    this.actions,
    this.elevation = 0.0,
    this.backgroundColor,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: title,
      actions: actions,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      // Add a shadow to make it more distinct
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }
}
