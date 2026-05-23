// lib/view/customer/more/checkout_cart_items.dart
// Widget danh sách món ăn trong giỏ hàng tại màn xác nhận

import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common_widget/app_image_view.dart';

class CheckoutCartItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double Function(dynamic) toDouble;

  const CheckoutCartItems({
    super.key,
    required this.items,
    required this.toDouble,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Giỏ hàng trống.',
              style: TextStyle(color: TColor.secondaryText)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(
          indent: 16, endIndent: 16,
          color: TColor.secondaryText.withValues(alpha: 0.3),
          height: 1,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppImageView(
                  path: item['imageUrl']?.toString() ?? '',
                  width: 50, height: 50,
                  fit: BoxFit.cover,
                  placeholderAsset: 'assets/img/app_logo.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['dishName']?.toString() ?? '',
                      style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item['canteenName'] ?? '',
                      style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
                  Text('x${item['quantity']}',
                      style: TextStyle(color: TColor.secondaryText, fontSize: 12)),
                ],
              )),
              Text(
                '${toDouble(item['lineTotal']).toStringAsFixed(0)} đ',
                style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ]),
          );
        },
      ),
    );
  }
}
