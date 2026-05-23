// wallet_withdraw_dialog.dart — Dialog rút tiền về ngân hàng

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'wallet_constants.dart';

class WalletWithdrawDialog extends StatefulWidget {
  final double balance;
  final VoidCallback onWithdrawn;

  const WalletWithdrawDialog({
    super.key,
    required this.balance,
    required this.onWithdrawn,
  });

  @override
  State<WalletWithdrawDialog> createState() => _WalletWithdrawDialogState();
}

class _WalletWithdrawDialogState extends State<WalletWithdrawDialog> {
  final _amtCtrl  = TextEditingController();
  final _accCtrl  = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _selectedBank;
  bool _loading = false;

  @override
  void dispose() {
    _amtCtrl.dispose(); _accCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amtCtrl.text.replaceAll('.', ''));
    if (amount == null || amount < 10000) { _snack('Số tiền tối thiểu 10.000đ'); return; }
    if (amount > widget.balance)           { _snack('Số dư không đủ'); return; }
    if (_selectedBank == null)             { _snack('Vui lòng chọn ngân hàng'); return; }
    if (_accCtrl.text.trim().isEmpty)      { _snack('Nhập số tài khoản'); return; }
    if (_nameCtrl.text.trim().isEmpty)     { _snack('Nhập tên chủ tài khoản'); return; }

    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchPost(SVKey.svWalletWithdraw, isToken: true, body: {
        'soTien'       : amount,
        'nganHang'     : _selectedBank,
        'soTaiKhoanNH' : _accCtrl.text.trim(),
        'tenChuTK'     : _nameCtrl.text.trim(),
      });
      if (res is Map && res['success'] == true) {
        if (mounted) { Navigator.pop(context); widget.onWithdrawn(); }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message']?.toString() ?? 'Yêu cầu rút tiền đã gửi!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
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

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: TColor.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    final balLabel = fmtVnd(widget.balance);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Header
          Row(children: [
            const Expanded(
              child: Text('Rút tiền',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context)),
          ]),

          // Balance chip
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text('Số dư: $balLabel',
                  style: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.w700)),
            ]),
          ),

          // Bank picker
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBank,
                isExpanded: true,
                hint: const Text('Chọn ngân hàng'),
                items: kBanks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Account number
          TextField(
            controller: _accCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec('Số tài khoản', Icons.credit_card_rounded),
          ),
          const SizedBox(height: 10),

          // Account holder
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _dec('Tên chủ tài khoản', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 10),

          // Amount
          TextField(
            controller: _amtCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dec('Số tiền rút (đ)', Icons.monetization_on_outlined),
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Gửi yêu cầu rút tiền',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}
