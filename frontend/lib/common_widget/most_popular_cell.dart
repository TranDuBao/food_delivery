import 'package:flutter/material.dart';

import '../common/color_extension.dart';
import 'app_image_view.dart';

class MostPopularCell extends StatelessWidget {
  final Map mObj;
  final VoidCallback onTap;
  const MostPopularCell({super.key, required this.mObj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppImageView(
                path: mObj["imageUrl"]?.toString() ?? mObj["image"]?.toString(),
                width: 220,
                height: 130,
                fit: BoxFit.cover,
                placeholderAsset: 'assets/img/app_logo.png',
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              mObj["name"]?.toString() ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: TColor.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(
              height: 4,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    [
                      if ((mObj["type"]?.toString() ?? '').isNotEmpty) mObj["type"]?.toString(),
                      if ((mObj["food_type"]?.toString() ?? '').isNotEmpty) mObj["food_type"]?.toString(),
                    ].join(' . '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  "assets/img/rate.png",
                  width: 10,
                  height: 10,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 4),
                Text(
                  mObj["rate"]?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TColor.primary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
