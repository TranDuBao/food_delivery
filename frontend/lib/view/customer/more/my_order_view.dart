import 'package:flutter/material.dart';

import '../../../common/app_alert.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/app_image_view.dart';
import '../../../common_widget/round_button.dart';
import '../menu/all_reviews_view.dart';
import '../menu/item_details_view.dart';
import 'area_orders_view.dart';
import 'checkout_view.dart';
import 'review_order_view.dart';

// ─────────────────────────────────────────────
// MÀN HÌNH GIỎ HÀNG
// ─────────────────────────────────────────────
class MyOrderView extends StatefulWidget {
  const MyOrderView({super.key});

  @override
  State<MyOrderView> createState() => _MyOrderViewState();
}

class _MyOrderViewState extends State<MyOrderView> {
  late Future<Map<String, dynamic>> cartFuture;
  bool isRemoving = false;

  @override
  void initState() {
    super.initState();
    cartFuture = _loadCart();
  }

  Future<Map<String, dynamic>> _loadCart() async {
    try {
      final response =
          await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (response is Map<String, dynamic> && response['success'] == true) {
        final items = response['data'] as List? ?? [];
        final tongTien = response['tongTien'] ?? 0;

        final mappedItems = items.whereType<Map>().map((item) {
          final gia =
              double.tryParse(item['giaTien']?.toString() ?? '0') ?? 0;
          final sl = (item['soLuong'] as num?)?.toInt() ?? 1;
          return <String, dynamic>{
            'dishId': item['maMonAn'],
            'dishName': item['tenMonAn'] ?? 'Món ăn',
            'quantity': sl,
            'lineTotal': gia * sl,
            'canteenName': item['tenGianHang'] ?? '',
            'imageUrl': item['hinhAnh'] ?? item['imageUrl'] ?? '',
          };
        }).toList();

        return {'items': mappedItems, 'totalAmount': tongTien};
      }
    } catch (e) {
      debugPrint('Load cart error: $e');
    }
    return {'items': [], 'totalAmount': 0};
  }

  List<Map<String, dynamic>> _cartItems(Map<String, dynamic> cart) {
    final items = cart['items'] as List? ?? [];
    return items
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> _refresh() async {
    final newFuture = _loadCart();
    setState(() { cartFuture = newFuture; });  // block {} → return void, not Future
    await newFuture;
  }

  Future<void> _removeItem(dynamic dishId) async {
    final parsedId = int.tryParse(dishId?.toString() ?? '');
    if (parsedId == null || parsedId <= 0 || isRemoving) return;

    setState(() => isRemoving = true);
    try {
      await ServiceCall.fetchDelete(SVKey.svCartRemove(parsedId),
          isToken: true);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      AppAlert.show(context, message: error.toString(), type: 'error');
    } finally {
      if (mounted) setState(() => isRemoving = false);
    }
  }

  Future<void> _updateQuantity(dynamic dishId, int newQty) async {
    final parsedId = int.tryParse(dishId?.toString() ?? '');
    if (parsedId == null || parsedId <= 0 || isRemoving) return;

    setState(() => isRemoving = true);
    try {
      await ServiceCall.fetchPut(SVKey.svCartUpdate,
          isToken: true,
          body: {'maMonAn': parsedId, 'soLuong': newQty});
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      AppAlert.show(context, message: error.toString(), type: 'error');
    } finally {
      if (mounted) setState(() => isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: cartFuture,
          builder: (context, snapshot) {
            final cart = snapshot.data ?? <String, dynamic>{};
            final items = _cartItems(cart);
            final totalAmount = _toDouble(cart['totalAmount']);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Header =====
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pushNamedAndRemoveUntil(
                                    context, 'Home', (_) => false),
                            icon: Image.asset('assets/img/btn_back.png',
                                width: 20, height: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Giỏ hàng',
                              style: TextStyle(
                                color: TColor.primaryText,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),



                      const SizedBox(height: 20),

                      // ===== Danh sách món =====
                      Text(
                        'Các món đã thêm vào giỏ của bạn.',
                        style: TextStyle(
                            color: TColor.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 18),

                      if (snapshot.connectionState ==
                          ConnectionState.waiting)
                        const Center(
                            child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator()))
                      else if (items.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 36),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart_outlined,
                                  color: TColor.secondaryText, size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Giỏ hàng đang trống.',
                                style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thêm món ăn rồi quay lại đây để thanh toán.',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: TColor.secondaryText),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailsView(
                                      dishObj: {'dishId': item['dishId']},
                                    ),
                                  ),
                                );
                                _refresh();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TColor.textfield,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: AppImageView(
                                        path: item['imageUrl']?.toString() ?? '',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        placeholderAsset: 'assets/img/app_logo.png',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['dishName']?.toString() ?? '',
                                                      style: TextStyle(
                                                          color: TColor.primaryText,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item['canteenName']?.toString() ?? '',
                                                      style: TextStyle(
                                                          color: TColor.secondaryText,
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: isRemoving ? null : () => _removeItem(item['dishId']),
                                                child: Padding(
                                                  padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                                                  child: Icon(Icons.delete_outline_rounded,
                                                      color: Colors.red.shade300, size: 22),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Text(
                                                '${_toDouble(item['lineTotal']).toStringAsFixed(0)} đ',
                                                style: TextStyle(
                                                    color: TColor.primaryText,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700),
                                              ),
                                              const Spacer(),
                                              Container(
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    InkWell(
                                                      onTap: isRemoving ? null : () {
                                                        final qty = item['quantity'] ?? 1;
                                                        if (qty > 1) {
                                                          _updateQuantity(item['dishId'], qty - 1);
                                                        } else {
                                                          _removeItem(item['dishId']);
                                                        }
                                                      },
                                                      child: Container(
                                                        width: 28,
                                                        alignment: Alignment.center,
                                                        child: Icon(Icons.remove, color: TColor.primary, size: 16),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 28,
                                                      alignment: Alignment.center,
                                                      child: Text('${item['quantity'] ?? 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ),
                                                    InkWell(
                                                      onTap: isRemoving ? null : () {
                                                        final qty = item['quantity'] ?? 1;
                                                        _updateQuantity(item['dishId'], qty + 1);
                                                      },
                                                      child: Container(
                                                        width: 28,
                                                        alignment: Alignment.center,
                                                        child: Icon(Icons.add, color: TColor.primary, size: 16),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                          },
                        ),

                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tổng tiền',
                                style: TextStyle(
                                    color: TColor.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              '${totalAmount.toStringAsFixed(0)} đ',
                              style: TextStyle(
                                  color: TColor.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        RoundButton(
                          title: 'Tiến hành đặt hàng',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CheckoutView()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


// MÀN HÌNH LỊCH SỬ ĐƠN HÀNG (có filter tabs)
// ─────────────────────────────────────────────
class OrderHistoryView extends StatefulWidget {
  final String? initialFilter;
  final bool isPushed;
  const OrderHistoryView({super.key, this.initialFilter, this.isPushed = false});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> ordersFuture;

  final List<_TabDef> _tabs = const [
    _TabDef('Tất cả', null),
    _TabDef('Đang ghép', 'choGhepDon'),
    _TabDef('Chờ giao', 'choGiaoHang'),
    _TabDef('Đã giao', 'daGiao'),
    _TabDef('Đã hủy', 'daHuy'),
  ];

  @override
  void initState() {
    super.initState();
    // Xác định tab ban đầu dựa trên initialFilter, mặc định là 0 (Tất cả)
    int initialIndex = 0;
    if (widget.initialFilter != null) {
      final idx =
          _tabs.indexWhere((t) => t.status == widget.initialFilter);
      if (idx >= 0) initialIndex = idx;
    }
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
    ordersFuture = _loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadMyOrders() async {
    try {
      final response =
          await ServiceCall.fetchGet(SVKey.svOrderMy, isToken: true);
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Load orders error: $e');
    }
    return [];
  }

  Future<void> _refresh() async {
    setState(() { ordersFuture = _loadMyOrders(); });  // block → void
    await ordersFuture;
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'choGhepDon':
        return 'Đang ghép đơn';
      case 'dangChuanBi':
        return 'Đang chuẩn bị';
      case 'choGiaoHang':
        return 'Chờ giao hàng';
      case 'dangGiao':
        return 'Đang giao';
      case 'daGiao':
        return 'Đã giao';
      case 'daHuy':
        return 'Đã hủy';
      default:
        return s ?? '';
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'choGhepDon':
        return const Color(0xFFFF7043);
      case 'dangChuanBi':
        return Colors.blue;
      case 'choGiaoHang':
        return Colors.teal;
      case 'dangGiao':
        return Colors.green;
      case 'daGiao':
        return Colors.green.shade800;
      case 'daHuy':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelOrder(dynamic orderId) async {
    final id = int.tryParse(orderId?.toString() ?? '');
    if (id == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ServiceCall.fetchPost(
        SVKey.svOrderMyCancel(id),
        isToken: true,
        body: {'reason': 'CUSTOMER_CANCELLED'},
      );
      if (!mounted) return;
      AppAlert.show(context, message: 'Đã hủy đơn hàng thành công.');
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      AppAlert.show(context, message: e.toString(), type: 'error');
    }
  }

  Future<void> _refundOrder(dynamic orderId) async {
    final id = int.tryParse(orderId?.toString() ?? '');
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yêu cầu hoàn tiền', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Bạn có chắc muốn hủy đơn và hoàn tiền không? Tiền sẽ được hoàn trả vào tài khoản thanh toán của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: TColor.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hoàn tiền'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      Globs.showHUD();
      final res = await ServiceCall.fetchPost(
        SVKey.svPaymentRefund,
        isToken: true,
        body: {'maDonHang': id},
      );
      Globs.hideHUD();
      
      if (res is Map && res['success'] == true) {
        if (!mounted) return;
        AppAlert.show(context, message: res['message']?.toString() ?? 'Đã gửi yêu cầu hoàn tiền.');
        await _refresh();
      }
    } catch (e) {
      Globs.hideHUD();
      if (!mounted) return;
      AppAlert.show(context, message: e.toString(), type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.isPushed) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, 'Home', (_) => false);
                      }
                    },
                    icon: Image.asset('assets/img/btn_back.png',
                        width: 20, height: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Lịch sử đơn hàng',
                      style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: Icon(Icons.refresh_rounded, color: TColor.primary),
                  ),
                ],
              ),
            ),


            // ── Tab Bar ──
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: TColor.primary,
                indicatorWeight: 3,
                labelColor: TColor.primary,
                unselectedLabelColor: TColor.secondaryText,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: _tabs
                    .map((t) => Tab(text: t.label))
                    .toList(),
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allOrders = snapshot.data ?? [];

                  return TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final orders = tab.status == null
                          ? allOrders
                          : allOrders
                              .where((o) =>
                                  o['trangThaiDonHang']?.toString() ==
                                  tab.status)
                              .toList();

                      return _OrderList(
                        orders: orders,
                        statusLabel: _statusLabel,
                        statusColor: _statusColor,
                        onCancel: _cancelOrder,
                        onRefund: _refundOrder,
                        onRefresh: _refresh,
                        onReview: (orderId, danhSachMon) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewOrderView(
                                maDonHang: orderId,
                                danhSachMon: danhSachMon,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final String? status;
  const _TabDef(this.label, this.status);
}

// ─────────────────────────────────────────────
// WIDGET: Danh sách đơn hàng
// ─────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final Future<void> Function(dynamic) onCancel;
  final Future<void> Function(dynamic) onRefund;
  final Future<void> Function() onRefresh;
  final void Function(dynamic orderId, String? danhSachMon) onReview;

  const _OrderList({
    required this.orders,
    required this.statusLabel,
    required this.statusColor,
    required this.onCancel,
    required this.onRefund,
    required this.onRefresh,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                color: Colors.grey.shade300, size: 72),
            const SizedBox(height: 14),
            const Text(
              'Chưa có đơn hàng nào.',
              style:
                  TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final order = orders[index];
          final status = order['trangThaiDonHang']?.toString();
          final maDon = order['maDonHang'];
          final sColor = statusColor(status);

          Widget orderCard = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─ Status bar top ─
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.08),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status),
                          color: sColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel(status),
                        style: TextStyle(
                            color: sColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '#${maDon ?? ''}',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // ─ Content ─
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order['hinhAnhDauTien'] != null && order['hinhAnhDauTien'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppImageView(
                                  path: order['hinhAnhDauTien'].toString(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholderAsset: 'assets/img/app_logo.png',
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Địa chỉ
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: TColor.primary, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${order['tenToaNha'] ?? ''} · P.${order['tenPhong'] ?? ''}',
                                        style: TextStyle(
                                            color: TColor.primaryText,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Món ăn
                                Text(
                                  order['danhSachMon']?.toString() ?? '',
                                  style: TextStyle(
                                      color: TColor.secondaryText,
                                      fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tổng tiền
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${double.tryParse(order['tongTien']?.toString() ?? '0')?.toStringAsFixed(0)} đ',
                            style: TextStyle(
                                color: TColor.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800),
                          ),
                          if (status == 'choGhepDon')
                            Builder(builder: (context) {
                              final isPaid = order['trangThaiThanhToan'] == 'paid';
                              return TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  backgroundColor:
                                      (isPaid ? TColor.primary : Colors.red).withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                ),
                                onPressed: () => isPaid ? onRefund(maDon) : onCancel(maDon),
                                child: Text(
                                  isPaid ? 'Hoàn tiền' : 'Hủy đơn',
                                  style: TextStyle(
                                      color: isPaid ? TColor.primary : Colors.red.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              );
                            }),
                          if (status == 'daGiao') ...[  
                            Builder(builder: (_) {
                              final tongMon = (order['tongMon'] as num?)?.toInt() ?? 0;
                              final soMonDaDanhGia = (order['soMonDaDanhGia'] as num?)?.toInt() ?? 0;
                              final daDanhGia = tongMon > 0 && soMonDaDanhGia >= tongMon;
                              if (daDanhGia) {
                                // Đã đánh giá → xem đánh giá tại AllReviewsView
                                final maMonAn = (order['maMonAnDauTien'] as num?)?.toInt();
                                final tenMon = order['tenMonAnDauTien']?.toString()
                                    ?? order['danhSachMon']?.toString()
                                    ?? 'Món ăn';
                                return GestureDetector(
                                  onTap: () {
                                    if (maMonAn != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AllReviewsView(
                                            dishId: maMonAn,
                                            dishName: tenMon,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.grey.shade400,
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Xem đánh giá',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return _ReviewButton(
                                onTap: () => onReview(
                                  maDon,
                                  order['danhSachMon']?.toString(),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (status == 'choGhepDon') {
            return GestureDetector(
              onTap: () {
                final maToaNha = int.tryParse(order['maToaNha']?.toString() ?? '');
                if (maToaNha != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AreaOrdersView(
                        toaNha: maToaNha,
                        tenToaNha: order['tenToaNha']?.toString() ?? '',
                      ),
                    ),
                  );
                }
              },
              child: orderCard,
            );
          }
          
          return orderCard;
        },
      ),
    );
  }

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'choGhepDon':
        return Icons.access_time_rounded;
      case 'dangChuanBi':
        return Icons.restaurant_rounded;
      case 'choGiaoHang':
        return Icons.local_shipping_outlined;
      case 'dangGiao':
        return Icons.delivery_dining_rounded;
      case 'daGiao':
        return Icons.check_circle_rounded;
      case 'daHuy':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

// ─────────────────────────────────────────────
// WIDGET: Nút Đánh giá kiểu Shopee
// ─────────────────────────────────────────────
class _ReviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEE4D2D), Color(0xFFFF6B4A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEE4D2D).withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Đánh giá',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET: Danh sách đơn hàng trong khu vực (Dùng cho tab Khu vực)
// ─────────────────────────────────────────────
class AreaOrderListWidget extends StatefulWidget {
  final int toaNha;
  final String tenToaNha;

  const AreaOrderListWidget({super.key, required this.toaNha, required this.tenToaNha});

  @override
  State<AreaOrderListWidget> createState() => _AreaOrderListWidgetState();
}

class _AreaOrderListWidgetState extends State<AreaOrderListWidget> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (widget.toaNha <= 0) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderAreaOrders,
        queryParameters: {'maToaNha': widget.toaNha},
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            orders = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'choGhepDon':   return '⏳ Chờ ghép đơn';
      case 'choXacNhan':   return '🤝 Đang ghép...';
      case 'dangChuanBi':  return '👨‍🍳 Đang chuẩn bị';
      case 'choGiaoHang':  return '✅ Sẵn sàng giao';
      default:             return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'choGhepDon':   return Colors.orange;
      case 'choXacNhan':   return Colors.indigo;
      case 'dangChuanBi':  return Colors.blue;
      default:             return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    
    if (widget.toaNha <= 0 || orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, color: Colors.grey.shade300, size: 64),
            const SizedBox(height: 12),
            Text(
              orders.isEmpty ? 'Chưa có đơn nào trong khu vực.' : 'Bạn chưa có đơn hàng nào để xác định khu vực.',
              style: TextStyle(color: TColor.secondaryText, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          final status = order['trangThaiDonHang']?.toString();
          int currentUserId = ServiceCall.userPayload['maTaiKhoan'] as int? ?? 0;
          bool isMyOrder = order['maTaiKhoan'] == currentUserId;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMyOrder ? Colors.green.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isMyOrder ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (order['tenKhach']?.toString() ?? 'Khách hàng') + (isMyOrder ? ' (Đơn của bạn)' : ''),
                        style: TextStyle(
                          color: isMyOrder ? Colors.green.shade700 : TColor.primaryText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  order['danhSachMon']?.toString() ?? '',
                  style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}