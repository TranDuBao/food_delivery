import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/app_image_view.dart';

import 'dine_in_checkout_view.dart';

/// Màn hình thực đơn quán — hiển thị khi khách quét mã QR.
/// Được mở từ deep link: shipfood://canteen/{canteenId}
class DineInMenuView extends StatefulWidget {
  final int canteenId;
  const DineInMenuView({super.key, required this.canteenId});

  @override
  State<DineInMenuView> createState() => _DineInMenuViewState();
}

class _DineInMenuViewState extends State<DineInMenuView> {
  bool _isLoading = true;
  Map<String, dynamic> _canteen = {};
  List<Map<String, dynamic>> _dishes = [];
  String? _error;

  // Giỏ hàng tạm (maMonAn → {dish, qty})
  final Map<int, Map<String, dynamic>> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await ServiceCall.fetchGet(
        SVKey.svDineInMenu(widget.canteenId),
        isToken: false,
      );
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map;
        setState(() {
          _canteen = Map<String, dynamic>.from(data['canteen'] as Map? ?? {});
          _dishes = (data['dishes'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        setState(() => _error = 'Không tải được thực đơn.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Gộp món theo danh mục
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final d in _dishes) {
      final cat = d['tenDanhMuc']?.toString() ?? 'Khác';
      result.putIfAbsent(cat, () => []).add(d);
    }
    return result;
  }

  int get _totalQty => _cart.values.fold(0, (s, v) => s + (v['qty'] as int));
  double get _totalPrice => _cart.values.fold(
      0, (s, v) => s + (v['qty'] as int) * _toDouble(v['dish']['giaTien']));

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  void _addQty(Map<String, dynamic> dish) {
    final id = dish['maMonAn'] as int;
    setState(() {
      if (_cart.containsKey(id)) {
        _cart[id]!['qty'] = (_cart[id]!['qty'] as int) + 1;
      } else {
        _cart[id] = {'dish': dish, 'qty': 1};
      }
    });
  }

  void _removeQty(Map<String, dynamic> dish) {
    final id = dish['maMonAn'] as int;
    if (!_cart.containsKey(id)) return;
    setState(() {
      final cur = _cart[id]!['qty'] as int;
      if (cur <= 1) {
        _cart.remove(id);
      } else {
        _cart[id]!['qty'] = cur - 1;
      }
    });
  }

  int _qtyOf(Map<String, dynamic> dish) =>
      (_cart[dish['maMonAn'] as int]?['qty'] as int?) ?? 0;

  void _goCheckout() {
    if (_cart.isEmpty) return;
    final items = _cart.values.map((v) => {
      'maMonAn': (v['dish']['maMonAn'] as int),
      'tenMonAn': v['dish']['tenMonAn']?.toString() ?? '',
      'soLuong': v['qty'] as int,
      'giaTien': _toDouble(v['dish']['giaTien']),
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DineInCheckoutView(
          maGianHang: widget.canteenId,
          tenGianHang: _canteen['tenGianHang']?.toString() ?? '',
          items: items,
          tongTien: _totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
      bottomNavigationBar: _totalQty > 0 ? _buildCartBar() : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadMenu,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final grouped = _grouped;
    final categories = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        // ── App bar với banner quán ────────────────────────────────────
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: TColor.primary,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (_canteen['banner'] != null && (_canteen['banner'] as String).isNotEmpty)
                  AppImageView(
                    path: _canteen['banner'].toString(),
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [TColor.primary, TColor.primary.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Icon(Icons.restaurant_rounded, size: 80, color: Colors.white30),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black54],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Đang mở cửa',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                const Text('Gọi món tại bàn', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _canteen['tenGianHang']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_canteen['gioMoCua'] != null)
                        Text(
                          '🕐 ${_canteen['gioMoCua']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          leading: IconButton(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // ── Danh sách món theo danh mục ────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final cat = categories[i];
                final dishes = grouped[cat]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i > 0) const SizedBox(height: 16),
                    // Tiêu đề danh mục
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        cat,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    // Các món trong danh mục
                    ...dishes.map((dish) => _buildDishCard(dish)),
                  ],
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dish) {
    final qty = _qtyOf(dish);
    final price = _toDouble(dish['giaTien']);
    final name = dish['tenMonAn']?.toString() ?? '';
    final desc = dish['moTa']?.toString() ?? '';
    final img = dish['hinhAnh']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh món
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppImageView(
              path: img,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              placeholderAsset: 'assets/img/app_logo.png',
            ),
          ),
          const SizedBox(width: 12),
          // Tên + mô tả + giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1A1A)),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${price.toStringAsFixed(0)}đ',
                      style: TextStyle(
                        color: TColor.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    // Nút tăng giảm số lượng
                    if (qty == 0)
                      GestureDetector(
                        onTap: () => _addQty(dish),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: TColor.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Thêm',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          _circleBtn(Icons.remove_rounded, () => _removeQty(dish)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '$qty',
                              style: TextStyle(
                                color: TColor.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _circleBtn(Icons.add_rounded, () => _addQty(dish)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: TColor.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: TColor.primary),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _goCheckout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: TColor.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalQty',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Xem đơn & Thanh toán',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Text(
                '${_totalPrice.toStringAsFixed(0)}đ',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
