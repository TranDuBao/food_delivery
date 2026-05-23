// lib/view/customer/home/home_meal_suggestion.dart
import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/view_all_title_row.dart';
import '../menu/all_dishes_view.dart';

/// Widget section "Gợi ý bữa trưa / sáng / tối" theo giờ thực.
class HomeMealSuggestion extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onDishTap;

  const HomeMealSuggestion({
    super.key,
    required this.title,
    required this.suggestions,
    required this.isLoading,
    required this.onDishTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ViewAllTitleRow(
            title: title,
            onView: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllDishesView()),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : suggestions.isEmpty
                  ? Center(
                      child: Text(
                        'Chưa có gợi ý phù hợp giờ này',
                        style: TextStyle(color: TColor.secondaryText, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final dish = suggestions[index];
                        return _SuggestionCard(
                          dish: dish,
                          onTap: () => onDishTap(dish),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ── Card nhỏ hiển thị từng món ──────────────────────────────────────────────
class _SuggestionCard extends StatelessWidget {
  final Map<String, dynamic> dish;
  final VoidCallback onTap;

  const _SuggestionCard({required this.dish, required this.onTap});

  String _formatPrice(dynamic value) {
    final num? v = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (v == null) return '';
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final name     = dish['name']?.toString() ?? '';
    final price    = dish['price'];
    final imageUrl = dish['imageUrl']?.toString();
    final rateStr  = dish['rate']?.toString() ?? '';
    final hasRate  = rateStr.isNotEmpty && rateStr != '0' && rateStr != '0.0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      width: 150,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Nội dung
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (price != null)
                        Text(
                          _formatPrice(price),
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (hasRate)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFC107)),
                            const SizedBox(width: 2),
                            Text(rateStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 150,
        height: 100,
        color: const Color(0xFFF5F5F5),
        child: const Icon(Icons.restaurant, color: Colors.grey, size: 36),
      );
}
