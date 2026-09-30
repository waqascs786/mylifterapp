import 'package:flutter/material.dart';

class CircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final Color? textColor;
  final double? fontSize;
  final bool showPercentage;
  final String? label;
  final Widget? child;

  const CircularProgress({
    super.key,
    required this.value,
    this.size = 80,
    this.strokeWidth = 6,
    this.backgroundColor,
    this.valueColor,
    this.textColor,
    this.fontSize,
    this.showPercentage = true,
    this.label,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? Colors.grey[200]!;
    final valColor = valueColor ?? theme.primaryColor;
    final txtColor = textColor ?? theme.colorScheme.onSurface;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: strokeWidth,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(valColor),
                );
              },
            ),
          ),
          if (child != null)
            child!
          else if (showPercentage)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: fontSize ?? (size * 0.22),
                    fontWeight: FontWeight.w700,
                    color: txtColor,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: (fontSize ?? (size * 0.22)) * 0.5,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class LinearProgress extends StatelessWidget {
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;
  final BorderRadius? borderRadius;
  final bool showLabel;
  final String? label;
  final TextStyle? labelStyle;

  const LinearProgress({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    this.borderRadius,
    this.showLabel = false,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? Colors.grey[200]!;
    final valColor = valueColor ?? theme.primaryColor;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label ?? 'Progress',
                  style: labelStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  '${(value * 100).toInt()}%',
                  style: labelStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  backgroundColor: bgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(valColor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class StepProgress extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final bool showLabels;
  final List<String>? labels;

  const StepProgress({
    super.key,
    required this.totalSteps,
    required this.completedSteps,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.showLabels = false,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.primaryColor;
    final inactive = inactiveColor ?? Colors.grey[300]!;
    final completed = completedColor ?? Colors.green;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < completedSteps;
        final isCurrent = index == completedSteps;

        return Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: isCompleted || isCurrent ? 1 : 0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              builder: (context, animValue, child) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      inactive,
                      isCompleted ? completed : active,
                      animValue,
                    ),
                    border: Border.all(
                      color: isCompleted ? completed : active,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(Icons.check, size: size * 0.5, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 0.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
            ),
            if (index < totalSteps - 1)
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: index < completedSteps ? 1 : 0,
                  ),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  builder: (context, animValue, child) {
                    return Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: Color.lerp(inactive, completed, animValue),
                    );
                  },
                ),
              ),
          ],
        );
      }),
    );
  }
}
