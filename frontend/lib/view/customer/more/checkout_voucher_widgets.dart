// lib/view/customer/more/checkout_voucher_widgets.dart
// Widget dòng voucher + bottom sheet chọn voucher trong màn xác nhận đặt hàng

import 'package:flutter/material.dart';
import '../voucher/voucher_model.dart';
import '../voucher/voucher_service.dart';
import '../../../common/color_extension.dart';

// Sentinel: người dùng bấm "Bỏ chọn voucher"
const kRemoveVoucher = '__remove_voucher__';

// ─── Voucher Row ──────────────────────────────────────────────────────────────
class CheckoutVoucherRow extends StatelessWidget {
  final Voucher? selectedVoucher;
  final double totalAmount;
  final String? canteenId;            // maGianHang đang đặt
  final void Function(Object?) onResult;

  const CheckoutVoucherRow({
    super.key,
    required this.selectedVoucher,
    required this.totalAmount,
    required this.onResult,
    this.canteenId,
  });

  Future<void> _openPicker(BuildContext context) async {
    // Chỉ lấy voucher của đúng gian hàng đang đặt
    final allVouchers = VoucherService.instance.myVouchers;
    final myVouchers = canteenId != null
        ? allVouchers.where((v) => v.restaurantId == canteenId).toList()
        : allVouchers;
    if (myVouchers.isEmpty) return;

    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => VoucherPickerSheet(
        vouchers: myVouchers,
        totalAmount: totalAmount,
        selected: selectedVoucher,
      ),
    );
    onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    // Đếm voucher hợp lệ cho gian hàng này
    final allVouchers = VoucherService.instance.myVouchers;
    final myVouchers = canteenId != null
        ? allVouchers.where((v) => v.restaurantId == canteenId).toList()
        : allVouchers;
    if (myVouchers.isEmpty && selectedVoucher == null) return const SizedBox();

    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedVoucher != null
                ? const Color(0xFFFF6B35)
                : const Color(0xFFFFCCBB),
          ),
        ),
        child: Row(children: [
          const Icon(Icons.local_offer_rounded, color: Color(0xFFFF6B35), size: 20),
          const SizedBox(width: 10),
          Expanded(child: selectedVoucher != null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(selectedVoucher!.title,
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35), fontSize: 13)),
                  Text(
                    'Giảm ${selectedVoucher!.discountPercent.toInt()}%'
                    '${selectedVoucher!.maxDiscount != null ? ' (tối đa ${selectedVoucher!.maxDiscount!.toStringAsFixed(0)}đ)' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ])
              : Text(
                  myVouchers.isNotEmpty
                      ? 'Chọn voucher (${myVouchers.length} có sẵn)'
                      : 'Bạn chưa có voucher',
                  style: TextStyle(
                    color: myVouchers.isNotEmpty ? const Color(0xFFFF6B35) : Colors.grey,
                    fontWeight: FontWeight.w600, fontSize: 13,
                  ),
                )),
          if (selectedVoucher != null)
            GestureDetector(
              onTap: () => onResult(kRemoveVoucher),
              child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ]),
      ),
    );
  }
}

// ─── Voucher Picker Sheet ─────────────────────────────────────────────────────
class VoucherPickerSheet extends StatelessWidget {
  final List<Voucher> vouchers;
  final double totalAmount;
  final Voucher? selected;

  const VoucherPickerSheet({
    super.key,
    required this.vouchers,
    required this.totalAmount,
    this.selected,
  });

  double _saved(Voucher v) {
    final d = totalAmount * v.discountPercent / 100;
    final m = v.maxDiscount;
    return m != null && d > m ? m : d;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Chọn voucher',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              itemCount: vouchers.length,
              itemBuilder: (_, i) {
                final v = vouchers[i];
                final isSel = selected?.id == v.id;
                final saved = _saved(v);
                return GestureDetector(
                  onTap: () => Navigator.pop(context, v),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFFF3ED) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? const Color(0xFFFF6B35) : Colors.grey.shade200,
                        width: isSel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('-${v.discountPercent.toInt()}%',
                              style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w900, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(v.restaurantName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('Tiết kiệm: ~${saved.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                                color: Color(0xFFFF6B35), fontWeight: FontWeight.w600, fontSize: 12)),
                      ])),
                      if (isSel)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFFFF6B35), size: 22),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (selected != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, kRemoveVoucher),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Bỏ chọn voucher',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
