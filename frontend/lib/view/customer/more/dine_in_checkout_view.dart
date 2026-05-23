import 'package:flutter/material.dart';
import 'package:food_delivery/common/app_alert.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/view/customer/main_tabview/main_tabview.dart';

import '../more/sepay_payment_view.dart';

/// Màn hình xác nhận & thanh toán đơn dine-in.
class DineInCheckoutView extends StatefulWidget {
  final int maGianHang;
  final String tenGianHang;
  final List<Map<String, dynamic>> items;
  final double tongTien;

  const DineInCheckoutView({
    super.key,
    required this.maGianHang,
    required this.tenGianHang,
    required this.items,
    required this.tongTien,
  });

  @override
  State<DineInCheckoutView> createState() => _DineInCheckoutViewState();
}

class _DineInCheckoutViewState extends State<DineInCheckoutView> {
  bool _isSubmitting = false;
  String _paymentMethod = 'sepay'; // 'sepay' | 'cash'

  double get _total => widget.tongTien;

  Future<void> _placeOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    Globs.showHUD(status: 'Đang gửi đơn...');
    try {
      final orderItems = widget.items.map((it) => {
        'maMonAn': it['maMonAn'],
        'soLuong': it['soLuong'],
        'giaTien': it['giaTien'],
      }).toList();

      final res = await ServiceCall.fetchPost(
        SVKey.svDineInCheckout,
        isToken: true,
        body: {
          'maGianHang': widget.maGianHang,
          'items': orderItems,
          'tongTien': _total.round(),
        },
      );

      if (res is! Map || res['success'] != true) {
        throw (res is Map ? (res['message'] ?? 'Đặt hàng thất bại') : 'Lỗi hệ thống').toString();
      }

      final maDonHang = res['data']?['maDonHang'] as int?;
      if (maDonHang == null) throw 'Không lấy được mã đơn hàng.';

      Globs.hideHUD();
      if (!mounted) return;

      if (_paymentMethod == 'sepay') {
        // Tạo mã thanh toán SePay
        Globs.showHUD(status: 'Đang tạo mã thanh toán...');
        final payRes = await ServiceCall.fetchPost(
          SVKey.svPaymentCreate,
          isToken: true,
          body: {'maDonHang': maDonHang, 'tongTien': _total.round()},
        );
        Globs.hideHUD();
        if (!mounted) return;

        if (payRes is Map && payRes['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SepayPaymentView(
                maDonHang: maDonHang,
                amount: _total,
                paymentCode: payRes['paymentCode']?.toString() ?? '',
                qrUrl: payRes['qrUrl']?.toString() ?? '',
                accountNumber: payRes['accountNumber']?.toString() ?? '',
                accountName: payRes['accountName']?.toString() ?? '',
                bankCode: payRes['bankCode']?.toString() ?? '',
              ),
            ),
          );
        } else {
          _showSuccessAndNavigate();
        }
      } else {
        // Tiền mặt – không cần thanh toán online
        _showSuccessAndNavigate();
      }
    } catch (e) {
      Globs.hideHUD();
      if (mounted) AppAlert.show(context, message: e.toString(), type: 'error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessAndNavigate() {
    AppAlert.show(context, message: 'Đặt món thành công! Quán đang chuẩn bị.', type: 'success');
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainTabView(initialTab: 1)),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.tenGianHang,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1A1A1A)),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner dine-in ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TColor.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.table_restaurant_rounded, color: TColor.primary, size: 24),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gọi món tại bàn',
                        style: TextStyle(
                          color: TColor.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Món sẽ được phục vụ tại bàn của bạn',
                        style: TextStyle(color: TColor.primary.withOpacity(0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Danh sách món ─────────────────────────────────────────
            const Text('Món đã chọn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: widget.items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final isLast = i == widget.items.length - 1;
                  final price = (item['giaTien'] as num?)?.toDouble() ?? 0;
                  final qty = (item['soLuong'] as int?) ?? 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: TColor.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$qty',
                                style: TextStyle(
                                  color: TColor.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['tenMonAn']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                            Text(
                              '${(price * qty).toStringAsFixed(0)}đ',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tổng tiền ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    '${_total.toStringAsFixed(0)}đ',
                    style: TextStyle(
                      color: TColor.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Phương thức thanh toán ─────────────────────────────────
            const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _payTile('sepay', 'Chuyển khoản QR (SePay)', Icons.qr_code_scanner_rounded, const Color(0xFF0D7EFF)),
                  Divider(height: 1, color: Colors.grey.shade100),
                  _payTile('cash', 'Tiền mặt khi nhận món', Icons.payments_rounded, Colors.green.shade600),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── Nút đặt món ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  _isSubmitting ? 'Đang gửi đơn...' : 'Đặt món ngay',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _payTile(String id, String title, IconData icon, Color color) {
    final selected = _paymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? TColor.primary : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}
