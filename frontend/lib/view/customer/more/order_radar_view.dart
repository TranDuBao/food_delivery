import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../common/app_alert.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';

class OrderRadarView extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final String floor;
  final double lat;
  final double lng;

  const OrderRadarView({
    super.key,
    this.orders = const [],
    this.floor = 'Tầng 1',
    this.lat = 10.762622,
    this.lng = 106.660172,
  });

  @override
  State<OrderRadarView> createState() => _OrderRadarViewState();
}

class _OrderRadarViewState extends State<OrderRadarView> {
  static const int panelRadar = 0;
  static const int panelAbort = 1;
  static const int panelGrouped = 2;
  static const int panelReceived = 3;

  late Future<List<Map<String, dynamic>>> _radarFuture;
  Future<List<Map<String, dynamic>>>? _statusFuture;
  final Set<int> _myOrderIds = <int>{};

  late String _currentFloor;
  late double _currentLat;
  late double _currentLng;

  int _selectedPanel = panelRadar;
  int? _cancellingOrderId;

  @override
  void initState() {
    super.initState();
    _currentFloor = widget.floor;
    _currentLat = widget.lat;
    _currentLng = widget.lng;
    _radarFuture = _loadRadar();
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _isCollectingStatus(Map<String, dynamic> order) {
    final status = order['status']?.toString().toLowerCase().trim() ?? '';
    return status == 'pending' || status == 'collecting';
  }

  bool _isMyOrder(Map<String, dynamic> order) {
    final id = _toInt(order['id']);
    return id > 0 && _myOrderIds.contains(id);
  }

  bool _canCancelCollectingOrder(Map<String, dynamic> order) {
    return _isMyOrder(order) && _isCollectingStatus(order);
  }

  Future<List<Map<String, dynamic>>> _loadRadar() async {
    List<Map<String, dynamic>> seedOrders = widget.orders;

    if (seedOrders.isEmpty) {
      dynamic activeResponse = [];

      seedOrders = activeResponse is List
          ? activeResponse
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];
    }

    _myOrderIds
      ..clear()
      ..addAll(
        seedOrders
            .map((item) => _toInt(item['id']))
            .where((id) => id > 0),
      );

    if (seedOrders.isNotEmpty) {
      final firstOrder = seedOrders.first;
      _currentFloor = firstOrder['floor']?.toString().trim().isNotEmpty == true
          ? firstOrder['floor'].toString()
          : widget.floor;
      _currentLat = _toDouble(firstOrder['lat'], fallback: widget.lat);
      _currentLng = _toDouble(firstOrder['lng'], fallback: widget.lng);
    }

    dynamic response = [];
    /* await ServiceCall.post({
        'lng': _currentLng.toString(),
      }); */

    final radarRows = response is List
        ? response
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    final merged = <int, Map<String, dynamic>>{};
    for (final order in seedOrders) {
      final id = _toInt(order['id']);
      if (id > 0) {
        merged[id] = Map<String, dynamic>.from(order);
      }
    }
    for (final order in radarRows) {
      final id = _toInt(order['id']);
      if (id > 0) {
        merged[id] = order;
      }
    }

    return merged.values.toList();
  }

  Future<List<Map<String, dynamic>>> _loadOrdersByStatus(List<String> statuses) async {
    dynamic response = [];
    /* await ServiceCall.post({
        'limit': '100',
      }); */

    if (response is! List) {
      return <Map<String, dynamic>>[];
    }

    return response
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _statusesForPanel(int panel) {
    switch (panel) {
      case panelAbort:
        return const ['abort'];
      case panelGrouped:
        return const ['grouped', 'single_accepted', 'confirmed'];
      case panelReceived:
        return const ['delivered'];
      case panelRadar:
      default:
        return const ['pending'];
    }
  }

  String _emptyTextForPanel(int panel) {
    switch (panel) {
      case panelAbort:
        return 'Chưa có đơn nào đã hủy.';
      case panelGrouped:
        return 'Chưa có đơn nào đã ghép.';
      case panelReceived:
        return 'Chưa có đơn nào đã nhận.';
      case panelRadar:
      default:
        return 'Chưa có đơn nào gần khu vực này.';
    }
  }

  Future<void> _refreshCurrentPanel() async {
    if (_selectedPanel == panelRadar) {
      setState(() {
        _radarFuture = _loadRadar();
      });
      await _radarFuture;
      return;
    }

    setState(() {
      _statusFuture = _loadOrdersByStatus(_statusesForPanel(_selectedPanel));
    });
    await _statusFuture;
  }

  Future<void> _switchPanel(int panel) async {
    if (_selectedPanel == panel) {
      return;
    }

    setState(() {
      _selectedPanel = panel;
      if (panel != panelRadar) {
        _statusFuture = _loadOrdersByStatus(_statusesForPanel(panel));
      }
    });
  }

  Future<void> _cancelCollectingOrder(Map<String, dynamic> order) async {
    final orderId = _toInt(order['id']);
    if (orderId <= 0 || !_canCancelCollectingOrder(order)) {
      return;
    }

    if (_cancellingOrderId != null) {
      return;
    }

    setState(() {
      _cancellingOrderId = orderId;
    });

    try {
      await ServiceCall.fetchPost(
        SVKey.svOrderMyCancel(orderId.toString()),
        isToken: true,
        body: {
          'reason': 'CUSTOMER_ABORT_WHILE_COLLECTING',
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy đơn đang ghép (abort).')),
      );

      setState(() {
        _radarFuture = _loadRadar();
        if (_selectedPanel != panelRadar) {
          _statusFuture = _loadOrdersByStatus(_statusesForPanel(_selectedPanel));
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cancellingOrderId = null;
        });
      }
    }
  }

  String _labelForOrder(Map<String, dynamic> order) {
    final dishName = order['dishName']?.toString().trim() ?? '';
    final canteenName = order['canteenName']?.toString().trim() ?? '';
    if (dishName.isNotEmpty && canteenName.isNotEmpty) {
      return '$dishName - $canteenName';
    }
    if (dishName.isNotEmpty) {
      return dishName;
    }
    return 'Đơn #${order['id'] ?? ''}';
  }

  String _statusText(dynamic rawStatus) {
    final status = rawStatus?.toString().toLowerCase().trim() ?? '';
    switch (status) {
      case 'pending':
        return 'Đang ghép';
      case 'grouped':
      case 'single_accepted':
      case 'confirmed':
        return 'Đã ghép';
      case 'delivered':
        return 'Đã nhận';
      case 'abort':
        return 'Abort';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return status.isEmpty ? 'Đang ghép' : status;
    }
  }

  Color _statusColor(dynamic rawStatus) {
    final status = rawStatus?.toString().toLowerCase().trim() ?? '';
    switch (status) {
      case 'grouped':
      case 'single_accepted':
      case 'confirmed':
        return const Color(0xff1453b8);
      case 'delivered':
        return const Color(0xff1f8f52);
      case 'abort':
      case 'cancelled':
        return const Color(0xffb42318);
      case 'pending':
      default:
        return const Color(0xff9c4f12);
    }
  }

  Widget _buildPanelButton({
    required int panel,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPanel == panel;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchPanel(panel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xffc2410c) : Colors.white,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchBar() {
    return Row(
      children: [
        _buildPanelButton(
          panel: panelRadar,
          title: 'Đơn đang ghép',
          icon: Icons.radar_rounded,
        ),
        const SizedBox(width: 8),
        _buildPanelButton(
          panel: panelAbort,
          title: 'Đơn đã hủy\nAbort',
          icon: Icons.cancel_outlined,
        ),
        const SizedBox(width: 8),
        _buildPanelButton(
          panel: panelGrouped,
          title: 'Đơn đã ghép',
          icon: Icons.groups_rounded,
        ),
        const SizedBox(width: 8),
        _buildPanelButton(
          panel: panelReceived,
          title: 'Đơn đã nhận',
          icon: Icons.inventory_2_rounded,
        ),
      ],
    );
  }

  Widget _buildRadarSurface(List<Map<String, dynamic>> orders) {
    final size = 290.0;
    final pointCount = math.max(orders.length, 1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xfffff4ea),
            const Color(0xffffe0c8),
            TColor.white,
          ],
          stops: const [0.12, 0.48, 1],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.88, end: 1),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, pulse, child) {
              return Transform.scale(scale: pulse, child: child);
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xffffb684).withOpacity(0.42), width: 2),
              ),
            ),
          ),
          Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xffffb684).withOpacity(0.5), width: 2),
            ),
          ),
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xffffb684).withOpacity(0.58), width: 2),
            ),
          ),
          Container(
            width: size * 0.14,
            height: size * 0.14,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xfff97316), Color(0xffea580c)],
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55ea580c),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 22),
          ),
          for (int i = 0; i < pointCount; i += 1)
            _RadarDot(
              angle: (math.pi * 2 / pointCount) * i,
              radius: 104,
              label: i < orders.length ? _labelForOrder(orders[i]) : '',
              active: i < orders.length,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(dynamic rawStatus) {
    final color = _statusColor(rawStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusText(rawStatus),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRadarOrderCard(Map<String, dynamic> order, int index) {
    final orderId = _toInt(order['id']);
    final canCancel = _canCancelCollectingOrder(order);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xfffff2e8),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: TColor.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForOrder(order),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBadge(order['status']),
                    const SizedBox(width: 8),
                    Icon(Icons.pin_drop_rounded,
                        color: TColor.secondaryText, size: 14),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Tầng ${order['floor'] ?? _currentFloor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canCancel) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 34,
              child: TextButton(
                onPressed: _cancellingOrderId == orderId
                    ? null
                    : () => _cancelCollectingOrder(order),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffb42318),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 34),
                ),
                child: Text(
                  _cancellingOrderId == orderId ? 'Đang hủy...' : 'Hủy đơn',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusOrderCard(Map<String, dynamic> order, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xfffff2e8),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: TColor.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForOrder(order),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TColor.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusBadge(order['status']),
                    const SizedBox(width: 8),
                    Icon(Icons.store_mall_directory_outlined,
                        color: TColor.secondaryText, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order['canteenName']?.toString() ?? 'Căn tin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList({
    required AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    required List<Map<String, dynamic>> rows,
    required String emptyText,
    required bool useRadarCard,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, color: TColor.secondaryText, size: 42),
            const SizedBox(height: 8),
            Text(
              emptyText,
              style: TextStyle(color: TColor.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (useRadarCard) {
          return _buildRadarOrderCard(rows[index], index);
        }
        return _buildStatusOrderCard(rows[index], index);
      },
    );
  }

  Widget _buildRadarPanel(AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
    final allRows = snapshot.data ?? <Map<String, dynamic>>[];
    final rows = allRows.where(_isCollectingStatus).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách đơn đang ghép',
          style: TextStyle(
            color: TColor.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildOrderList(
          snapshot: snapshot,
          rows: rows,
          emptyText: _emptyTextForPanel(panelRadar),
          useRadarCard: true,
        ),
      ],
    );
  }

  Widget _buildStatusPanel(int panel) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _statusFuture,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              panel == panelAbort
                  ? 'Danh sách đơn đã hủy (abort)'
                  : panel == panelGrouped
                    ? 'Danh sách đơn đã ghép'
                    : 'Danh sách đơn đã nhận',
              style: TextStyle(
                color: TColor.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            _buildOrderList(
              snapshot: snapshot,
              rows: rows,
              emptyText: _emptyTextForPanel(panel),
              useRadarCard: false,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffff8f2),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _radarFuture,
          builder: (context, radarSnapshot) {
            final trackingCount = (radarSnapshot.data ?? const <Map<String, dynamic>>[]).length;

            return RefreshIndicator(
              onRefresh: _refreshCurrentPanel,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
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
                                Material(
                                  color: Colors.white.withOpacity(0.24),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => Navigator.pop(context),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.arrow_back_rounded,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Material(
                                  color: Colors.white.withOpacity(0.24),
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: _refreshCurrentPanel,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.refresh_rounded,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Điều phối đơn canteen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Theo dõi $trackingCount đơn trong khu vực hiện tại',
                              style: const TextStyle(
                                color: Color(0xffffedd5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildDispatchBar(),
                      const SizedBox(height: 14),
                      if (_selectedPanel == panelRadar)
                        _buildRadarPanel(radarSnapshot)
                      else
                        _buildStatusPanel(_selectedPanel),
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

class _RadarDot extends StatelessWidget {
  final double angle;
  final double radius;
  final String label;
  final bool active;

  const _RadarDot({
    required this.angle,
    required this.radius,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final offsetX = math.cos(angle) * radius;
    final offsetY = math.sin(angle) * radius;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xfff97316)
                  : TColor.secondaryText.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x66f97316),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 82,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TColor.secondaryText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
