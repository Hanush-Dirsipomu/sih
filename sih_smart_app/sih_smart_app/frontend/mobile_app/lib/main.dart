// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/screens/admin_main_dashboard.dart';
import 'package:mobile_app/screens/enhanced_login_screen.dart';
import 'package:mobile_app/screens/student_dashboard.dart';
import 'package:mobile_app/screens/teacher_dashboard.dart';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Map<String, String?>?> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role');
    if (userRole == null) return null;
    
    return {
      'user_role': userRole,
      'institution_id': prefs.getString('institution_id'),
      'institution_name': prefs.getString('institution_name'),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    return MaterialApp(
      title: 'Smart Curriculum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<Map<String, String?>?>(
        future: _getInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!;
            final role = userData['user_role'];
            
            if (role == 'admin') {
              return AdminMainDashboard(
                institutionId: int.tryParse(userData['institution_id'] ?? '0') ?? 0,
                institutionName: userData['institution_name'] ?? 'Institution',
              );
            }
            if (role == 'teacher') return const TeacherDashboard();
            if (role == 'student') return const StudentDashboard();
          }
          return const EnhancedLoginScreen();
        },
      ),
    );
  }
}