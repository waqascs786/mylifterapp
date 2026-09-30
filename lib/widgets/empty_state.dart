import 'package:flutter/material.dart';

enum EmptyStateType { noCourses, noResults, noWishlist, noInternet, custom }

class EmptyState extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final String? illustration;
  final Widget? illustrationWidget;
  final String? buttonText;
  final VoidCallback? onButtonTap;
  final IconData? icon;

  const EmptyState({
    super.key,
    this.type = EmptyStateType.custom,
    this.title,
    this.subtitle,
    this.illustration,
    this.illustrationWidget,
    this.buttonText,
    this.onButtonTap,
    this.icon,
  });

  const EmptyState.noCourses({
    super.key,
    this.buttonText,
    this.onButtonTap,
  })  : type = EmptyStateType.noCourses,
        title = 'No Courses Yet',
        subtitle = 'Start exploring and enroll in courses to begin learning',
        illustration = null,
        illustrationWidget = null,
        icon = Icons.school_outlined;

  const EmptyState.noResults({
    super.key,
    this.buttonText,
    this.onButtonTap,
  })  : type = EmptyStateType.noResults,
        title = 'No Results Found',
        subtitle = 'Try adjusting your search or filter to find what you\'re looking for',
        illustration = null,
        illustrationWidget = null,
        icon = Icons.search_off;

  const EmptyState.noWishlist({
    super.key,
    this.buttonText,
    this.onButtonTap,
  })  : type = EmptyStateType.noWishlist,
        title = 'No Wishlisted Courses',
        subtitle = 'Save courses you\'re interested in to view them later',
        illustration = null,
        illustrationWidget = null,
        icon = Icons.favorite_border;

  const EmptyState.noInternet({
    super.key,
    this.buttonText,
    this.onButtonTap,
  })  : type = EmptyStateType.noInternet,
        title = 'No Internet Connection',
        subtitle = 'Please check your internet connection and try again',
        illustration = null,
        illustrationWidget = null,
        icon = Icons.wifi_off;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(config, theme),
            const SizedBox(height: 24),
            Text(
              config.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              config.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (config.buttonText != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(config.buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(EmptyStateConfig config, ThemeData theme) {
    if (illustrationWidget != null) {
      return illustrationWidget!;
    }

      if (illustration != null) {
      return Image.asset(
        illustration!,
        width: 150,
        height: 150,
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        size: 60,
        color: theme.primaryColor.withOpacity(0.6),
      ),
    );
  }

  EmptyStateConfig _getConfig() {
    switch (type) {
      case EmptyStateType.noCourses:
        return EmptyStateConfig(
          title: title ?? 'No Courses Yet',
          subtitle: subtitle ?? 'Start exploring and enroll in courses to begin learning',
          buttonText: buttonText ?? 'Browse Courses',
          icon: icon ?? Icons.school_outlined,
        );
      case EmptyStateType.noResults:
        return EmptyStateConfig(
          title: title ?? 'No Results Found',
          subtitle: subtitle ?? 'Try adjusting your search or filter to find what you\'re looking for',
          buttonText: buttonText ?? 'Clear Filters',
          icon: icon ?? Icons.search_off,
        );
      case EmptyStateType.noWishlist:
        return EmptyStateConfig(
          title: title ?? 'No Wishlisted Courses',
          subtitle: subtitle ?? 'Save courses you\'re interested in to view them later',
          buttonText: buttonText ?? 'Discover Courses',
          icon: icon ?? Icons.favorite_border,
        );
      case EmptyStateType.noInternet:
        return EmptyStateConfig(
          title: title ?? 'No Internet Connection',
          subtitle: subtitle ?? 'Please check your internet connection and try again',
          buttonText: buttonText ?? 'Retry',
          icon: icon ?? Icons.wifi_off,
        );
      case EmptyStateType.custom:
        return EmptyStateConfig(
          title: title ?? 'Nothing Here',
          subtitle: subtitle ?? '',
          buttonText: buttonText,
          icon: icon ?? Icons.inbox_outlined,
        );
    }
  }
}

class EmptyStateConfig {
  final String title;
  final String subtitle;
  final String? buttonText;
  final IconData? icon;

  const EmptyStateConfig({
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.icon,
  });
}
