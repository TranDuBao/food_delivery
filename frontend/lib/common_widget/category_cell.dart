import 'package:flutter/material.dart';

import '../common/color_extension.dart';

class CategoryCell extends StatelessWidget {
  final Map cObj;
  final VoidCallback onTap;
  final bool isSelected;
  const CategoryCell({
    super.key,
    required this.cObj,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            _buildCategoryLogo(),
            const SizedBox(
              height: 8,
            ),
            Text(
              cObj["name"],
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? TColor.primary : TColor.primaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLogo() {
    final icon = cObj["icon"];
    final bgColor = cObj["bgColor"] is Color
        ? cObj["bgColor"] as Color
        : const Color(0xFFFFE8D9);

    if (icon is IconData) {
      return Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? TColor.primary : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 34,
          color: TColor.primary,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        cObj["image"].toString(),
        width: 85,
        height: 85,
        fit: BoxFit.cover,
      ),
    );
  }
}