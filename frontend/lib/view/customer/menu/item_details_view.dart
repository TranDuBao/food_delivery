import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:food_delivery/common_widget/round_icon_button.dart';

import '../../../common/app_alert.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/app_image_view.dart';
import '../../../common_widget/review_card_widget.dart';
import '../more/my_order_view.dart';
import 'all_reviews_view.dart';

class ItemDetailsView extends StatefulWidget {
  final Map? dishObj;
  const ItemDetailsView({super.key, this.dishObj});

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  double price = 15;
  int qty = 1;
  bool isFav = false;
  bool isAdding = false;
  int _cartCount = 0;
  late Future<Map<String, dynamic>> dishFuture;
  late Future<List<Map<String, dynamic>>> reviewsFuture;

  int? get dishId {
    final rawId = widget.dishObj?["dishId"] ?? widget.dishObj?["id"];
    return int.tryParse(rawId?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    final rawPrice = widget.dishObj?["price"] ?? widget.dishObj?["rate"];
    if (rawPrice is num) {
      price = rawPrice.toDouble();
    } else if (rawPrice != null) {
      price = double.tryParse(rawPrice.toString()) ?? price;
    }

    dishFuture = _loadDishDetail();
    _loadCartCount();
    final id = int.tryParse(
        (widget.dishObj?['dishId'] ?? widget.dishObj?['id'])?.toString() ?? '');
    reviewsFuture = id != null ? _loadDishReviews(id) : Future.value([]);
  }

  Future<List<Map<String, dynamic>>> _loadDishReviews(int id) async {
    try {
      final res = await ServiceCall.fetchGet(
        '${SVKey.svReviewByDish(id)}?limit=2',
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

  Future<Map<String, dynamic>> _loadDishDetail() async {
    final id = dishId;
    if (id == null) {
      return Map<String, dynamic>.from(widget.dishObj ?? {});
    }

    try {
      final response = await ServiceCall.fetchGet(
        '${SVKey.svCanteenDishes}/$id',
        isToken: true,
      );
      final rawData = response is Map ? (response['data'] ?? response) : null;
      if (rawData is Map) {
        final detail = Map<String, dynamic>.from(rawData);
        // Map SQL fields to frontend fields
        detail['name'] ??= detail['tenMonAn'];
        detail['imageUrl'] ??= detail['hinhAnh'];
        detail['description'] ??= detail['moTa'];
        final rawPrice = detail['giaTien'] ?? detail['price'];
        if (rawPrice is num) {
          price = rawPrice.toDouble();
        } else if (rawPrice != null) {
          price = double.tryParse(rawPrice.toString()) ?? price;
        }
        return detail;
      }
    } catch (e) {
      debugPrint('Load dish detail error: $e');
    }

    return Map<String, dynamic>.from(widget.dishObj ?? {});
  }

  String _dishName(Map<String, dynamic> dish) =>
      dish["name"]?.toString() ?? dish["tenMonAn"]?.toString() ?? "";
  String _dishDescription(Map<String, dynamic> dish) =>
      dish["description"]?.toString() ?? dish["moTa"]?.toString() ?? "";
  String _dishImage(Map<String, dynamic> dish) =>
      dish["imageUrl"]?.toString() ?? dish["hinhAnh"]?.toString() ?? "";

  Future<void> _addToCart(Map<String, dynamic> dish) async {
    final rawId = dish['maMonAn'] ?? dish['id'] ?? dish['dishId'] ?? dishId;
    final resolvedDishId = int.tryParse(rawId?.toString() ?? '');

    if (resolvedDishId == null || resolvedDishId <= 0) {
      if (!mounted) return;
      AppAlert.show(context, message: 'Không xác định được món để thêm vào giỏ', type: 'error');
      return;
    }

    if (isAdding) return;

    setState(() => isAdding = true);

    try {
      await ServiceCall.fetchPost(
        SVKey.svCartAdd,
        isToken: true,
        body: {'maMonAn': resolvedDishId, 'soLuong': qty},
      );

      if (!mounted) return;

      AppAlert.show(context, message: 'Đã thêm ${_dishName(dish)} (x$qty) vào giỏ hàng!');
      // Cập nhật badge
      await _loadCartCount();
    } catch (error) {
      if (!mounted) return;
      AppAlert.show(context, message: error.toString(), type: 'error');
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return FutureBuilder<Map<String, dynamic>>(
      future: dishFuture,
      builder: (context, snapshot) {
        final dish = snapshot.data ?? Map<String, dynamic>.from(widget.dishObj ?? {});

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
                height: media.width,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.transparent, Colors.black],
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
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Builder(builder: (_) {
                                        final rating = (dish['diemDanhGia'] ?? dish['rate']);
                                        final ratingVal = rating is num ? rating.toDouble() : double.tryParse(rating?.toString() ?? '') ?? 0.0;
                                        final luot = (dish['luotDanhGia'] ?? dish['rating'])?.toString() ?? '0';
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            IgnorePointer(
                                              ignoring: true,
                                              child: RatingBar.builder(
                                                initialRating: ratingVal,
                                                minRating: 1,
                                                direction: Axis.horizontal,
                                                allowHalfRating: true,
                                                itemCount: 5,
                                                itemSize: 20,
                                                itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
                                                itemBuilder: (context, _) => Icon(
                                                  Icons.star,
                                                  color: TColor.primary,
                                                ),
                                                onRatingUpdate: (_) {},
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ' ${ratingVal.toStringAsFixed(1)} ($luot Đánh giá)',
                                              style: TextStyle(
                                                color: TColor.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${price.toStringAsFixed(0)} VNĐ",
                                            style: TextStyle(
                                              color: TColor.primaryText,
                                              fontSize: 31,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                if (_dishDescription(dish).isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25),
                                    child: Text(
                                      "Mô tả",
                                      style: TextStyle(
                                        color: TColor.primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25),
                                    child: Text(
                                      _dishDescription(dish),
                                      style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 25),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Number of Portions",
                                        style: TextStyle(
                                          color: TColor.primaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          qty = qty - 1;
                                          if (qty < 1) {
                                            qty = 1;
                                          }
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          height: 25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: TColor.primary,
                                            borderRadius: BorderRadius.circular(12.5),
                                          ),
                                          child: Text(
                                            "-",
                                            style: TextStyle(
                                              color: TColor.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        height: 25,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: TColor.primary),
                                          borderRadius: BorderRadius.circular(12.5),
                                        ),
                                        child: Text(
                                          qty.toString(),
                                          style: TextStyle(
                                            color: TColor.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          qty = qty + 1;
                                          setState(() {});
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          height: 25,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: TColor.primary,
                                            borderRadius: BorderRadius.circular(12.5),
                                          ),
                                          child: Text(
                                            "+",
                                            style: TextStyle(
                                              color: TColor.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 220,
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      Container(
                                        width: media.width * 0.25,
                                        height: 160,
                                        decoration: BoxDecoration(
                                          color: TColor.primary,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(35),
                                            bottomRight: Radius.circular(35),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Stack(
                                          alignment: Alignment.centerRight,
                                          children: [
                                            Container(
                                              margin: const EdgeInsets.only(
                                                top: 8,
                                                bottom: 8,
                                                left: 10,
                                                right: 20,
                                              ),
                                              width: media.width - 80,
                                              height: 120,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(35),
                                                  bottomLeft: Radius.circular(35),
                                                  topRight: Radius.circular(10),
                                                  bottomRight: Radius.circular(10),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4),
                                                  )
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Total Price",
                                                    style: TextStyle(
                                                      color: TColor.primaryText,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Text(
                                                    "${(price * qty).toStringAsFixed(0)} VNĐ",
                                                    style: TextStyle(
                                                      color: TColor.primaryText,
                                                      fontSize: 21,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  SizedBox(
                                                    width: 130,
                                                    height: 25,
                                                    child: RoundIconButton(
                                                      title: isAdding ? "Adding..." : "Add to Cart",
                                                      icon: "assets/img/shopping_add.png",
                                                      color: TColor.primary,
                                                      onPressed: () => _addToCart(dish),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const MyOrderView(),
                                                  ),
                                                );
                                                _loadCartCount();
                                              },
                                              child: Stack(
                                                clipBehavior: Clip.none,
                                                children: [
                                                  Container(
                                                    width: 45,
                                                    height: 45,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(22.5),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.black12,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        )
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Image.asset(
                                                      "assets/img/shopping_cart.png",
                                                      width: 20,
                                                      height: 20,
                                                      color: TColor.primary,
                                                    ),
                                                  ),
                                                  if (_cartCount > 0)
                                                    Positioned(
                                                      right: -2,
                                                      top: -2,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.orange,
                                                          shape: BoxShape.circle,
                                                          border: Border.all(color: Colors.white, width: 1.5),
                                                        ),
                                                        constraints: const BoxConstraints(
                                                            minWidth: 20, minHeight: 20),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          _cartCount > 99 ? '99+' : '$_cartCount',
                                                          style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                              height: 1.0),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ── Đánh giá section (sau Add to Cart) ──────────
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
                                        Divider(
                                          color: Colors.grey.shade200,
                                          height: 1,
                                          thickness: 1,
                                        ),
                                        const SizedBox(height: 14),
                                        // Header
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: TColor.primary.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                ratingVal.toStringAsFixed(1),
                                                style: TextStyle(
                                                  color: TColor.primary,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: List.generate(5, (i) => Icon(
                                                        i < ratingVal.round()
                                                            ? Icons.star_rounded
                                                            : Icons.star_outline_rounded,
                                                        size: 16,
                                                        color: i < ratingVal.round()
                                                            ? const Color(0xFFFFC107)
                                                            : Colors.grey.shade300,
                                                      )),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Đánh giá sản phẩm ($luot)',
                                                      style: TextStyle(
                                                        color: TColor.primaryText,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (resolvedDishId != null)
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
                                        const SizedBox(height: 10),
                                        // Danh sách đánh giá
                                        if (reviews.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            child: Text(
                                              'Chưa có đánh giá nào.',
                                              style: TextStyle(
                                                color: TColor.secondaryText,
                                                fontSize: 13,
                                              ),
                                            ),
                                          )
                                        else
                                          ...reviews.map((rev) => ReviewCard(review: rev, compact: true)),
                                        const SizedBox(height: 20),
                                      ],
                                    );
                                  },
                                ),
                                // ─────────────────────────────────────────────
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                      Container(
                        height: media.width - 20,
                        alignment: Alignment.bottomRight,
                        margin: const EdgeInsets.only(right: 4),
                        child: InkWell(
                          onTap: () {
                            isFav = !isFav;
                            setState(() {});
                          },
                          child: Image.asset(
                            isFav
                                ? "assets/img/favorites_btn.png"
                                : "assets/img/favorites_btn_2.png",
                            width: 70,
                            height: 70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 35),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Image.asset(
                              "assets/img/btn_back.png",
                              width: 20,
                              height: 20,
                              color: TColor.white,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
