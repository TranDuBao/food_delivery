import 'package:flutter/material.dart';

import '../common/color_extension.dart';
import 'app_image_view.dart';

class MenuItemRow extends StatelessWidget {
  final Map mObj;
  final VoidCallback onTap;
  const MenuItemRow({super.key, required this.mObj, required this.onTap});

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    final val = (price as num?)?.toInt() ?? 0;
    if (val <= 0) return '';
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer}đ';
  }

  @override
  Widget build(BuildContext context) {
    final rateStr = mObj["rate"]?.toString() ?? '';
    final hasRating = rateStr.isNotEmpty;
    final ratingCount = mObj["rating"]?.toString() ?? '';
    final priceFormatted = _formatPrice(mObj["price"]);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              AppImageView(
                path: mObj["imageUrl"]?.toString() ?? mObj["image"]?.toString(),
                width: double.maxFinite,
                height: 200,
                fit: BoxFit.cover,
                placeholderAsset: 'assets/img/app_logo.png',
              ),
              Container(
                width: double.maxFinite,
                height: 200,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mObj["name"]?.toString() ?? '',
                          textAlign: TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Sao rating
                            if (hasRating) ...[
                              Icon(Icons.star_rounded,
                                  color: const Color(0xFFFFB800), size: 13),
                              const SizedBox(width: 3),
                              Text(
                                rateStr,
                                style: TextStyle(
                                    color: TColor.primary, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              if (ratingCount.isNotEmpty) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '($ratingCount)',
                                  style: TextStyle(
                                      color: TColor.white.withValues(alpha: 0.7), fontSize: 10),
                                ),
                              ],
                              const SizedBox(width: 8),
                            ],
                            // Giá tiền
                            if (priceFormatted.isNotEmpty) ...[
                              Text(
                                priceFormatted,
                                style: TextStyle(
                                  color: TColor.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                [
                                  if ((mObj["type"]?.toString() ?? '').isNotEmpty)
                                    mObj["type"]?.toString(),
                                  if ((mObj["food_type"]?.toString() ?? '').isNotEmpty)
                                    mObj["food_type"]?.toString()
                                ].join(' · '),
                                textAlign: TextAlign.start,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: TColor.white.withValues(alpha: 0.85), fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
