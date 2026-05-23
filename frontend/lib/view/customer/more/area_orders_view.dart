import 'dart:async';
import 'package:flutter/material.dart';

import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/service_call.dart';
import '../../../common_widget/app_image_view.dart';

class AreaOrdersView extends StatefulWidget {
  final int toaNha;
  final String tenToaNha;

  const AreaOrdersView({super.key, required this.toaNha, required this.tenToaNha});

  @override
  State<AreaOrdersView> createState() => _AreaOrdersViewState();
}

class _AreaOrdersViewState extends State<AreaOrdersView> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Tự động làm mới mỗi 30 giây
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await ServiceCall.fetchGet(
        SVKey.svOrderAreaOrders,
        queryParameters: {'maToaNha': widget.toaNha},
        isToken: true,
      );
      if (response is Map && response['success'] == true) {
        final data = response['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            orders = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'choGhepDon':   return '⏳ Chờ ghép đơn';
      case 'choXacNhan':   return '🤝 Đang ghép...';
      case 'dangChuanBi':  return '👨‍🍳 Đang chuẩn bị';
      case 'choGiaoHang':  return '✅ Sẵn sàng giao';
      case 'dangGiao':     return '🛵 Đang giao';
      case 'daGiao':       return '🎉 Đã giao';
      case 'daHuy':        return '❌ Đã hủy';
      default:             return status ?? '';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'choGhepDon':   return Colors.orange;
      case 'choXacNhan':   return Colors.indigo;
      case 'dangChuanBi':  return Colors.blue;
      case 'choGiaoHang':  return Colors.teal;
      case 'dangGiao':     return Colors.green;
      case 'daGiao':       return Colors.green.shade800;
      case 'daHuy':        return Colors.red;
      default:             return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: Image.asset('assets/img/btn_back.png', width: 20, height: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn đang chờ ghép',
                          style: TextStyle(
                            color: TColor.primaryText,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.tenToaNha.isNotEmpty ? widget.tenToaNha : '${widget.toaNha}',
                          style: TextStyle(color: TColor.secondaryText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Nút refresh thủ công
                  IconButton(
                    onPressed: () {
                      setState(() => isLoading = true);
                      _loadOrders();
                    },
                    icon: Icon(Icons.refresh_rounded, color: TColor.primary),
                  ),
                ],
              ),
            ),

            // Info box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TColor.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TColor.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: TColor.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đơn hàng sẽ được ghép sau 15 phút. '
                      'Khi đủ đơn, hệ thống tự động gom và gửi đến các quán.',
                      style: TextStyle(color: TColor.primary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${orders.length} đơn đang chờ trong khu vực này',
                    style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tự cập nhật mỗi 30s',
                    style: TextStyle(color: TColor.secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  color: TColor.secondaryText, size: 64),
                              const SizedBox(height: 12),
                              Text(
                                'Chưa có đơn nào trong khu vực.',
                                style: TextStyle(color: TColor.secondaryText, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final order = orders[index];
                              final status = order['trangThaiDonHang']?.toString();
                              int currentUserId = ServiceCall.userPayload['maTaiKhoan'] as int? ?? 0;
                              bool isMyOrder = order['maTaiKhoan'] == currentUserId;
                              
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isMyOrder ? Colors.green.withOpacity(0.15) : TColor.textfield,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isMyOrder ? Colors.green.withOpacity(0.5) : Colors.transparent),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (order['tenKhach']?.toString() ?? 'Khách hàng') + (isMyOrder ? ' (Đơn của bạn)' : ''),
                                            style: TextStyle(
                                              color: isMyOrder ? Colors.green.shade700 : TColor.primaryText,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (order['hinhAnhDauTien'] != null && order['hinhAnhDauTien'].toString().isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: AppImageView(
                                                path: order['hinhAnhDauTien'].toString(),
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                placeholderAsset: 'assets/img/app_logo.png',
                                              ),
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            order['danhSachMon']?.toString() ?? '',
                                            style: TextStyle(color: TColor.secondaryText, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
