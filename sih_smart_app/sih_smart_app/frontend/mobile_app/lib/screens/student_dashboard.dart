// lib/screens/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_loading_indicator.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/student_attendance_dashboard.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<Map<String, dynamic>> _routineFuture;

  @override
  void initState() {
    super.initState();
    _routineFuture = ApiService.getSmartRoutine();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
  
  Future<void> _refreshRoutine() async {
    setState(() {
      _routineFuture = ApiService.getSmartRoutine();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Routine'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentAttendanceDashboard(),
                ),
              );
            },
            tooltip: 'View Attendance',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRoutine,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _routineFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!['routine'] == null || (snapshot.data!['routine'] as List).isEmpty) {
              return const Center(child: Text('No routine available for today.'));
            }
            
            final routineData = snapshot.data!;
            final routine = routineData['routine'] as List;
            final alerts = routineData['alerts'] as List? ?? [];
            final lowAttendanceSubjects = routineData['low_attendance_subjects'] as List? ?? [];
            
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, routineData['branch'], routineData['semester']),
                ),
                if (alerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildAlertsSection(alerts),
                  ),
                if (lowAttendanceSubjects.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildAttendanceWarning(lowAttendanceSubjects),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildTimelineTile(
                        context,
                        routine[index],
                        isFirst: index == 0,
                        isLast: index == routine.length - 1
                      );
                    },
                    childCount: routine.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, String branch, String semester) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(branch, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(semester, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimelineTile(BuildContext context, Map<String, dynamic> event, {bool isFirst = false, bool isLast = false}) {
    final bool isClass = event['type'] == 'class';
    final String priority = event['priority'] ?? 'medium';
    final theme = Theme.of(context);
    
    Color eventColor = isClass ? const Color(0xFF4A69FF) : 
                      (priority == 'high' ? Colors.red : Colors.orange);
    IconData eventIcon = isClass ? Icons.school_outlined : 
                         (priority == 'high' ? Icons.priority_high : Icons.lightbulb_outline);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: eventColor.withOpacity(0.1),
                    border: Border.all(color: eventColor, width: 2),
                  ),
                  child: Icon(eventIcon, size: 20, color: eventColor),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.grey[300])),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    event['time'] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: eventColor,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 4, bottom: 20, right: 16),
                  elevation: priority == 'high' ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: priority == 'high' 
                      ? BorderSide(color: eventColor.withOpacity(0.3), width: 1)
                      : BorderSide.none,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: priority == 'high' 
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [eventColor.withOpacity(0.05), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        )
                      : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isClass) ..[
                              Icon(Icons.room_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                event['details'] ?? 'Room: TBA',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ] else ..[
                              Icon(Icons.auto_awesome, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'AI Recommendation',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                            if (priority == 'high') ..[
                              const Spacer(),
                              Chip(
                                label: const Text('Priority', style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.red.withOpacity(0.1),
                                side: BorderSide(color: Colors.red.withOpacity(0.3)),
                              ),
                            ],
                          ],
                        ),
                        if (isClass && event['subject_code'] != null) ..[
                          const SizedBox(height: 4),
                          Text(
                            event['subject_code'],
                            style: TextStyle(
                              color: eventColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAlertsSection(List<dynamic> alerts) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        color: Colors.orange.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notification_important, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Alerts',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts.map((alert) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert['message'] ?? '',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttendanceWarning(List<dynamic> subjects) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Warning',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Low attendance in: ${subjects.join(', ')}',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentAttendanceDashboard(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics, size: 18),
                      label: const Text('View Details', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}