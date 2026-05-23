// wallet_widgets.dart — UI components tái sử dụng cho màn hình ví cá nhân

import 'package:flutter/material.dart';
import 'wallet_constants.dart';

// ─── Balance Card ─────────────────────────────────────────────────────────────
class WalletBalanceCard extends StatelessWidget {
  final double balance;
  const WalletBalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF1DE9B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C853).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        const Icon(Icons.account_balance_wallet_rounded,
            color: Colors.white70, size: 36),
        const SizedBox(height: 8),
        const Text('Số dư ví',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 6),
        Text(fmtVnd(balance),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────
class WalletActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const WalletActionBtn({
    super.key,
    required this.icon,
    required this.label,
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class WalletTxTile extends StatelessWidget {
  final Map<String, dynamic> tx;

  const WalletTxTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final isNap    = tx['loai'] == 'nap';
    final color    = isNap ? const Color(0xFF00C853) : Colors.orange;
    final amount   = double.tryParse(tx['soTien']?.toString() ?? '0') ?? 0;
    final dt       = DateTime.tryParse(tx['thoiGian']?.toString() ?? '');
    final status   = tx['trangThai']?.toString() ?? '';
    final bank     = tx['nganHang']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(
            isNap ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: color, size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Label + bank + date
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isNap ? 'Nạp tiền' : 'Rút tiền',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (bank != null)
              Text(bank,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            if (dt != null)
              Text('${dt.day}/${dt.month}/${dt.year}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
          ]),
        ),

        // Amount + status badge
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isNap ? '+' : '-'}${fmtVnd(amount)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 3),
          _StatusBadge(status: status),
        ]),
      ]),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'hoan_thanh';
    final isFail = status == 'that_bai';
    final color  = isDone ? Colors.green : isFail ? Colors.red : Colors.orange;
    final bg     = isDone ? Colors.green.shade50
                 : isFail ? Colors.red.shade50
                 : Colors.orange.shade50;
    final label  = isDone ? 'Hoàn thành'
                 : isFail ? 'Thất bại'
                 : 'Đang xử lý';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── Empty Transactions ───────────────────────────────────────────────────────
class WalletEmptyTx extends StatelessWidget {
  const WalletEmptyTx({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(Icons.receipt_long_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text('Chưa có giao dịch nào',
              style: TextStyle(color: Colors.grey.shade400)),
        ]),
      ),
    );
  }
}
