import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common_widget/app_image_view.dart';
import '../../common_widget/review_card_widget.dart';
import '../customer/menu/all_reviews_view.dart';

class StaffItemDetailsView extends StatefulWidget {
  final Map<String, dynamic> dishObj;
  final VoidCallback? onEdit;

  const StaffItemDetailsView({super.key, required this.dishObj, this.onEdit});

  @override
  State<StaffItemDetailsView> createState() => _StaffItemDetailsViewState();
}

class _StaffItemDetailsViewState extends State<StaffItemDetailsView> {
  late Future<Map<String, dynamic>> dishFuture;
  late Future<List<Map<String, dynamic>>> reviewsFuture;

  int? get dishId {
    final rawId = widget.dishObj["maMonAn"] ?? widget.dishObj["id"];
    return int.tryParse(rawId?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    dishFuture = Future.value(widget.dishObj);
    final id = dishId;
    reviewsFuture = id != null ? _loadDishReviews(id) : Future.value([]);
  }

  Future<List<Map<String, dynamic>>> _loadDishReviews(int id) async {
    try {
      final res = await ServiceCall.fetchGet(
        '${SVKey.svReviewByDish(id)}?limit=3',
        isToken: false,
      );
      final data = res is Map ? res['data'] : res;
      return (data as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _dishName(Map<String, dynamic> dish) =>
      dish["tenMonAn"]?.toString() ?? dish["name"]?.toString() ?? "";
  String _dishDescription(Map<String, dynamic> dish) =>
      dish["moTa"]?.toString() ?? dish["description"]?.toString() ?? "";
  String _dishImage(Map<String, dynamic> dish) =>
      dish["hinhAnh"]?.toString() ?? dish["imageUrl"]?.toString() ?? "";
  String _categoryName(Map<String, dynamic> dish) =>
      dish["tenDanhMuc"]?.toString() ?? dish["categoryName"]?.toString() ?? "Khác";

  double _price(Map<String, dynamic> dish) {
    final rawPrice = dish["giaTien"] ?? dish["price"];
    if (rawPrice is num) return rawPrice.toDouble();
    return double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
  }

  String _formatPrice(double v) {
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: dishFuture,
      builder: (context, snapshot) {
        final dish = snapshot.data ?? widget.dishObj;
        final price = _price(dish);
        final isAvail = dish['trangThai'] != 0 && dish['isAvailable'] != false;
        final isDeleted = dish['daXoa'] == 1; // Ngừng bán
        final stock = dish['soLuongTon'] ?? 0;

        return Scaffold(
          backgroundColor: TColor.white,
          body: Stack(
            alignment: Alignment.topCenter,
            children: [
              AppImageView(
                path: _dishImage(dish),
                width: media.width,
                height: media.width,
                fit: BoxFit.cover,
                placeholderAsset: "assets/img/app_logo.png",
              ),
              Container(
                width: media.width,
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: media.width - 60),
                          Container(
                            decoration: BoxDecoration(
                              color: TColor.white,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 35),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Text(
                                    _dishName(dish),
                                    style: TextStyle(
                                      color: TColor.primaryText,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _categoryName(dish),
                                            style: TextStyle(
                                              color: TColor.secondaryText,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          // Status + Stock
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isDeleted
                                                      ? Colors.orange
                                                      : (isAvail ? Colors.green : Colors.grey),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isDeleted
                                                    ? 'Đang ngừng bán'
                                                    : (isAvail ? 'Còn hàng' : 'Hết món'),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDeleted
                                                      ? Colors.orange.shade700
                                                      : (isAvail ? Colors.green : Colors.grey),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Icon(Icons.inventory_2_outlined,
                                                  size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Tồn kho: $stock',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatPrice(price),
                                        style: TextStyle(
                                          color: TColor.primary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 25),
                                
                                // Description
                                if (_dishDescription(dish).isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25),
                                    child: Text(
                                      "Mô tả sản phẩm",
                                      style: TextStyle(
                                        color: TColor.primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25),
                                    child: Text(
                                      _dishDescription(dish),
                                      style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                ],

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Divider(
                                    color: TColor.secondaryText.withAlpha(80),
                                    height: 1,
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(height: 25),

                                // Actions
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 50,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: TColor.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15),
                                              ),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                                            label: const Text(
                                              "Chỉnh sửa thông tin",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            onPressed: () {
                                              if (widget.onEdit != null) {
                                                widget.onEdit!();
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Reviews section
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: reviewsFuture,
                                  builder: (context, revSnap) {
                                    final reviews = revSnap.data ?? [];
                                    final resolvedDishId = int.tryParse(
                                        (dish['maMonAn'] ?? dish['id'] ?? dish['dishId'])?.toString() ?? '');
                                    final rating = dish['diemDanhGia'] ?? dish['rate'];
                                    final ratingVal = rating is num
                                        ? rating.toDouble()
                                        : double.tryParse(rating?.toString() ?? '') ?? 0.0;
                                    final luot = (dish['luotDanhGia'] ?? 0) is num
                                        ? (dish['luotDanhGia'] ?? 0) as num
                                        : num.tryParse(dish['luotDanhGia']?.toString() ?? '') ?? 0;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          color: TColor.textfield,
                                          height: 10,
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 25),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Đánh giá từ khách hàng",
                                                style: TextStyle(
                                                  color: TColor.primaryText,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              if (resolvedDishId != null && reviews.isNotEmpty)
                                                GestureDetector(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => AllReviewsView(
                                                        dishId: resolvedDishId,
                                                        dishName: _dishName(dish),
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Xem tất cả',
                                                    style: TextStyle(
                                                      color: TColor.primary,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                          decoration: BoxDecoration(
                                            color: TColor.primary.withAlpha(20),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                ratingVal.toStringAsFixed(1),
                                                style: TextStyle(
                                                  color: TColor.primary,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    RatingBar.builder(
                                                      initialRating: ratingVal,
                                                      minRating: 1,
                                                      direction: Axis.horizontal,
                                                      allowHalfRating: true,
                                                      ignoreGestures: true,
                                                      itemCount: 5,
                                                      itemSize: 18,
                                                      unratedColor: Colors.grey.shade300,
                                                      itemBuilder: (context, _) => Icon(
                                                        Icons.star_rounded,
                                                        color: const Color(0xFFFFC107),
                                                      ),
                                                      onRatingUpdate: (_) {},
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Số lượt đánh giá: $luot',
                                                      style: TextStyle(
                                                        color: TColor.primaryText,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (reviews.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            child: Text(
                                              'Chưa có bài đánh giá nào.',
                                              style: TextStyle(
                                                color: TColor.secondaryText,
                                                fontSize: 14,
                                              ),
                                            ),
                                          )
                                        else
                                          ...reviews.map((rev) => ReviewCard(review: rev, compact: true)),
                                        const SizedBox(height: 40),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
