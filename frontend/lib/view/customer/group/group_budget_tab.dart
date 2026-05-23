import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'group_model.dart';
import 'group_wallet_view.dart';
import 'group_wallet_widgets.dart';

class GroupBudgetTab extends StatelessWidget {
  final GroupModel group;

  const GroupBudgetTab({super.key, required this.group});

  GroupWallet get _wallet => group.wallet ??
      GroupWallet(groupId: group.id, balance: 0, qrCode: 'GROUP-${group.referralCode}');

  String _fmt(double b) =>
      '${b.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
                color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(children: [
            const Text('Số dư ví nhóm',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(_fmt(_wallet.balance),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GroupWalletView(group: group))),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nạp tiền', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2ECC71),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GroupWalletView(group: group))),
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('QR', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Transaction history
        Row(children: [
          const Expanded(child: Text('Lịch sử giao dịch',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          TextButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GroupWalletView(group: group))),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
            label: const Text('Xem tất cả'),
            style: TextButton.styleFrom(foregroundColor: TColor.primary),
          ),
        ]),
        const SizedBox(height: 8),

        if (_wallet.transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                const Text('Chưa có giao dịch nào',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ),
          )
        else
          ..._wallet.transactions.take(5).map((t) => WalletTxTile(tx: t)),
      ],
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final WalletTransaction tx;
  const TransactionTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDeposit = tx.type == 'deposit';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDeposit ? const Color(0xFF2ECC71) : Colors.red).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isDeposit ? const Color(0xFF2ECC71) : Colors.red,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.description,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(tx.userName, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
        Text(
          '${isDeposit ? '+' : '-'}${tx.amount.toStringAsFixed(0)} đ',
          style: TextStyle(
            color: isDeposit ? const Color(0xFF2ECC71) : Colors.red,
            fontWeight: FontWeight.w800, fontSize: 14,
          ),
        ),
      ]),
    );
  }
}
