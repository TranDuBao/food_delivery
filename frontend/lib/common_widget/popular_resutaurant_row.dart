import 'package:flutter/material.dart';

import '../common/color_extension.dart';
import 'app_image_view.dart';

class PopularRestaurantRow extends StatelessWidget {
  final Map pObj;
  final VoidCallback onTap;
  const PopularRestaurantRow({super.key, required this.pObj, required this.onTap});

  /// Xây dựng widget hiển thị sao từ avgRating
  Widget _buildStarRating(double? avgRating, int totalReviews) {
    if (avgRating == null || avgRating <= 0) {
      return Row(
        children: [
          Icon(Icons.star_border_rounded, color: Colors.grey[400], size: 14),
          const SizedBox(width: 4),
          Text(
            'Chưa có đánh giá',
            style: TextStyle(color: TColor.secondaryText, fontSize: 11),
          ),
        ],
      );
    }

    final full = avgRating.floor();
    final half = (avgRating - full) >= 0.25 && (avgRating - full) < 0.75;
    final empty = 5 - full - (half ? 1 : 0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Các ngôi sao
        ...List.generate(full, (_) => Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: 14)),
        if (half) Icon(Icons.star_half_rounded, color: const Color(0xFFFFB800), size: 14),
        ...List.generate(empty, (_) => Icon(Icons.star_border_rounded, color: const Color(0xFFFFB800), size: 14)),
        const SizedBox(width: 5),
        Text(
          avgRating.toStringAsFixed(1),
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalReviews đánh giá)',
          style: TextStyle(color: TColor.secondaryText, fontSize: 11),
        ),
      ],
    );
  }

  /// Xây dựng chip món ăn nổi bật
  Widget _buildTopDishChip(Map<String, dynamic> dish, BuildContext context) {
    final imageUrl = dish['imageUrl']?.toString();
    final name = dish['name']?.toString() ?? '';
    final price = (dish['price'] as num?)?.toDouble() ?? 0;
    final rating = (dish['rating'] as num?)?.toDouble() ?? 0;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh món ăn
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AppImageView(
              path: imageUrl,
              width: 120,
              height: 80,
              fit: BoxFit.cover,
              placeholderAsset: 'assets/img/app_logo.png',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rating > 0) ...[
                      Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: 11),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        '${_formatPrice(price)}đ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TColor.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    if (price <= 0) return '0';
    final val = price.toInt();
    // Định dạng 1000 → 1.000
    final str = val.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final avgRating = (pObj['avgRating'] as num?)?.toDouble();
    final totalReviews = (pObj['totalReviews'] as num?)?.toInt() ?? 0;
    final topDishes = (pObj['topDishes'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh banner gian hàng
            ClipRRect(
              child: AppImageView(
                path: pObj["imageUrl"]?.toString() ?? pObj["image"]?.toString(),
                width: double.maxFinite,
                height: 180,
                fit: BoxFit.cover,
                placeholderAsset: 'assets/img/app_logo.png',
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên gian hàng
                  Text(
                    pObj["name"]?.toString() ?? '',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Sao rating
                  _buildStarRating(avgRating, totalReviews),

                  const SizedBox(height: 4),

                  // Địa điểm / giờ mở cửa
                  Text(
                    [
                      if ((pObj["type"]?.toString() ?? '').isNotEmpty)
                        pObj["type"]?.toString(),
                      if ((pObj["food_type"]?.toString() ?? '').isNotEmpty)
                        pObj["food_type"]?.toString(),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                  ),

                  // Top 3 món nổi bật (chỉ hiển thị nếu có)
                  if (topDishes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Món nổi bật',
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 148,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: topDishes.length,
                        itemBuilder: (context, index) =>
                            _buildTopDishChip(topDishes[index], context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                ],
              ),
            ),

            // Đường kẻ phân cách
            const Divider(height: 20, thickness: 1, indent: 20, endIndent: 20),
          ],
        ),
      ),
    );
  }
}
