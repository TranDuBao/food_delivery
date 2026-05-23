import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/locator.dart';
import 'package:food_delivery/view/customer/group/group_service.dart';
import 'package:food_delivery/view/customer/voucher/voucher_service.dart';
import 'package:http/http.dart' as http;

typedef ResSuccess = Future<void> Function(Map<String, dynamic>);
typedef ResSuccessAny = Future<void> Function(dynamic);
typedef ResFailure = Future<void> Function(dynamic);

class ServiceCall {
  static final NavigationService navigationService = locator<NavigationService>();
  static Map userPayload = {};


  static void post(Map<String, dynamic> parameter, String path,
      {bool isToken = false, ResSuccess? withSuccess, ResFailure? failure}) {
    Future(() {
      try {
        var headers = {'Content-Type': 'application/json'};

        if (isToken) {
          final authToken = Globs.udValueString(KKey.authToken);
          if (authToken.isNotEmpty) {
            headers["Authorization"] = "Bearer $authToken";
          }
        }

        http
          .post(Uri.parse(path), body: json.encode(parameter), headers: headers)
            .then((value) {
          if (kDebugMode) {
            print(value.body);
          }
          try {
            var jsonObj =
                json.decode(value.body) as Map<String, dynamic>? ?? {};

            if (value.statusCode >= 200 && value.statusCode < 300) {
              if (withSuccess != null) withSuccess(jsonObj);
            } else {
              if (failure != null) {
                failure(jsonObj[KKey.message] ?? value.body);
              }
            }
          } catch (err) {
            if (failure != null) failure(err.toString());
          }
        }).catchError( (e) {
           if (failure != null) failure(e.toString());
        });
      } catch (err) {
        if (failure != null) failure(err.toString());
      }
    });
  }

  static Future<dynamic> fetchPost(String path,
      {Map<String, dynamic>? body, bool isToken = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (isToken) {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    final value = await http.post(
      Uri.parse(path),
      body: json.encode(body ?? {}),
      headers: headers,
    ).timeout(const Duration(seconds: 15));

    if (kDebugMode) {
      print(value.body);
    }

    final decoded = json.decode(value.body);

    if (value.statusCode >= 200 && value.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw decoded[KKey.message] ?? value.body;
    }

    throw value.body;
  }

  static Future<dynamic> fetchPut(String path,
      {Map<String, dynamic>? body, bool isToken = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (isToken) {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    final value = await http.put(
      Uri.parse(path),
      body: json.encode(body ?? {}),
      headers: headers,
    );

    if (kDebugMode) {
      print(value.body);
    }

    final decoded = json.decode(value.body);

    if (value.statusCode >= 200 && value.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw decoded[KKey.message] ?? value.body;
    }

    throw value.body;
  }

  static Future<dynamic> fetchDelete(String path, {bool isToken = false}) async {
    final headers = {'Content-Type': 'application/json'};

    if (isToken) {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    final value = await http.delete(Uri.parse(path), headers: headers);

    if (kDebugMode) {
      print(value.body);
    }

    final decoded = json.decode(value.body);

    if (value.statusCode >= 200 && value.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw decoded[KKey.message] ?? value.body;
    }

    throw value.body;
  }

  static void get(String path,
      {Map<String, dynamic>? queryParameters,
      bool isToken = false,
      ResSuccessAny? withSuccess,
      ResFailure? failure}) {
    Future(() {
      try {
        var headers = {'Content-Type': 'application/json'};

        if (isToken) {
          final authToken = Globs.udValueString(KKey.authToken);
          if (authToken.isNotEmpty) {
            headers['Authorization'] = 'Bearer $authToken';
          }
        }

        final uri = Uri.parse(path).replace(
          queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
        );

        http.get(uri, headers: headers).then((value) {
          if (kDebugMode) {
            print(value.body);
          }

          try {
            final decoded = json.decode(value.body);

            if (value.statusCode >= 200 && value.statusCode < 300) {
              if (withSuccess != null) withSuccess(decoded);
            } else {
              if (failure != null) {
                if (decoded is Map<String, dynamic>) {
                  failure(decoded[KKey.message] ?? value.body);
                } else {
                  failure(value.body);
                }
              }
            }
          } catch (err) {
            if (failure != null) failure(err.toString());
          }
        }).catchError((e) {
          if (failure != null) failure(e.toString());
        });
      } catch (err) {
        if (failure != null) failure(err.toString());
      }
    });
  }

  static Future<dynamic> fetchGet(String path,
      {Map<String, dynamic>? queryParameters, bool isToken = false}) async {
    var headers = {'Content-Type': 'application/json'};

    if (isToken) {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }

    final uri = Uri.parse(path).replace(
      queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
    );

    final value = await http.get(uri, headers: headers);

    if (kDebugMode) {
      print(value.body);
    }

    final decoded = json.decode(value.body);

    if (value.statusCode >= 200 && value.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      throw decoded[KKey.message] ?? value.body;
    }

    throw value.body;
  }

  static logout(){
    Globs.udBoolSet(false, Globs.userLogin);
    Globs.udRemove(KKey.authToken);
    Globs.udRemove(Globs.userPayload);
    userPayload = {};
    GroupService.instance.clearSession(); // xóa nhóm khỏi memory khi đăng xuất
    VoucherService.instance.clearSession(); // xóa voucher cache khi đăng xuất
    navigationService.navigateTo("welcome");
  }

  /// Upload một file ảnh dưới dạng multipart/form-data.
  /// Trả về URL của ảnh sau khi upload thành công, hoặc null nếu lỗi.
  static Future<String?> uploadImageFile(
    String path,
    dynamic file, {
    String fieldName = 'image',
    bool isToken = true,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(path));

      if (isToken) {
        final authToken = Globs.udValueString(KKey.authToken);
        if (authToken.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $authToken';
        }
      }

      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) print(response.body);

      final decoded = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Backend trả về { imageUrl: '...' } hoặc { url: '...' } hoặc { data: { url: '...' } }
        return (decoded['imageUrl'] ?? decoded['url'] ?? decoded['data']?['url'])?.toString();
      }
    } catch (e) {
      if (kDebugMode) print('uploadImageFile error: $e');
    }
    return null;
  }

}
