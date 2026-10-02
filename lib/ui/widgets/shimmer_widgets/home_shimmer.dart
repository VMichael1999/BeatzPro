import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../utils/beatz_design.dart';

/// Loading skeleton with the same layout as the home screen.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Shimmer.fromColors(
      baseColor: colors.surface,
      highlightColor: colors.raised,
      enabled: !MediaQuery.disableAnimationsOf(context),
      direction: ShimmerDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tiles(context),
          const SizedBox(height: 22),
          _title(160),
          const SizedBox(height: 10),
          for (var i = 0; i < 4; i++) _row(),
          const SizedBox(height: 14),
          _tiles(context),
        ],
      ),
    );
  }

  Widget _box(double w, double h, {double r = 8}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(r)),
      );

  Widget _title(double w) => _box(w, 20);

  Widget _tiles(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 36 - 20) / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(140),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(w, w, r: 10),
                  const SizedBox(height: 6),
                  _box(w * 0.8, 12),
                  const SizedBox(height: 4),
                  _box(w * 0.5, 10),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _row() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            _box(44, 44),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(150, 14),
                const SizedBox(height: 6),
                _box(90, 11),
              ],
            ),
          ],
        ),
      );
}
