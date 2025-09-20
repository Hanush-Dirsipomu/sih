// lib/screens/admin_main_dashboard.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/screens/admin_user_management.dart';
import 'package:mobile_app/screens/admin_branch_management.dart';
import 'package:mobile_app/screens/admin_subject_management.dart';
import 'package:mobile_app/screens/admin_timetable_management.dart';
import 'package:mobile_app/screens/admin_enrollment_management.dart';

class AdminMainDashboard extends StatefulWidget {
  final int institutionId;
  final String institutionName;

  const AdminMainDashboard({
    Key? key,
    required this.institutionId,
    required this.institutionName,
  }) : super(key: key);

  @override
  _AdminMainDashboardState createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> {
  Map<String, dynamic> dashboardStats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await ApiService.getDashboardStats(widget.institutionId);
      setState(() {
        dashboardStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.institutionName} - Admin'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDashboardStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Stats Cards
                    const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    
                    const SizedBox(height: 30),
                    
                    // Management Options
                    const Text(
                      'Institution Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildManagementOptions(),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {
        'title': 'Total Students',
        'value': dashboardStats['total_students']?.toString() ?? '0',
        'icon': Icons.school,
        'color': Colors.blue,
      },
      {
        'title': 'Total Teachers',
        'value': dashboardStats['total_teachers']?.toString() ?? '0',
        'icon': Icons.person,
        'color': Colors.green,
      },
      {
        'title': 'Branches',
        'value': dashboardStats['total_branches']?.toString() ?? '0',
        'icon': Icons.category,
        'color': Colors.orange,
      },
      {
        'title': 'Subjects',
        'value': dashboardStats['total_subjects']?.toString() ?? '0',
        'icon': Icons.book,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (stat['color'] as Color).withOpacity(0.1),
                  (stat['color'] as Color).withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManagementOptions() {
    final options = [
      {
        'title': 'User Management',
        'subtitle': 'Manage students and teachers',
        'icon': Icons.people,
        'color': Colors.blue,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminUserManagement(institutionId: widget.institutionId),
          ),
        ),
      },
      {
        'title': 'Branch Management',
        'subtitle': 'Create and manage branches',
        'icon': Icons.account_tree,
        'color': Colors.green,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminBranchManagement(institutionId: widget.institutionId),
          ),
        ),
      },
      {
        'title': 'Subject Management',
        'subtitle': 'Manage subjects and curriculum',
        'icon': Icons.menu_book,
        'color': Colors.orange,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminSubjectManagement(institutionId: widget.institutionId),
          ),
        ),
      },
      {
        'title': 'Timetable Management',
        'subtitle': 'Create class schedules',
        'icon': Icons.schedule,
        'color': Colors.purple,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminTimetableManagement(institutionId: widget.institutionId),
          ),
        ),
      },
      {
        'title': 'Student Enrollment',
        'subtitle': 'Enroll students in semesters',
        'icon': Icons.assignment_ind,
        'color': Colors.teal,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminEnrollmentManagement(institutionId: widget.institutionId),
          ),
        ),
      },
    ];

    return Column(
      children: options.map((option) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (option['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option['icon'] as IconData,
                color: option['color'] as Color,
                size: 26,
              ),
            ),
            title: Text(
              option['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              option['subtitle'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
            onTap: option['onTap'] as VoidCallback,
          ),
        );
      }).toList(),
    );
  }
}