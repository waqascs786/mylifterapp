import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double maxRating;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final Color halfColor;
  final bool showHalfStars;
  final int? ratingCount;
  final bool showRatingCount;

  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.filledColor = Colors.amber,
    this.emptyColor = Colors.grey,
    this.halfColor = Colors.amber,
    this.showHalfStars = true,
    this.ratingCount,
    this.showRatingCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStars(),
        if (showRatingCount && ratingCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($ratingCount)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating.toInt(), (index) {
        return _buildStar(index + 1);
      }),
    );
  }

  Widget _buildStar(int starIndex) {
    if (starIndex <= rating.floor()) {
      return Icon(Icons.star, size: size, color: filledColor);
    }

    if (showHalfStars && starIndex - 0.5 <= rating) {
      return Icon(Icons.star_half, size: size, color: halfColor);
    }

    return Icon(Icons.star_border, size: size, color: emptyColor);
  }
}

class InteractiveRating extends StatefulWidget {
  final double initialRating;
  final double maxRating;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final ValueChanged<double>? onRatingChanged;
  final bool allowHalfRating;

  const InteractiveRating({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 32,
    this.filledColor = Colors.amber,
    this.emptyColor = Colors.grey,
    this.onRatingChanged,
    this.allowHalfRating = false,
  });

  @override
  State<InteractiveRating> createState() => _InteractiveRatingState();
}

class _InteractiveRatingState extends State<InteractiveRating> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(InteractiveRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _currentRating = widget.initialRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating.toInt(), (index) {
        return GestureDetector(
          onTap: () {
            final newRating = index + 1.0;
            setState(() => _currentRating = newRating);
            widget.onRatingChanged?.call(newRating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _buildStar(index + 1),
          ),
        );
      }),
    );
  }

  Widget _buildStar(int starIndex) {
    IconData icon;
    Color color;

    if (starIndex <= _currentRating.floor()) {
      icon = Icons.star;
      color = widget.filledColor;
    } else if (widget.allowHalfRating && starIndex - 0.5 <= _currentRating) {
      icon = Icons.star_half;
      color = widget.filledColor;
    } else {
      icon = Icons.star_border;
      color = widget.emptyColor;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        icon,
        key: ValueKey('$starIndex-$color'),
        size: widget.size,
        color: color,
      ),
    );
  }
}

class RatingBar extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final int maxStars;
  final int barCount;
  final Color barColor;
  final Color emptyBarColor;
  final double barHeight;
  final TextStyle? labelStyle;

  const RatingBar({
    super.key,
    required this.rating,
    this.totalRatings = 0,
    this.maxStars = 5,
    this.barCount = 5,
    this.barColor = Colors.amber,
    this.emptyBarColor = Colors.grey,
    this.barHeight = 8,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: (labelStyle ?? const TextStyle()).copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingWidget(rating: rating, size: 16),
                if (totalRatings > 0)
                  Text(
                    '$totalRatings ratings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(barCount, (index) {
          final starValue = maxStars - index;
          final percentage = starValue <= rating ? 1.0 : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  '$starValue',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.star, size: 12, color: barColor),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(barHeight / 2),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: emptyBarColor,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      minHeight: barHeight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
