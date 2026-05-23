import 'package:flutter/material.dart';

import '../common/app_alert.dart';
import '../common/color_extension.dart';
import '../common/globs.dart';
import '../common/service_call.dart';
import 'app_image_view.dart';

class RecentItemRow extends StatelessWidget {
  final Map rObj;
  final VoidCallback onTap;
  const RecentItemRow(
      {super.key, required this.rObj, required this.onTap});

  /// Format giá → "38.000 đ"
  String _formatPrice(dynamic value) {
    final num? v =
        value is num ? value : num.tryParse(value?.toString() ?? '');
    if (v == null) return '';
    final formatted = v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  /// Format sold → "1.2k" nếu >= 1000
  String _formatSold(dynamic value) {
    final int v =
        value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
    if (v <= 0) return '';
    if (v >= 1000) {
      final k = v / 1000;
      return 'Đã bán ${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return 'Đã bán $v';
  }

  @override
  Widget build(BuildContext context) {
    final price = rObj['price'] ?? rObj['giaTien'];
    final sold = rObj['soLuongDaBan'];
    final rateStr = rObj['rate']?.toString() ?? '';
    final ratingCountStr = rObj['rating']?.toString() ?? '';
    final soldStr = _formatSold(sold);
    final hasRate = rateStr.isNotEmpty && rateStr != '0' && rateStr != '0.0';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Ảnh ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppImageView(
                      path: rObj["imageUrl"]?.toString() ??
                          rObj["image"]?.toString(),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholderAsset: 'assets/img/app_logo.png',
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Nội dung ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên món
                    Text(
                      rObj["name"]?.toString() ?? '',
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Gian hàng / danh mục
                    if ((rObj["food_type"]?.toString() ?? '').isNotEmpty)
                      Text(
                        rObj["food_type"].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 12,
                        ),
                      ),

                    const SizedBox(height: 6),

                    // ─ Hàng dưới: sao + đã bán ─
                    Row(
                      children: [
                        // Sao
                        if (hasRate) ...[
                          Icon(Icons.star_rounded,
                              size: 13, color: const Color(0xFFFFC107)),
                          const SizedBox(width: 2),
                          Text(
                            rateStr,
                            style: TextStyle(
                              color:
                                  TColor.primaryText.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (ratingCountStr.isNotEmpty &&
                              ratingCountStr != '0') ...[
                            const SizedBox(width: 3),
                            Text(
                              '($ratingCountStr)',
                              style: TextStyle(
                                color: TColor.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                        ],

                        // Đã bán
                        if (soldStr.isNotEmpty) ...[
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 12,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            soldStr,
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ─ Giá nổi bật (giống Shopee) ─
                    if (price != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _formatPrice(price),
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              try {
                                final rawId = rObj['maMonAn'] ?? rObj['id'] ?? rObj['dishId'];
                                final resolvedDishId = int.tryParse(rawId?.toString() ?? '');
                                if (resolvedDishId != null && resolvedDishId > 0) {
                                  await ServiceCall.fetchPost(
                                    SVKey.svCartAdd,
                                    isToken: true,
                                    body: {'maMonAn': resolvedDishId, 'soLuong': 1},
                                  );
                                  if (context.mounted) {
                                    AppAlert.show(context, message: 'Đã thêm ${rObj['name'] ?? 'món'} vào giỏ hàng!');
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppAlert.show(context, message: e.toString(), type: 'error');
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 16,
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
        ),
      ),
    );
  }
}
