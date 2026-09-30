import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

enum CourseCardMode { grid, list }

class CourseCard extends StatelessWidget {
  final String thumbnailUrl;
  final String title;
  final String instructorName;
  final String? instructorAvatarUrl;
  final double rating;
  final int ratingCount;
  final double price;
  final double? salePrice;
  final bool isFree;
  final double? progress;
  final bool isEnrolled;
  final CourseCardMode mode;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.thumbnailUrl,
    required this.title,
    required this.instructorName,
    this.instructorAvatarUrl,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.price = 0.0,
    this.salePrice,
    this.isFree = false,
    this.progress,
    this.isEnrolled = false,
    this.mode = CourseCardMode.grid,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return mode == CourseCardMode.grid ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context, height: 140),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInstructorRow(theme),
                  const SizedBox(height: 8),
                  _buildRatingRow(theme),
                  const SizedBox(height: 8),
                  _buildPriceAndProgress(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(context, width: 120, height: 80),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInstructorRow(theme),
                    const SizedBox(height: 6),
                    _buildRatingRow(theme),
                    const SizedBox(height: 6),
                    _buildPriceAndProgress(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, {double? width, double height = 140}) {
    return Hero(
      tag: 'course_thumbnail_$title',
      child: SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.play_circle_outline, size: 40, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructorRow(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundImage: instructorAvatarUrl != null
              ? NetworkImage(instructorAvatarUrl!)
              : null,
          backgroundColor: Colors.grey[300],
          child: instructorAvatarUrl == null
              ? const Icon(Icons.person, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            instructorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.star, size: 14, color: Colors.amber[600]),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($ratingCount)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndProgress(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPriceBadge(theme),
        if (isEnrolled && progress != null) _buildProgressBar(),
      ],
    );
  }

  Widget _buildPriceBadge(ThemeData theme) {
    if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Free',
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      children: [
        if (salePrice != null && salePrice! < price) ...[
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '\$${salePrice!.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
        ] else
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      width: 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(progress! * 100).toInt()}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress! >= 1.0 ? Colors.green : Colors.blue,
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  final CourseCardMode mode;

  const CourseCardShimmer({super.key, this.mode = CourseCardMode.grid});

  @override
  Widget build(BuildContext context) {
    return mode == CourseCardMode.grid ? _buildGridShimmer() : _buildListShimmer();
  }

  Widget _buildGridShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 150, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 180, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 120, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
