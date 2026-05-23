// lib/view/customer/home/home_recent_items.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/recent_item_row.dart';
import 'package:food_delivery/common_widget/view_all_title_row.dart';
import '../menu/all_dishes_view.dart';
import '../menu/item_details_view.dart';

/// Section "Recent Items / Món ăn" (dưới cùng) trên HomeView.
class HomeRecentItems extends StatelessWidget {
  final List<Map<String, dynamic>> dishes;
  final bool isCategorySelected;
  final String? selectedCategory;
  final bool isSearching;

  const HomeRecentItems({
    super.key,
    required this.dishes,
    required this.isCategorySelected,
    required this.selectedCategory,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ViewAllTitleRow(
            title: isSearching ? 'Kết quả tìm kiếm' : (isCategorySelected ? 'Món ăn' : 'Recent Items'),
            onView: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllDishesView(
                  initialCategory: isCategorySelected ? selectedCategory : null,
                ),
              ),
            ),
          ),
        ),
        if (dishes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              isCategorySelected
                  ? 'Không tìm thấy món trong danh mục đã chọn'
                  : 'Không có món phù hợp',
              style: TextStyle(color: TColor.secondaryText, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: dishes.length,
            itemBuilder: (context, index) {
              final rObj = dishes[index];
              return RecentItemRow(
                rObj: rObj,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailsView(dishObj: rObj)),
                ),
              );
            },
          ),
      ],
    );
  }
}
