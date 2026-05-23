// lib/view/customer/group/group_wallet_widgets.dart
// Reusable widgets cho màn hình Ví nhóm.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'group_model.dart';

// ─── Balance Card ─────────────────────────────────────────────────────────────
class WalletBalanceCard extends StatelessWidget {
  final double balance;
  const WalletBalanceCard({super.key, required this.balance});

  String _fmt(double b) =>
      '${b.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 32),
        const SizedBox(height: 8),
        const Text('Số dư ví nhóm', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text(_fmt(balance),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// ─── QR Code Card ─────────────────────────────────────────────────────────────
class WalletQrCard extends StatelessWidget {
  final String qrCode;
  const WalletQrCard({super.key, required this.qrCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Mã QR nạp tiền',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            color: TColor.primary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép mã QR')),
              );
            },
          ),
        ]),
        const SizedBox(height: 12),
        QrImageView(data: qrCode, version: QrVersions.auto, size: 200, backgroundColor: Colors.white),
        const SizedBox(height: 12),
        Text(qrCode,
            style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w700,
                fontSize: 16, letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('Quét mã này để chuyển tiền vào ví nhóm',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}

// ─── Payment Method Card ──────────────────────────────────────────────────────
class WalletPaymentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const WalletPaymentCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class WalletTxTile extends StatelessWidget {
  final WalletTransaction tx;
  const WalletTxTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDeposit = tx.type == 'deposit';
    final color = isDeposit ? const Color(0xFF2ECC71) : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(
            isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: color, size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(tx.userName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Text('${isDeposit ? '+' : '-'}${tx.amount.toStringAsFixed(0)} đ',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );
  }
}
