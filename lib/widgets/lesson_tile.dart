import 'package:flutter/material.dart';

class LessonTile extends StatelessWidget {
  final int lessonNumber;
  final String title;
  final String duration;
  final bool isCompleted;
  final bool isLocked;
  final bool isPlaying;
  final VoidCallback? onTap;

  const LessonTile({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.duration,
    this.isCompleted = false,
    this.isLocked = false,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildLeadingIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                          color: isLocked ? Colors.grey[400] : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        duration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTrailingIcon(theme),
              ],
            ),
          ),
        ),
        Divider(height: 1, indent: 52, color: Colors.grey[200]),
      ],
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    if (isCompleted) {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 20),
      );
    }

    if (isLocked) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock_outline, color: Colors.grey[400], size: 18),
      );
    }

    if (isPlaying) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow, color: Colors.white, size: 22),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        lessonNumber.toString().padLeft(2, '0'),
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrailingIcon(ThemeData theme) {
    if (isLocked) {
      return Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]);
    }

    if (isPlaying) {
      return Icon(Icons.equalizer, size: 20, color: theme.primaryColor);
    }

    return Icon(Icons.chevron_right, size: 22, color: Colors.grey[400]);
  }
}

class LessonTileGroup extends StatelessWidget {
  final String sectionTitle;
  final int? sectionNumber;
  final List<LessonTile> lessons;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const LessonTileGroup({
    super.key,
    this.sectionTitle = '',
    this.sectionNumber,
    required this.lessons,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Row(
              children: [
                if (sectionNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Section $sectionNumber',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    sectionTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${lessons.length} lessons',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, size: 20),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(children: lessons),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}
