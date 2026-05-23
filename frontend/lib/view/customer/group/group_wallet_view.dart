import 'package:flutter/material.dart';
import 'group_model.dart';
import 'group_wallet_topup.dart';
import 'group_wallet_widgets.dart';

class GroupWalletView extends StatelessWidget {
  final GroupModel group;
  const GroupWalletView({super.key, required this.group});

  GroupWallet get _wallet => group.wallet ??
      GroupWallet(groupId: group.id, balance: 0, qrCode: 'GROUP-${group.referralCode}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Ví nhóm – ${group.name}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Balance
          WalletBalanceCard(balance: _wallet.balance),
          const SizedBox(height: 24),

          // QR Code
          WalletQrCard(qrCode: _wallet.qrCode),
          const SizedBox(height: 20),

          // Top-up (VNPay / MoMo / Chuyển khoản)
          const WalletTopUpSection(),
          const SizedBox(height: 24),

          // Transaction history
          const Text('Lịch sử giao dịch',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),

          if (_wallet.transactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('Chưa có giao dịch nào',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ]),
              ),
            )
          else
            ..._wallet.transactions.map((t) => WalletTxTile(tx: t)),
        ],
      ),
    );
  }
}
