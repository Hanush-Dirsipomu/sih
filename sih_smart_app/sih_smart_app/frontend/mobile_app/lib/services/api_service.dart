// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String _baseUrl = "http://10.0.2.2:5000/api";
  static const String _adminUrl = "http://10.0.2.2:5000/api/admin";
  
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  static Future<Map<String, dynamic>> registerInstitution(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register_institution'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(data),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': responseData['message']};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<Map<String, dynamic>> login(String collegeId, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, String>{'college_id': collegeId, 'password': password, 'role': role}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        // Store authentication token
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
        }
        
        // Store user data
        await prefs.setString('user_role', data['role']);
        await prefs.setInt('user_id', data['user_id']);
        
        // Store institution data
        if (data['institution_id'] != null) {
          await prefs.setString('institution_id', data['institution_id'].toString());
        }
        if (data['institution_name'] != null) {
          await prefs.setString('institution_name', data['institution_name']);
        }
        
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to login'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  // ADMIN API FUNCTIONS
  
  // Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats(int institutionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_adminUrl/dashboard/stats'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load dashboard stats');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // User Management
  static Future<List<dynamic>> getUsers(int institutionId, String? role) async {
    try {
      String url = '$_adminUrl/users';
      if (role != null) {
        url += '?role=$role';
      }
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> createUser(int institutionId, Map<String, dynamic> userData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_adminUrl/users'),
        headers: headers,
        body: jsonEncode(userData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUser(int institutionId, int userId, Map<String, dynamic> userData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_adminUrl/users/$userId'),
        headers: headers,
        body: jsonEncode(userData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<void> deleteUser(int institutionId, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_adminUrl/users/$userId'),
        headers: headers,
      );
      
      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // Branch Management
  static Future<List<dynamic>> getBranches(int institutionId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_adminUrl/branches'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load branches');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> createBranch(int institutionId, Map<String, dynamic> branchData) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_adminUrl/branches'),
        headers: headers,
        body: jsonEncode(branchData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create branch');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> updateBranch(int institutionId, int branchId, Map<String, dynamic> branchData) async {
    try {
      final response = await http.put(
        Uri.parse('$_adminUrl/branches/$branchId'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
        body: jsonEncode(branchData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to update branch');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // Semester Management
  static Future<List<dynamic>> getSemesters(int institutionId, int branchId) async {
    try {
      final response = await http.get(
        Uri.parse('$_adminUrl/branches/$branchId/semesters'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load semesters');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> createSemester(int institutionId, int branchId, Map<String, dynamic> semesterData) async {
    try {
      final response = await http.post(
        Uri.parse('$_adminUrl/branches/$branchId/semesters'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
        body: jsonEncode(semesterData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create semester');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // Subject Management
  static Future<List<dynamic>> getSubjects(int institutionId, int semesterId) async {
    try {
      final response = await http.get(
        Uri.parse('$_adminUrl/semesters/$semesterId/subjects'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> createSubject(int institutionId, int semesterId, Map<String, dynamic> subjectData) async {
    try {
      final response = await http.post(
        Uri.parse('$_adminUrl/semesters/$semesterId/subjects'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
        body: jsonEncode(subjectData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create subject');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // Timetable Management
  static Future<List<dynamic>> getClassSchedules(int institutionId, int subjectId) async {
    try {
      final response = await http.get(
        Uri.parse('$_adminUrl/subjects/$subjectId/schedule'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load schedules');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> createClassSchedule(int institutionId, int subjectId, Map<String, dynamic> scheduleData) async {
    try {
      final response = await http.post(
        Uri.parse('$_adminUrl/subjects/$subjectId/schedule'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
        body: jsonEncode(scheduleData),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': responseData};
      } else {
        throw Exception(responseData['error'] ?? 'Failed to create schedule');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  // Student Enrollment
  static Future<void> enrollStudent(int institutionId, int studentId, int semesterId) async {
    try {
      final response = await http.post(
        Uri.parse('$_adminUrl/students/$studentId/enroll'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Institution-ID': institutionId.toString(),
        },
        body: jsonEncode({'semester_id': semesterId}),
      );
      
      if (response.statusCode != 200) {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['error'] ?? 'Failed to enroll student');
      }
    } catch (e) {
      throw Exception('Could not connect to server: $e');
    }
  }

  static Future<Map<String, dynamic>> saveStudentProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('$_baseUrl/student/$userId/profile'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(profileData),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to save profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<Map<String, dynamic>> getSmartRoutine() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception('User not logged in');
      
      final response = await http.get(Uri.parse('$_baseUrl/student/$userId/smart_routine'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load routine');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<dynamic>> getTeacherTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception('User not logged in');
      final response = await http.get(Uri.parse('$_baseUrl/teacher/$userId/timetable/today'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load timetable');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  static Future<List<dynamic>> getClassRoster(int classId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/class/$classId/roster'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load class roster');
      }
    } catch (e) {
      throw Exception('Error fetching roster: $e');
    }
  }

  static Future<List<dynamic>> getAttendanceRecord(int classId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/class/$classId/attendance'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load attendance record');
      }
    } catch (e) {
      throw Exception('Error fetching attendance record: $e');
    }
  }

  static Future<Map<String, dynamic>> markAttendance(XFile imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/mark_attendance'));
      request.files.add(await http.MultipartFile.fromPath('attendance_photo', imageFile.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(responseData)};
      } else {
        final errorBody = jsonDecode(responseData);
        return {'success': false, 'message': 'Server error: ${errorBody['message'] ?? 'Unknown error'}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  static Future<Map<String, dynamic>> saveAttendance(int classId, Map<String, bool> attendanceData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/save_attendance'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(<String, dynamic>{
          'class_id': classId,
          'attendance': attendanceData,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to save attendance'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Could not connect to server'};
    }
  }

  // NEW ANALYTICS ENDPOINTS
  
  /// Get student attendance summary with 75% threshold warnings
  static Future<Map<String, dynamic>> getStudentAttendanceSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception('User not logged in');
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/student/$userId/attendance/summary'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load attendance summary');
      }
    } catch (e) {
      throw Exception('Error loading attendance: $e');
    }
  }
  
  /// Get teacher's semester overview with all student attendance data
  static Future<Map<String, dynamic>> getTeacherSemesterOverview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception('User not logged in');
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/teacher/$userId/semester/overview'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load semester overview');
      }
    } catch (e) {
      throw Exception('Error loading semester data: $e');
    }
  }
  
  /// Get detailed attendance history for a specific class
  static Future<Map<String, dynamic>> getClassAttendanceHistory(int classId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/class/$classId/attendance/history'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load attendance history');
      }
    } catch (e) {
      throw Exception('Error loading attendance history: $e');
    }
  }
}
