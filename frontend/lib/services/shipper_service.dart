import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';

class ShipperService {
  static String get basePath => "${SVKey.apiBaseUrl}shipper";

  // 1. Xem các nhóm đơn có thể nhận
  static Future<List<dynamic>> getAvailableGroups() async {
    final res = await ServiceCall.fetchGet("$basePath/groups/available", isToken: true);
    if (res['success'] == true) {
      return res['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  // 2. Nhận đơn nhóm
  static Future<bool> acceptGroup(int groupId) async {
    try {
      final res = await ServiceCall.fetchPost("$basePath/groups/$groupId/accept", isToken: true);
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // 3. Cập nhật trạng thái
  static Future<bool> updateDeliveryStatus(int groupId, String status) async {
    try {
      final res = await ServiceCall.fetchPut(
        "$basePath/groups/$groupId/status",
        isToken: true,
        body: {'status': status} // 'daGiao' hoặc 'daHuy'
      );
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
