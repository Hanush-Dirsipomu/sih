import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your machine's IP for physical devices
  static const String baseUrl = "http://10.0.2.2:5000/api";

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Updated Login to handle College ID and new Token structure
  static Future<Map<String, dynamic>> login(String collegeId, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"college_id": collegeId, "password": password}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user_role', data['role']);
      await prefs.setString('user_id', data['user_id'].toString());
      await prefs.setString('institution_name', data['institution_name'] ?? "");
    }
    return data;
  }

  // Super Admin Bulk Upload Service
  static Future<Map<String, dynamic>> uploadCsv(File file, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/admin/upload"));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['type'] = type;
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}