import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final bool compact;

  const RatingDisplay({super.key, required this.rating, required this.count, this.compact = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          if (!compact) ...[
            const SizedBox(width: 3),
            Text(
              '($count)',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ],
      );
}
