// lib/view/customer/more/checkout_area_orders_section.dart
// Widget gợi ý đơn ghép theo tòa nhà trong màn xác nhận đặt hàng

import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common/service_call.dart';

class CheckoutAreaOrdersSection extends StatelessWidget {
  final int? selectedBuildingId;
  final bool isLoading;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> buildings;
  final String Function() sectionTitleText;

  const CheckoutAreaOrdersSection({
    super.key,
    required this.selectedBuildingId,
    required this.isLoading,
    required this.orders,
    required this.buildings,
    required this.sectionTitleText,
  });

  String get _buildingName => buildings
      .firstWhere((b) => b['maToaNha'] == selectedBuildingId, orElse: () => {})['tenToaNha']
      ?.toString() ?? selectedBuildingId.toString();

  @override
  Widget build(BuildContext context) {
    if (selectedBuildingId == null) return const SizedBox();
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (orders.isEmpty) return const SizedBox();

    final previewList = orders.take(3).toList();
    final currentUserId = ServiceCall.userPayload['maTaiKhoan'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(
            'Gợi ý đơn ghép tòa $_buildingName',
            style: TextStyle(color: TColor.primaryText, fontSize: 16, fontWeight: FontWeight.w800),
          )),
          if (orders.length > 3)
            TextButton(
              onPressed: () => _showAll(context, currentUserId),
              child: Text('Xem tất cả',
                  style: TextStyle(color: TColor.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 12),
        _OrderList(orders: previewList, currentUserId: currentUserId, compact: true),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showAll(BuildContext context, int currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllAreaOrdersSheet(
        buildingName: _buildingName,
        orders: orders,
        currentUserId: currentUserId,
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────
class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final int currentUserId;
  final bool compact;

  const _OrderList({required this.orders, required this.currentUserId, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColor.textfield,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: orders.length,
        separatorBuilder: (_, __) => Divider(
            indent: 16, endIndent: 16,
            color: TColor.secondaryText.withValues(alpha: 0.3), height: 1),
        itemBuilder: (_, i) {
          final order = orders[i];
          final isMe = order['maTaiKhoan'] == currentUserId;
          return Container(
            color: isMe ? Colors.green.withValues(alpha: 0.12) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  (order['tenKhach']?.toString() ?? 'Khách') + (isMe ? ' (Đơn của bạn)' : ''),
                  style: TextStyle(
                    color: isMe ? Colors.green.shade700 : TColor.primaryText,
                    fontSize: compact ? 14 : 15, fontWeight: FontWeight.w700,
                  ),
                )),
                Text('P.${order['tenPhong'] ?? ''}',
                    style: TextStyle(
                      color: isMe ? Colors.green.shade700 : TColor.secondaryText,
                      fontSize: compact ? 12 : 13,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.normal,
                    )),
              ]),
              const SizedBox(height: 4),
              Text(order['danhSachMon']?.toString() ?? '',
                  style: TextStyle(color: TColor.secondaryText, fontSize: compact ? 12 : 13),
                  maxLines: compact ? 1 : null,
                  overflow: compact ? TextOverflow.ellipsis : null),
            ]),
          );
        },
      ),
    );
  }
}

// ─── All Area Orders Sheet ────────────────────────────────────────────────────
class _AllAreaOrdersSheet extends StatelessWidget {
  final String buildingName;
  final List<Map<String, dynamic>> orders;
  final int currentUserId;

  const _AllAreaOrdersSheet({
    required this.buildingName,
    required this.orders,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Đơn chờ ghép tại Tòa $buildingName',
            style: TextStyle(color: TColor.primaryText, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _OrderList(orders: orders, currentUserId: currentUserId, compact: false),
        )),
      ]),
    );
  }
}
