import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool isTransparent;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  final bool showSearch;
  final VoidCallback? onSearchTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.isTransparent = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.titleWidget,
    this.bottom,
    this.showSearch = false,
    this.onSearchTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaffold = Scaffold.of(context);
    final hasDrawer = scaffold.hasDrawer;
    final canPop = Navigator.canPop(context);

    final bgColor = isTransparent
        ? Colors.transparent
        : backgroundColor ?? theme.primaryColor;
    final fgColor = foregroundColor ?? Colors.white;

    return AppBar(
      title: titleWidget ?? Text(
        title,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: isTransparent ? 0 : elevation,
      leading: _buildLeading(context, hasDrawer, canPop, fgColor),
      actions: _buildActions(fgColor),
      bottom: bottom,
      flexibleSpace: isTransparent
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget? _buildLeading(BuildContext context, bool hasDrawer, bool canPop, Color fgColor) {
    if (hasDrawer) {
      return IconButton(
        icon: Icon(Icons.menu, color: fgColor),
        onPressed: () => Scaffold.of(context).openDrawer(),
      );
    }

    if (showBackButton && canPop) {
      return IconButton(
        icon: Icon(Icons.arrow_back_ios, color: fgColor, size: 20),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      );
    }

    return null;
  }

  List<Widget>? _buildActions(Color fgColor) {
    final actionList = <Widget>[];

    if (showSearch) {
      actionList.add(
        IconButton(
          icon: Icon(Icons.search, color: fgColor),
          onPressed: onSearchTap,
        ),
      );
    }

    if (actions != null) {
      actionList.addAll(actions!);
    }

    return actionList.isEmpty ? null : actionList;
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Gradient? gradient;
  final Color? startColor;
  final Color? endColor;
  final Widget? titleWidget;

  const GradientAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.gradient,
    this.startColor,
    this.endColor,
    this.titleWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            LinearGradient(
              colors: [
                startColor ?? theme.primaryColor,
                endColor ?? theme.primaryColorDark,
              ],
            ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              if (showBackButton && canPop)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: titleWidget ??
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
              ),
              if (actions != null)
                ...actions!
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  SliverAppBarDelegate({
    required this.child,
    this.minHeight = 56,
    this.maxHeight = 56,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) {
    return child != oldDelegate.child ||
        minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight;
  }
}
