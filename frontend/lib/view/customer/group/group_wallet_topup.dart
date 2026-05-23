// lib/view/customer/group/group_wallet_topup.dart
// Dialog nạp tiền qua SePay / Chuyển khoản.

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'group_wallet_widgets.dart';

const _kPaymentMethods = [
  _PayMethod('SePay QR', Icons.qr_code_scanner_rounded, Color(0xFF0D7EFF)),
  _PayMethod('Chuyển khoản', Icons.account_balance_rounded, Color(0xFF6C63FF)),
];

class _PayMethod {
  final String label;
  final IconData icon;
  final Color color;
  const _PayMethod(this.label, this.icon, this.color);
}

/// Hàng ngang 3 phương thức thanh toán + dialog nhập số tiền
class WalletTopUpSection extends StatelessWidget {
  const WalletTopUpSection({super.key});

  void _showDialog(BuildContext context, String method) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nạp tiền qua $method',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Số tiền (VD: 100000)',
              suffixText: 'đ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Bạn sẽ được chuyển sang trang thanh toán $method.',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Tích hợp QR SePay cho nạp ví nhóm
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Vui lòng chuyển khoản qua $method — tính năng đang hoàn thiện'),
                backgroundColor: TColor.primary,
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Nạp tiền qua',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 12),
      Row(children: [
        for (int i = 0; i < _kPaymentMethods.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: WalletPaymentCard(
            label: _kPaymentMethods[i].label,
            icon: _kPaymentMethods[i].icon,
            color: _kPaymentMethods[i].color,
            onTap: () => _showDialog(context, _kPaymentMethods[i].label),
          )),
        ],
      ]),
    ]);
  }
}
