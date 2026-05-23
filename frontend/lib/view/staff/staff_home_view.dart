import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common_widget/round_button.dart';
import '../shared/login/welcome_view.dart';

class StaffHomeView extends StatefulWidget {
  const StaffHomeView({super.key});

  @override
  State<StaffHomeView> createState() => _StaffHomeViewState();
}

class _StaffHomeViewState extends State<StaffHomeView> {
  late Future<_StaffData> dashboardFuture;

  @override
  void initState() {
    super.initState();
    dashboardFuture = _loadDashboard();
  }

  Future<_StaffData> _loadDashboard() async {
    dynamic canteenResponse;
    dynamic orderResponse;

    try {
      canteenResponse = await ServiceCall.fetchGet(SVKey.svStaffStoreInfo, isToken: true);
      orderResponse = await ServiceCall.fetchGet(SVKey.svOrderStaffPending, isToken: true);
    } catch (e) {
      debugPrint('[StaffHome] API error: $e');
    }

    final cMap = canteenResponse is Map && canteenResponse['data'] != null
        ? Map<String, dynamic>.from(canteenResponse['data'])
        : <String, dynamic>{};
    
    final canteen = {
      'name': cMap['tenGianHang'] ?? '',
      'location': cMap['moTa'] ?? '',
      'openHours': cMap['gioMoCua'] ?? '',
      'description': cMap['moTa'] ?? '',
    };

    final orders = orderResponse is Map && orderResponse['data'] is List
        ? (orderResponse['data'] as List).whereType<Map>().map((item) {
            final m = Map<String, dynamic>.from(item);
            return {
              'status': m['trangThaiDonHang'] ?? 'pending',
              'dishName': m['danhSachMon'] ?? 'Mon an',
              'quantity': m['soLuong'] ?? '-',
              'floor': m['tang'] ?? '-',
              'deliveryPoint': 'Toa ${m['toaNha'] ?? ''} - P.${m['phong'] ?? ''}',
              'studentName': m['tenKhach'] ?? 'Khach hang',
            };
          }).toList()
        : <Map<String, dynamic>>[];

    return _StaffData(canteen: canteen, orders: orders);
  }

  Future<void> _refresh() async {
    setState(() {
      dashboardFuture = _loadDashboard();
    });
    await dashboardFuture;
  }

  String _statusLabel(dynamic statusRaw) {
    final status = statusRaw?.toString().toLowerCase().trim() ?? '';
    switch (status) {
      case 'pending':
      case 'dangchuanbi':
        return 'Cho xu ly';
      case 'grouped':
      case 'chogiao':
      case 'chogiaohang':
        return 'Da gom don / Cho giao';
      case 'single_accepted':
        return 'Da nhan don le';
      case 'confirmed':
        return 'Da xac nhan';
      case 'delivered':
      case 'dagiao':
        return 'Da giao';
      case 'cancelled':
      case 'dahuy':
        return 'Da huy';
      case 'expired':
        return 'Het han';
      default:
        return status.isEmpty ? 'Cho xu ly' : status;
    }
  }

  Color _statusColor(dynamic statusRaw) {
    final status = statusRaw?.toString().toLowerCase().trim() ?? '';
    switch (status) {
      case 'confirmed':
      case 'grouped':
      case 'single_accepted':
      case 'chogiao':
      case 'chogiaohang':
        return const Color(0xff1453b8);
      case 'delivered':
      case 'dagiao':
        return const Color(0xff1f8f52);
      case 'cancelled':
      case 'dahuy':
      case 'expired':
        return const Color(0xffb42318);
      case 'pending':
      case 'dangchuanbi':
      default:
        return const Color(0xff9c4f12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      body: SafeArea(
        child: FutureBuilder<_StaffData>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final canteen = data?.canteen ?? <String, dynamic>{};
            final orders = data?.orders ?? <Map<String, dynamic>>[];
            final pendingOrders = orders
                .where((item) =>
                    ['pending', 'dangchuanbi'].contains((item['status']?.toString().toLowerCase() ?? '')))
                .length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xfff97316), Color(0xffea580c)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Trang quan ly canteen',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _refresh,
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              canteen['name']?.toString().trim().isNotEmpty ==
                                      true
                                  ? canteen['name'].toString()
                                  : 'Canteen cua ban',
                              style: const TextStyle(
                                color: Color(0xffffedd5),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _SummaryBox(
                                    title: 'Tong don',
                                    value: '${orders.length}'),
                                const SizedBox(width: 8),
                                _SummaryBox(
                                    title: 'Cho xu ly',
                                    value: '$pendingOrders'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Don hang moi nhat',
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (orders.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 24),
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: TColor.secondaryText, size: 44),
                              const SizedBox(height: 8),
                              Text(
                                'Khong co don nao trong canteen hien tai.',
                                style: TextStyle(color: TColor.secondaryText),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: orders.length > 10 ? 10 : orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            final statusColor = _statusColor(order['status']);

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: TColor.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order['dishName']?.toString() ??
                                              'Mon an',
                                          style: TextStyle(
                                            color: TColor.primaryText,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _statusLabel(order['status']),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'SL: ${order['quantity'] ?? 1} | Tang: ${order['floor'] ?? '-'} | Diem giao: ${order['deliveryPoint'] ?? '-'}',
                                    style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Khach: ${order['studentName'] ?? '-'}',
                                    style: TextStyle(
                                        color: TColor.secondaryText,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 18),
                      RoundButton(
                        title: 'Dang xuat',
                        type: RoundButtonType.textPrimary,
                        onPressed: () async {
                          await ServiceCall.logout();
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const WelcomeView()),
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xffffedd5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffData {
  final Map<String, dynamic> canteen;
  final List<Map<String, dynamic>> orders;

  _StaffData({
    required this.canteen,
    required this.orders,
  });
}
