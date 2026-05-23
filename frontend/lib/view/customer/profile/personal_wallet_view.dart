// personal_wallet_view.dart — Màn hình chính Ví cá nhân
//
// Cấu trúc thư mục:
//   wallet/
//     wallet_constants.dart      ← kBanks, fmtVnd()
//     wallet_widgets.dart        ← WalletBalanceCard, WalletActionBtn, WalletTxTile
//     wallet_deposit_dialog.dart ← WalletDepositDialog, WalletBankInfoWidget
//     wallet_withdraw_dialog.dart ← WalletWithdrawDialog

import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';

import 'wallet/wallet_widgets.dart';
import 'wallet/wallet_deposit_dialog.dart';
import 'wallet/wallet_withdraw_dialog.dart';

class PersonalWalletView extends StatefulWidget {
  const PersonalWalletView({super.key});

  @override
  State<PersonalWalletView> createState() => _PersonalWalletViewState();
}

class _PersonalWalletViewState extends State<PersonalWalletView> {
  double _balance = 0;
  List<Map<String, dynamic>> _txs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCall.fetchGet(SVKey.svCustomerWallet, isToken: true);
      if (res is Map && res['success'] == true) {
        final d = res['data'] as Map;
        _balance = double.tryParse(d['wallet']?['soDu']?.toString() ?? '0') ?? 0;
        final list = d['transactions'] as List? ?? [];
        _txs = list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _openDeposit() => showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => WalletDepositDialog(onDeposited: _load),
  );

  void _openWithdraw() => showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => WalletWithdrawDialog(balance: _balance, onWithdrawn: _load),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Ví cá nhân',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: TColor.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance
                  WalletBalanceCard(balance: _balance),
                  const SizedBox(height: 16),

                  // Actions
                  Row(children: [
                    Expanded(child: WalletActionBtn(
                      icon: Icons.add_rounded,
                      label: 'Nạp tiền',
                      color: const Color(0xFF00C853),
                      onTap: _openDeposit,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: WalletActionBtn(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Rút tiền',
                      color: Colors.orange,
                      onTap: _openWithdraw,
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // Transaction history header
                  const Text('Lịch sử giao dịch',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 10),

                  // List or empty state
                  if (_txs.isEmpty) const WalletEmptyTx(),
                  ..._txs.map((tx) => WalletTxTile(tx: tx)),
                ],
              ),
            ),
    );
  }
}
