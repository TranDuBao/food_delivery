import 'package:flutter/material.dart';
import '../../common/app_alert.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/services/shipper_service.dart';

class ShipperMainView extends StatefulWidget {
  const ShipperMainView({Key? key}) : super(key: key);

  @override
  State<ShipperMainView> createState() => _ShipperMainViewState();
}

class _ShipperMainViewState extends State<ShipperMainView> {
  List<dynamic> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => isLoading = true);
    final data = await ShipperService.getAvailableGroups();
    setState(() {
      groups = data;
      isLoading = false;
    });
  }

  void _acceptGroup(int groupId) async {
    final ok = await ShipperService.acceptGroup(groupId);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nhận nhóm đơn thành công! Bắt đầu giao.")));
      // Trong thực tế sẽ chuyển sang màn "Đang Giao Hàng"
      _loadGroups(); 
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nhận thất bại, có thể người khác đã lấy.")));
    }
  }
  
  void _updateStatus(int groupId, String status) async {
     final ok = await ShipperService.updateDeliveryStatus(groupId, status);
     if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã đổi thành: $status")));
        _loadGroups();
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         title: const Text('Shipper: Tìm đơn nhóm'),
         backgroundColor: TColor.white,
         actions: [
           IconButton(icon: const Icon(Icons.refresh), onPressed: _loadGroups)
         ]
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? const Center(child: Text("Radar trống, chưa có đơn nào gom xong!"))
              : ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Khu vực gom: ${group['toaNha']} - Tầng ${group['tang']}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 5),
                            Text("Thời gian nổ chuyến: ${group['thoiGianTaoNhom']}"),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: TColor.primary),
                                  onPressed: () => _acceptGroup(group['maNhomGiaoHang']),
                                  child: const Text('Nhận Chuyến', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
