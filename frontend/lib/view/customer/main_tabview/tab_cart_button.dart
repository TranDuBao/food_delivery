// lib/view/customer/main_tabview/tab_cart_button.dart
// Widget tab Giỏ hàng với badge số lượng sản phẩm.

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';

class TabCartButton extends StatelessWidget {
  final bool isSelected;
  final int cartCount;
  final VoidCallback onTap;

  const TabCartButton({
    super.key,
    required this.isSelected,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/img/shopping_cart.png',
                width: 25,
                height: 25,
                color: isSelected ? TColor.primary : TColor.placeholder,
              ),
              if (cartCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Cart',
            style: TextStyle(
              color: isSelected ? TColor.primary : TColor.placeholder,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
