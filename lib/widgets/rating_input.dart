import 'package:flutter/material.dart';

class RatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final bool allowHalfStars;
  final String? label;

  const RatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 32.0,
    this.allowHalfStars = false,
    this.label,
  });

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1.0;
                  widget.onRatingChanged(_rating);
                });
              },
              onHorizontalDragUpdate: (details) {
                if (widget.allowHalfStars) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final tapPos = box.globalToLocal(details.globalPosition);
                  final newRating = (tapPos.dx / box.size.width).clamp(0.0, 5.0);
                  setState(() {
                    _rating = newRating;
                    widget.onRatingChanged(_rating);
                  });
                }
              },
              child: Icon(
                _getStarIcon(index),
                size: widget.size,
                color: _getStarColor(index),
              ),
            );
          }),
        ),
        if (widget.allowHalfStars) ...[
          const SizedBox(height: 4),
          Text(
            'Rating: ${_rating.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStarIcon(int index) {
    if (index < _rating) {
      return Icons.star;
    } else if (widget.allowHalfStars && index < _rating + 0.5) {
      return Icons.star_half;
    }
    return Icons.star_border;
  }

  Color _getStarColor(int index) {
    if (index < _rating) {
      return Colors.amber;
    } else if (widget.allowHalfStars && index < _rating + 0.5) {
      return Colors.amber;
    }
    return Colors.grey[300]!;
  }
}

/// Display-only rating stars (non-interactive)
class RatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final int? reviewCount;
  final bool showCount;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.size = 20.0,
    this.reviewCount,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          IconData starIcon;
          Color starColor;

          if (index < rating.floor()) {
            starIcon = Icons.star;
            starColor = Colors.amber;
          } else if (index < rating) {
            starIcon = Icons.star_half;
            starColor = Colors.amber;
          } else {
            starIcon = Icons.star_border;
            starColor = Colors.grey[300]!;
          }

          return Icon(
            starIcon,
            size: size,
            color: starColor,
          );
        }),
        if (showCount && reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}

/// Rating bar showing distribution of ratings
class RatingBar extends StatelessWidget {
  final Map<String, int> distribution;
  final double averageRating;
  final int totalReviews;
  final ValueChanged<int>? onRatingTap;

  const RatingBar({
    super.key,
    required this.distribution,
    required this.averageRating,
    required this.totalReviews,
    this.onRatingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Average rating
        SizedBox(
          width: 50,
          child: Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '($totalReviews reviews)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Rating bars
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final starRating = 5 - index;
              final count = distribution[starRating.toString()] ?? 0;
              final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

              return InkWell(
                onTap: onRatingTap != null ? () => onRatingTap!(starRating) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$starRating',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            width: MediaQuery.of(context).size.width * 0.5 * percentage,
                          ),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}