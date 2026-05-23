import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/app_image_view.dart';
import 'package:food_delivery/view/customer/menu/item_details_view.dart';

// ─── Sort options ─────────────────────────────────────────────────────────────
enum _SortMode { relevant, newest, bestseller, priceAsc, priceDesc }

class AllDishesView extends StatefulWidget {
  /// Nếu muốn pre-filter theo danh mục
  final String? initialCategory;

  const AllDishesView({super.key, this.initialCategory});

  @override
  State<AllDishesView> createState() => _AllDishesViewState();
}

class _AllDishesViewState extends State<AllDishesView> {
  final TextEditingController _search = TextEditingController();

  late Future<List<Map<String, dynamic>>> _future;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  _SortMode _sort = _SortMode.relevant;
  bool _priceDescToggle = false; // cho nút Giá toggle asc/desc

  @override
  void initState() {
    super.initState();
    _future = _load();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final res = await ServiceCall.fetchGet(
        SVKey.svCanteenDishes,
        isToken: true,
      );
      final data = res is Map ? res['data'] : res;
      final list = (data as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _all = list;
        _applyFilter();
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    List<Map<String, dynamic>> result = List.from(_all);

    // Lọc theo danh mục khởi đầu
    final cat = widget.initialCategory;
    if (cat != null && cat.isNotEmpty) {
      result = result
          .where((d) =>
              (d['categoryName']?.toString() ?? '')
                  .toLowerCase()
                  .contains(cat.toLowerCase()))
          .toList();
    }

    // Tìm kiếm
    if (q.isNotEmpty) {
      result = result
          .where((d) =>
              (d['name']?.toString() ?? '').toLowerCase().contains(q) ||
              (d['canteenName']?.toString() ?? '')
                  .toLowerCase()
                  .contains(q) ||
              (d['categoryName']?.toString() ?? '')
                  .toLowerCase()
                  .contains(q))
          .toList();
    }

    // Sắp xếp
    switch (_sort) {
      case _SortMode.relevant:
        break;
      case _SortMode.newest:
        // Không có timestamp → dùng id giảm dần
        result.sort((a, b) =>
            ((b['id'] as num?) ?? 0)
                .compareTo((a['id'] as num?) ?? 0));
        break;
      case _SortMode.bestseller:
        result.sort((a, b) =>
            ((b['soLuongDaBan'] as num?) ?? 0)
                .compareTo((a['soLuongDaBan'] as num?) ?? 0));
        break;
      case _SortMode.priceAsc:
        result.sort((a, b) =>
            ((a['price'] as num?) ?? 0)
                .compareTo((b['price'] as num?) ?? 0));
        break;
      case _SortMode.priceDesc:
        result.sort((a, b) =>
            ((b['price'] as num?) ?? 0)
                .compareTo((a['price'] as num?) ?? 0));
        break;
    }

    setState(() => _filtered = result);
  }

  void _setSort(_SortMode mode) {
    if (mode == _SortMode.priceAsc || mode == _SortMode.priceDesc) {
      // Toggle giá asc/desc
      setState(() {
        _priceDescToggle = !_priceDescToggle;
        _sort = _priceDescToggle ? _SortMode.priceDesc : _SortMode.priceAsc;
      });
    } else {
      setState(() => _sort = mode);
    }
    _applyFilter();
  }

  String _formatPrice(dynamic v) {
    final num? n = v is num ? v : num.tryParse(v?.toString() ?? '');
    if (n == null) return '';
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  String _formatSold(dynamic v) {
    final int n =
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    if (n <= 0) return '';
    if (n >= 1000) {
      final k = n / 1000;
      return 'Đã bán ${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k';
    }
    return 'Đã bán $n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: TColor.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: _SearchBar(controller: _search),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.tune_rounded,
                color: TColor.primaryText, size: 22),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // ── Sort bar ──────────────────────────────────────
              _SortBar(
                current: _sort,
                priceDescToggle: _priceDescToggle,
                onSelect: _setSort,
              ),

              // ── Grid ──────────────────────────────────────────
              Expanded(
                child: _filtered.isEmpty
                    ? _EmptyState(hasSearch: _search.text.isNotEmpty)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _DishCard(
                          dish: _filtered[i],
                          formatPrice: _formatPrice,
                          formatSold: _formatSold,
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ItemDetailsView(dishObj: _filtered[i]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm món ăn...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
          border: InputBorder.none,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Sort bar ─────────────────────────────────────────────────────────────────
class _SortBar extends StatelessWidget {
  final _SortMode current;
  final bool priceDescToggle;
  final void Function(_SortMode) onSelect;

  const _SortBar({
    required this.current,
    required this.priceDescToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_SortMode.relevant, 'Liên quan', null),
      (_SortMode.newest, 'Mới nhất', null),
      (_SortMode.bestseller, 'Bán chạy', null),
      (
        priceDescToggle ? _SortMode.priceDesc : _SortMode.priceAsc,
        'Giá',
        priceDescToggle
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded
      ),
    ];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: tabs.map((tab) {
                final mode = tab.$1;
                final label = tab.$2;
                final icon = tab.$3;
                final isPriceTab =
                    mode == _SortMode.priceAsc || mode == _SortMode.priceDesc;
                final isActive =
                    isPriceTab ? (current == _SortMode.priceAsc || current == _SortMode.priceDesc) : current == mode;

                return GestureDetector(
                  onTap: () => onSelect(mode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive
                                ? TColor.primary
                                : TColor.secondaryText,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 2),
                          Icon(icon,
                              size: 14,
                              color: isActive
                                  ? TColor.primary
                                  : TColor.secondaryText),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Active indicator
          Row(
            children: tabs.map((tab) {
              final mode = tab.$1;
              final isPriceTab =
                  mode == _SortMode.priceAsc || mode == _SortMode.priceDesc;
              final isActive =
                  isPriceTab ? (current == _SortMode.priceAsc || current == _SortMode.priceDesc) : current == mode;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isActive ? TColor.primary : Colors.transparent,
                ),
              );
            }).toList(),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

// ─── Dish card (grid) ─────────────────────────────────────────────────────────
class _DishCard extends StatelessWidget {
  final Map<String, dynamic> dish;
  final String Function(dynamic) formatPrice;
  final String Function(dynamic) formatSold;
  final VoidCallback onTap;

  const _DishCard({
    required this.dish,
    required this.formatPrice,
    required this.formatSold,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rate = (dish['rate'] as num?)?.toDouble() ??
        double.tryParse(dish['rate']?.toString() ?? '') ??
        0.0;
    final luot = (dish['rating'] as num?)?.toInt() ??
        int.tryParse(dish['rating']?.toString() ?? '') ??
        0;
    final sold = dish['soLuongDaBan'];
    final soldStr = formatSold(sold);
    final hasRate = rate > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ảnh ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppImageView(
                  path: dish['imageUrl']?.toString(),
                  fit: BoxFit.cover,
                  placeholderAsset: 'assets/img/app_logo.png',
                ),
              ),
            ),

            // ── Nội dung ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên
                    Text(
                      dish['name']?.toString() ?? '',
                      style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Gian hàng
                    if ((dish['canteenName']?.toString() ?? '').isNotEmpty)
                      Text(
                        dish['canteenName'].toString(),
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Sao + đã bán
                    if (hasRate || soldStr.isNotEmpty)
                      Row(
                        children: [
                          if (hasRate) ...[
                            Icon(Icons.star_rounded,
                                size: 12,
                                color: const Color(0xFFFFC107)),
                            const SizedBox(width: 2),
                            Text(
                              rate.toStringAsFixed(1),
                              style: TextStyle(
                                color: TColor.primaryText
                                    .withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (luot > 0) ...[
                              const SizedBox(width: 2),
                              Text(
                                '($luot)',
                                style: TextStyle(
                                  color: TColor.secondaryText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                          ],
                          if (soldStr.isNotEmpty)
                            Flexible(
                              child: Text(
                                soldStr,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 4),

                    // Giá
                    Text(
                      formatPrice(dish['price']),
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasSearch ? Icons.search_off_rounded : Icons.restaurant_menu_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'Không tìm thấy món phù hợp' : 'Chưa có món ăn nào',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
