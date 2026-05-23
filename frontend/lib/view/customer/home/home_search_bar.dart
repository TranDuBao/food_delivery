// lib/view/customer/home/home_search_bar.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_textfield.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final List<String> suggestions;
  final bool isCategorySelected;
  final ValueChanged<String> onSuggestionTap;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.suggestions,
    required this.isCategorySelected,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RoundTextfield(
          hintText: isCategorySelected
              ? 'Tìm món ăn trong danh mục'
              : 'Tìm món ăn hoặc căn tin',
          controller: controller,
          left: Container(
            alignment: Alignment.center,
            width: 30,
            child: Image.asset('assets/img/search.png', width: 20, height: 20),
          ),
        ),
        if (searchQuery.trim().isNotEmpty &&
            suggestions.isNotEmpty &&
            !(suggestions.length == 1 &&
                suggestions.first.toLowerCase().trim() ==
                    searchQuery.toLowerCase().trim()))
          Container(
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: TColor.placeholder.withValues(alpha: 0.25)),
              itemBuilder: (context, index) {
                final s = suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    s,
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => onSuggestionTap(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
