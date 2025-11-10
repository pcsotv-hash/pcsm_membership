import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl, connectTimeout: const Duration(seconds: 30)));

  // Submit form (multipart)
  Future<Map<String,dynamic>> submitForm({
    required Map<String,dynamic> fields,
    File? photo,
    File? cnicFront,
    File? cnicBack,
    Function(int,int)? onSendProgress,
  }) async {
    try {
      FormData formData = FormData();
      fields.forEach((k,v) => formData.fields.add(MapEntry(k, v?.toString() ?? "")));
      if (photo != null) {
        formData.files.add(MapEntry("photo", await MultipartFile.fromFile(photo.path, filename: photo.path.split('/').last)));
      }
      if (cnicFront != null) {
        formData.files.add(MapEntry("cnic_front", await MultipartFile.fromFile(cnicFront.path, filename: cnicFront.path.split('/').last)));
      }
      if (cnicBack != null) {
        formData.files.add(MapEntry("cnic_back", await MultipartFile.fromFile(cnicBack.path, filename: cnicBack.path.split('/').last)));
      }

      final resp = await _dio.post(AppConstants.submitEndpoint, data: formData, onSendProgress: onSendProgress);
      return resp.data is Map ? Map<String,dynamic>.from(resp.data) : {"status":0, "message":"Invalid response"};
    } catch (e) {
      return {"status":0, "message": e.toString()};
    }
  }

  // Admin login
  Future<Map<String,dynamic>> adminLogin(String username, String password) async {
    try {
      final r = await _dio.post(AppConstants.adminLogin, data: {"username": username, "password": password});
      return r.data is Map ? Map<String,dynamic>.from(r.data) : {"status":0, "message":"Invalid response"};
    } catch (e) {
      return {"status":0, "message": e.toString()};
    }
  }

  // Fetch members (admin)
  Future<Map<String,dynamic>> fetchMembers({String status = ""}) async {
    try {
      final r = await _dio.get(AppConstants.adminMembers, queryParameters: {"status": status});
      return r.data is Map ? Map<String,dynamic>.from(r.data) : {"status":0, "message":"Invalid response"};
    } catch (e) {
      return {"status":0, "message": e.toString()};
    }
  }

  // Update member status (admin)
  Future<Map<String,dynamic>> updateMemberStatus(int id, String status) async {
    try {
      final r = await _dio.post('admin/update_status.php', data: {'id': id, 'status': status});
      return r.data is Map ? Map<String,dynamic>.from(r.data) : {"status":0, "message":"Invalid response"};
    } catch (e) {
      return {"status":0, "message": e.toString()};
    }
  }

  // Check CNIC duplication (stub until API endpoint is finalized)
  Future<Map<String,dynamic>> checkCnicDuplication(String cnic) async {
    try {
      // If a dedicated endpoint exists, replace 'check_cnic.php' accordingly.
      final r = await _dio.get('check_cnic.php', queryParameters: {'cnic': cnic});
      if (r.data is Map) {
        return Map<String, dynamic>.from(r.data);
      }
      return {'exists': false};
    } catch (e) {
      // Fail-safe: assume not duplicate when network error
      return {'exists': false, 'error': e.toString()};
    }
  }
}
