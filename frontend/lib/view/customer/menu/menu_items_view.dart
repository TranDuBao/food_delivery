import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';

import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/app_image_view.dart';
import '../../../common_widget/recent_item_row.dart';
import '../../../common_widget/round_textfield.dart';
import '../more/my_order_view.dart';
import 'item_details_view.dart';

class MenuItemsView extends StatefulWidget {
  final Map mObj;
  const MenuItemsView({super.key, required this.mObj});

  @override
  State<MenuItemsView> createState() => _MenuItemsViewState();
}

class _MenuItemsViewState extends State<MenuItemsView> {
  final TextEditingController txtSearch = TextEditingController();
  late Future<List<Map<String, dynamic>>> itemsFuture;
  int _cartCount = 0;
  String _searchQuery = '';

  // Thông tin gian hàng từ mObj
  String get _storeName => widget.mObj['name']?.toString() ?? '';
  String get _storeLocation => widget.mObj['type']?.toString() ?? '';
  String get _storeOpenHours => widget.mObj['food_type']?.toString() ?? '';
  String? get _storeBanner =>
      widget.mObj['imageUrl']?.toString() ?? widget.mObj['bannerUrl']?.toString();
  double? get _storeRating => (widget.mObj['avgRating'] as num?)?.toDouble();
  int get _storeTotalReviews => (widget.mObj['totalReviews'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(_onSearchChanged);
    itemsFuture = _loadItems();
    _loadCartCount();
  }

  @override
  void dispose() {
    txtSearch.removeListener(_onSearchChanged);
    txtSearch.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = txtSearch.text);
  }

  Future<void> _loadCartCount() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (res is Map && res['success'] == true) {
        final items = res['data'] as List? ?? [];
        final count = items.fold<int>(0, (sum, item) {
          final sl = (item['soLuong'] as num?)?.toInt() ?? 0;
          return sum + sl;
        });
        if (mounted) setState(() => _cartCount = count);
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    final canteenId =
        (widget.mObj['canteenId'] ?? widget.mObj['id'])?.toString() ?? '';
    if (canteenId.isEmpty) return [];

    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svDishesByCanteen(canteenId),
        isToken: true,
      );
      final raw = response is Map ? (response['data'] ?? response) : response;
      final list = raw as List? ?? [];

      return list.cast<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        final price = map['giaTien'] ?? map['price'];
        final diemDanhGia = (map['diemDanhGia'] as num?)?.toDouble() ?? 0.0;
        final luotDanhGia = (map['luotDanhGia'] as num?)?.toInt() ?? 0;
        final soLuongDaBan = (map['soLuongDaBan'] as num?)?.toInt() ?? 0;
        return {
          'imageUrl'     : map['hinhAnh']?.toString() ?? map['imageUrl']?.toString(),
          'name'         : map['tenMonAn']?.toString() ?? map['name']?.toString() ?? '',
          'rate'         : diemDanhGia > 0 ? diemDanhGia.toStringAsFixed(1) : '',
          'rating'       : luotDanhGia > 0 ? '$luotDanhGia' : '',
          'soLuongDaBan' : soLuongDaBan,
          'type'         : map['tenDanhMuc']?.toString() ?? map['categoryName']?.toString() ?? '',
          'food_type'    : _storeName,
          'dishId'       : map['maMonAn'] ?? map['id'],
          'id'           : map['maMonAn'] ?? map['id'],
          'canteenId'    : map['maGianHang'] ?? map['canteenId'],
          'price'        : price,
          'description'  : map['moTa']?.toString() ?? map['description']?.toString() ?? '',
          'canteenName'  : _storeName,
        };
      }).toList();
    } catch (e) {
      debugPrint('MenuItems load error: $e');
      return [];
    }
  }

  /// Widget ngôi sao cho header gian hàng
  Widget _buildHeaderStars(double rating, int totalReviews) {
    final full = rating.floor();
    final half = (rating - full) >= 0.25 && (rating - full) < 0.75;
    final empty = 5 - full - (half ? 1 : 0);

    return Row(
      children: [
        ...List.generate(full, (_) => const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 16)),
        if (half) const Icon(Icons.star_half_rounded, color: Color(0xFFFFB800), size: 16),
        ...List.generate(empty, (_) => const Icon(Icons.star_border_rounded, color: Color(0xFFFFB800), size: 16)),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          '($totalReviews đánh giá)',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: itemsFuture,
        builder: (context, snapshot) {
          final allItems = snapshot.data ?? [];
          final query = _searchQuery.trim().toLowerCase();
          final items = query.isEmpty
              ? allItems
              : allItems.where((item) {
                  final name = item['name']?.toString().toLowerCase() ?? '';
                  return name.contains(query);
                }).toList();

          return CustomScrollView(
            slivers: [
              // ─────────────── HEADER: Banner + Info Gian Hàng ───────────────
              SliverAppBar(
                expandedHeight: media.height * 0.32,
                pinned: true,
                backgroundColor: TColor.primary,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh banner
                      AppImageView(
                        path: _storeBanner,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholderAsset: 'assets/img/app_logo.png',
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.15),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      // Nội dung info gian hàng (dưới cùng)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tên gian hàng
                              Text(
                                _storeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Rating sao
                              if (_storeRating != null && _storeRating! > 0)
                                _buildHeaderStars(_storeRating!, _storeTotalReviews)
                              else
                                Row(
                                  children: [
                                    ...List.generate(5, (_) => const Icon(Icons.star_border_rounded, color: Color(0xFFFFB800), size: 15)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Chưa có đánh giá',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              // Địa điểm + Giờ mở cửa
                              if (_storeLocation.isNotEmpty || _storeOpenHours.isNotEmpty)
                                Row(
                                  children: [
                                    if (_storeLocation.isNotEmpty) ...[
                                      const Icon(Icons.location_on_rounded,
                                          color: Colors.white70, size: 13),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          _storeLocation,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                    if (_storeLocation.isNotEmpty && _storeOpenHours.isNotEmpty)
                                      const Text('  ·  ',
                                          style: TextStyle(color: Colors.white54)),
                                    if (_storeOpenHours.isNotEmpty) ...[
                                      const Icon(Icons.access_time_rounded,
                                          color: Colors.white70, size: 13),
                                      const SizedBox(width: 3),
                                      Text(
                                        _storeOpenHours,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // AppBar khi thu nhỏ (pinned)
                title: Text(
                  _storeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Nút Back
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
                // Nút giỏ hàng
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MyOrderView()),
                            );
                            _loadCartCount();
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_cart_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        if (_cartCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              constraints:
                                  const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                _cartCount > 99 ? '99+' : '$_cartCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // ─────────────── THANH TÌM KIẾM ───────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: RoundTextfield(
                    hintText: 'Tìm món ăn...',
                    controller: txtSearch,
                    left: Container(
                      alignment: Alignment.center,
                      width: 30,
                      child: Image.asset(
                        'assets/img/search.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),

              // ─────────────── TIÊU ĐỀ SỐ MÓN ───────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        snapshot.connectionState == ConnectionState.waiting
                            ? 'Đang tải thực đơn...'
                            : query.isNotEmpty
                                ? 'Tìm thấy ${items.length} món'
                                : 'Thực đơn (${allItems.length} món)',
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─────────────── VOUCHER BANNER (nếu có) ───────────────
              if (widget.mObj['activeVoucherCode'] != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(children: [
                      const Icon(Icons.local_offer_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            widget.mObj['activeVoucherTitle']?.toString() ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dùng mã: ${widget.mObj['activeVoucherCode']} để giảm ${(widget.mObj['activeVoucherDiscount'] as num?)?.toInt() ?? 0}%',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${(widget.mObj['activeVoucherDiscount'] as num?)?.toInt() ?? 0}%',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

              // ─────────────── DANH SÁCH MÓN ĂN ───────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_outlined,
                            color: TColor.secondaryText, size: 64),
                        const SizedBox(height: 14),
                        Text(
                          allItems.isEmpty
                              ? 'Gian hàng chưa có món ăn nào.'
                              : 'Không tìm thấy món phù hợp.',
                          style:
                              TextStyle(color: TColor.secondaryText, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Divider nhẹ giữa các item
                      if (index.isOdd) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                          color: Colors.grey.shade200,
                        );
                      }
                      final itemIndex = index ~/ 2;
                      final mObj = items[itemIndex];
                      return Container(
                        color: Colors.white,
                        child: RecentItemRow(
                          rObj: mObj,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ItemDetailsView(dishObj: mObj),
                              ),
                            );
                            _loadCartCount();
                          },
                        ),
                      );
                    },
                    childCount: items.length * 2 - 1,
                  ),
                ),

              // Padding cuối
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
      ),
    );
  }
}
