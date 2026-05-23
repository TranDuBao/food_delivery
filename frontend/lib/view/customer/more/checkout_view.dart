import 'package:flutter/material.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/round_button.dart';
import '../voucher/voucher_model.dart';
import 'area_orders_view.dart';
import 'checkout_address_section.dart';
import 'checkout_area_orders_section.dart';
import 'checkout_cart_items.dart';
import 'checkout_voucher_widgets.dart';
import 'sepay_payment_view.dart';

class CheckoutView extends StatefulWidget {
  final Map<String, dynamic>? cartData;
  const CheckoutView({super.key, this.cartData});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  late Future<Map<String, dynamic>> cartFuture;
  late TextEditingController txtName;

  List<Map<String, dynamic>> buildings = [];
  List<Map<String, dynamic>> rooms = [];

  int? selectedBuildingId;
  int? selectedRoomId;
  bool isSubmitting = false;
  bool isLoadingAddress = true;
  List<Map<String, dynamic>> areaOrdersPreview = [];
  bool isLoadingAreaOrders = false;
  Voucher? _selectedVoucher;
  String selectedPaymentMethod = 'sepay'; // 'sepay' or 'cash'

  @override
  void initState() {
    super.initState();
    final payload = ServiceCall.userPayload;
    final userName = (payload['hoTen'] ?? payload['fullName'] ?? payload[KKey.name] ?? '').toString().trim();
    txtName = TextEditingController(text: userName);
    cartFuture = widget.cartData != null ? Future.value(widget.cartData!) : _loadCart();
    _loadAddressData();
  }

  @override
  void dispose() {
    txtName.dispose();
    super.dispose();
  }

  Future<void> _loadAddressData() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svAddress, isToken: true);
      if (res is Map && res['success'] == true) {
        final data = res['data'] as Map? ?? {};
        if (mounted) {
          setState(() {
            buildings = (data['buildings'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            rooms    = (data['rooms']     as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingAddress = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingAddress = false);
    }
  }

  Future<void> _loadAreaOrders(int maToaNha) async {
    setState(() { isLoadingAreaOrders = true; areaOrdersPreview = []; });
    try {
      final res = await ServiceCall.fetchGet(
        SVKey.svOrderAreaOrders,
        queryParameters: {'maToaNha': maToaNha.toString()},
        isToken: true,
      );
      if (res is Map && res['success'] == true && mounted) {
        setState(() {
          areaOrdersPreview = (res['data'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => isLoadingAreaOrders = false);
    }
  }

  Future<Map<String, dynamic>> _loadCart() async {
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerCart, isToken: true);
      if (res is Map<String, dynamic> && res['success'] == true) {
        final rawItems = res['data'] as List? ?? [];
        final tongTien = res['tongTien'] ?? 0;
        final items = rawItems.whereType<Map>().map((item) {
          final gia = double.tryParse(item['giaTien']?.toString() ?? '0') ?? 0;
          final sl  = (item['soLuong'] as num?)?.toInt() ?? 1;
          return <String, dynamic>{
            'dishId'     : item['maMonAn'],
            'dishName'   : item['tenMonAn'] ?? 'Món ăn',
            'canteenId'  : item['maGianHang'],
            'canteenName': item['tenGianHang'] ?? '',
            'quantity'   : sl,
            'lineTotal'  : gia * sl,
            'giaTien'    : gia,
            'imageUrl'   : item['hinhAnh'] ?? item['imageUrl'] ?? '',
          };
        }).toList();
        return {'items': items, 'totalAmount': tongTien};
      }
    } catch (_) {}
    return {'items': [], 'totalAmount': 0};
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  List<Map<String, dynamic>> _cartItems(Map<String, dynamic> cart) {
    return (cart['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Tính tổng tiền sau khi áp dụng voucher.
  /// Voucher chỉ giảm giá phần tiền của các món thuộc đúng quán phát hành voucher.
  double _discountedTotal(double total, List<Map<String, dynamic>> items) {
    if (_selectedVoucher == null) return total;

    final voucher = _selectedVoucher!;
    final voucherCanteenId = voucher.restaurantId;

    // Tính subtotal của các món thuộc quán có voucher
    double canteenSubtotal = 0;
    for (final item in items) {
      final itemCanteenId = item['canteenId']?.toString() ?? '';
      if (itemCanteenId == voucherCanteenId) {
        canteenSubtotal += _toDouble(item['lineTotal']);
      }
    }

    // Nếu không có món nào của quán này → không giảm gì
    if (canteenSubtotal <= 0) return total;

    // Tính số tiền được giảm (chỉ trên phần của quán đó)
    final discount = canteenSubtotal * voucher.discountPercent / 100;
    final maxD = voucher.maxDiscount;
    final actualDiscount = maxD != null && discount > maxD ? maxD : discount;

    return (total - actualDiscount).clamp(0, double.infinity);
  }

  Future<void> _submitOrder(Map<String, dynamic> cart) async {
    final items = _cartItems(cart);
    if (items.isEmpty)          { _snack('Giỏ hàng đang trống.'); return; }
    if (txtName.text.trim().isEmpty) { _snack('Vui lòng nhập họ tên.'); return; }
    if (selectedBuildingId == null)  { _snack('Vui lòng chọn tòa nhà.'); return; }
    if (selectedRoomId == null)      { _snack('Vui lòng chọn phòng học.'); return; }

    setState(() => isSubmitting = true);
    try {
      Globs.showHUD(status: 'Đang gửi đơn...');

      final myOrdersRes = await ServiceCall.fetchGet(SVKey.svOrderMy, isToken: true);
      if (myOrdersRes is Map && myOrdersRes['success'] == true) {
        for (var o in (myOrdersRes['data'] as List? ?? [])) {
          if (o['trangThaiDonHang'] == 'choGhepDon' && o['maToaNha'] != selectedBuildingId) {
            Globs.hideHUD();
            if (!mounted) return;
            showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text('Bạn đang có đơn ở ${o['tenToaNha'] ?? ''}. Hủy đơn đó hoặc đặt cùng khu vực.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Đóng', style: TextStyle(color: TColor.primary)))],
            ));
            return;
          }
        }
      }

      double tongTien = 0;
      for (final item in items) tongTien += _toDouble(item['lineTotal']);

      final orderItems = items.map((item) => {
        'maMonAn': item['dishId'],
        'soLuong': item['quantity'] ?? 1,
        'giaTien': _toDouble(item['giaTien']),
      }).toList();

      final res = await ServiceCall.fetchPost(SVKey.svOrderCheckout, isToken: true, body: {
        'maToaNha': selectedBuildingId,
        'maPhong' : selectedRoomId,
        'tongTien': tongTien,
        'items'   : orderItems,
      });

      if (res is! Map || res['success'] != true) {
        throw (res is Map ? (res['message'] ?? 'Đặt hàng thất bại.') : 'Đặt hàng thất bại.').toString();
      }

      final maDonHang = res['data']?['maDonHang'] as int?;
      if (maDonHang == null) throw 'Không lấy được mã đơn hàng.';

      final tenToaNha = buildings.firstWhere(
        (b) => b['maToaNha'] == selectedBuildingId, orElse: () => {},
      )['tenToaNha']?.toString() ?? '';

      if (selectedPaymentMethod == 'sepay') {
        Globs.showHUD(status: 'Đang tạo mã thanh toán...');
        final payRes = await ServiceCall.fetchPost(SVKey.svPaymentCreate, isToken: true,
            body: {'maDonHang': maDonHang, 'tongTien': tongTien.round()});

        if (!mounted) return;
        Globs.hideHUD();

        if (payRes is Map && payRes['success'] == true) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SepayPaymentView(
            maDonHang:     maDonHang,
            amount:        tongTien,
            paymentCode:   payRes['paymentCode']?.toString() ?? '',
            qrUrl:         payRes['qrUrl']?.toString() ?? '',
            accountNumber: payRes['accountNumber']?.toString() ?? '',
            accountName:   payRes['accountName']?.toString() ?? '',
            bankCode:      payRes['bankCode']?.toString() ?? '',
          )));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AreaOrdersView(
            toaNha: selectedBuildingId!, tenToaNha: tenToaNha,
          )));
        }
      } else {
        // Thanh toán tiền mặt
        Globs.hideHUD();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AreaOrdersView(
          toaNha: selectedBuildingId!, tenToaNha: tenToaNha,
        )));
      }
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      Globs.hideHUD();
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cart = snapshot.data ?? <String, dynamic>{};
          final items = _cartItems(cart);
          final total = _toDouble(cart['totalAmount']);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Image.asset('assets/img/btn_back.png', width: 20, height: 20),
                  ),
                  const SizedBox(width: 8),
                  Text('Xác nhận đặt hàng',
                      style: TextStyle(color: TColor.primaryText, fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 20),

                // Địa chỉ
                _title('Thông tin giao hàng'),
                const SizedBox(height: 12),
                CheckoutAddressSection(
                  nameController: txtName,
                  buildings: buildings, rooms: rooms,
                  selectedBuildingId: selectedBuildingId,
                  selectedRoomId: selectedRoomId,
                  onBuildingChanged: (val) => setState(() {
                    selectedBuildingId = val;
                    if (val != null) _loadAreaOrders(val);
                    if (selectedRoomId != null) {
                      final r = rooms.firstWhere((r) => r['maPhong'] == selectedRoomId, orElse: () => {});
                      if (r['maToaNha'] != val) selectedRoomId = null;
                    }
                  }),
                  onRoomChanged: (val) => setState(() {
                    selectedRoomId = val;
                    if (selectedBuildingId == null && val != null) {
                      final r = rooms.firstWhere((r) => r['maPhong'] == val, orElse: () => {});
                      if (r.isNotEmpty) { selectedBuildingId = r['maToaNha'] as int; _loadAreaOrders(selectedBuildingId!); }
                    }
                  }),
                ),
                const SizedBox(height: 24),

                // Gợi ý đơn ghép
                CheckoutAreaOrdersSection(
                  selectedBuildingId: selectedBuildingId,
                  isLoading: isLoadingAreaOrders,
                  orders: areaOrdersPreview,
                  buildings: buildings,
                  sectionTitleText: () => '',
                ),

                // Giỏ hàng
                _title('Món trong giỏ (${items.length} món)'),
                const SizedBox(height: 12),
                CheckoutCartItems(items: items, toDouble: _toDouble),
                const SizedBox(height: 16),

                // Voucher — chỉ hiển thị voucher của gian hàng trong giỏ
                CheckoutVoucherRow(
                  selectedVoucher: _selectedVoucher,
                  totalAmount: total,
                  // Lấy canteenId từ item đầu tiên trong giỏ
                  canteenId: items.isNotEmpty
                      ? items.first['canteenId']?.toString()
                      : null,
                  onResult: (result) {
                    if (!mounted) return;
                    if (result is Voucher) {
                      setState(() => _selectedVoucher = result);
                    } else if (result == kRemoveVoucher) {
                      setState(() => _selectedVoucher = null);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Phương thức thanh toán
                _title('Phương thức thanh toán'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _paymentTile(
                        id: 'sepay',
                        title: 'Chuyển khoản QR (SePay)',
                        icon: Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF0D7EFF),
                      ),
                      const Divider(height: 20),
                      _paymentTile(
                        id: 'cash',
                        title: 'Tiền mặt khi nhận hàng',
                        icon: Icons.payments_rounded,
                        color: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tổng tiền
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Tổng tiền',
                      style: TextStyle(color: TColor.primaryText, fontSize: 15, fontWeight: FontWeight.w700)),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    if (_selectedVoucher != null)
                      Text('${total.toStringAsFixed(0)} đ',
                          style: TextStyle(
                              color: TColor.secondaryText, fontSize: 13,
                              decoration: TextDecoration.lineThrough)),
                    Text('${_discountedTotal(total, items).toStringAsFixed(0)} đ',
                        style: TextStyle(color: TColor.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                  ]),
                ]),
                const SizedBox(height: 24),

                // Nút đặt hàng
                RoundButton(
                  title: isSubmitting ? 'Đang đặt hàng...' : 'Đặt hàng',
                  onPressed: isSubmitting ? () {} : () => _submitOrder(cart),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _title(String text) => Text(text,
      style: TextStyle(color: TColor.primaryText, fontSize: 16, fontWeight: FontWeight.w800));

  Widget _paymentTile({required String id, required String title, required IconData icon, required Color color}) {
    final isSelected = selectedPaymentMethod == id;
    return InkWell(
      onTap: () => setState(() => selectedPaymentMethod = id),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: TColor.primaryText, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? TColor.primary : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}