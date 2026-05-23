// wallet_deposit_dialog.dart — Dialog nạp tiền + màn hình thông tin CK ngân hàng

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'wallet_constants.dart';

// ─── Deposit Dialog ───────────────────────────────────────────────────────────
class WalletDepositDialog extends StatefulWidget {
  final VoidCallback onDeposited;
  const WalletDepositDialog({super.key, required this.onDeposited});

  @override
  State<WalletDepositDialog> createState() => _WalletDepositDialogState();
}

class _WalletDepositDialogState extends State<WalletDepositDialog> {
  final _amtCtrl = TextEditingController();
  Map<String, dynamic>? _bankInfo;
  bool _loading = false;

  @override
  void dispose() { _amtCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final amount = int.tryParse(_amtCtrl.text.replaceAll('.', ''));
    if (amount == null || amount < 10000) {
      _snack('Số tiền tối thiểu là 10.000đ'); return;
    }
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchPost(
          SVKey.svWalletDeposit, isToken: true, body: {'soTien': amount});
      if (res is Map && res['success'] == true) {
        setState(() => _bankInfo = Map<String, dynamic>.from(res['data'] as Map));
      } else {
        _snack((res is Map ? res['message'] : null) ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _bankInfo != null
            ? WalletBankInfoWidget(
                info: _bankInfo!,
                onDone: () { Navigator.pop(context); widget.onDeposited(); },
              )
            : _buildAmountStep(),
      ),
    );
  }

  Widget _buildAmountStep() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Header
      Row(children: [
        const Expanded(
          child: Text('Nạp tiền vào ví',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ),
        IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
      ]),
      const SizedBox(height: 16),

      // Amount field
      TextField(
        controller: _amtCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Số tiền (đ)',
          hintText: 'VD: 100000',
          prefixIcon: const Icon(Icons.monetization_on_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: TColor.primary, width: 1.5),
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text('Thanh toán bằng chuyển khoản ngân hàng',
          style: TextStyle(color: Colors.grey, fontSize: 11)),
      const SizedBox(height: 20),

      // Submit
      SizedBox(
        width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Tiếp tục',
                  style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}

// ─── Bank Info Widget ─────────────────────────────────────────────────────────
class WalletBankInfoWidget extends StatelessWidget {
  final Map<String, dynamic> info;
  final VoidCallback onDone;

  const WalletBankInfoWidget({
    super.key,
    required this.info,
    required this.onDone,
  });

  void _copy(BuildContext ctx, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
      content: Text('Đã sao chép!'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final soTien = (info['soTien'] as num?)?.toDouble() ?? 0;

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(children: [
        const Expanded(
          child: Text('Thông tin chuyển khoản',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        IconButton(icon: const Icon(Icons.close_rounded), onPressed: onDone),
      ]),
      const SizedBox(height: 12),

      // Bank info box
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(children: [
          _InfoRow('Ngân hàng',    info['nganHang']?.toString()   ?? '', context),
          _InfoRow('Số tài khoản', info['soTaiKhoan']?.toString() ?? '', context, copyable: true),
          _InfoRow('Chủ tài khoản', info['tenChuTK']?.toString()  ?? '', context),
          _InfoRow('Số tiền',      fmtVnd(soTien),                       context),
          _InfoRow('Nội dung CK',  info['noiDungCK']?.toString()  ?? '', context, copyable: true, highlight: true),
        ]),
      ),
      const SizedBox(height: 12),

      // Note
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vui lòng ghi đúng nội dung chuyển khoản để hệ thống xác nhận tự động.',
              style: TextStyle(color: Colors.orange, fontSize: 11),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // Done button
      SizedBox(
        width: double.infinity, height: 44,
        child: ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Đã chuyển khoản',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _InfoRow(String label, String value, BuildContext ctx,
      {bool copyable = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: highlight ? Colors.green.shade700 : Colors.black87,
              )),
        ),
        if (copyable)
          GestureDetector(
            onTap: () => _copy(ctx, value),
            child: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
          ),
      ]),
    );
  }
}
