// lib/screens/teacher_semester_overview.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/components/custom_loading_indicator.dart';
import 'package:mobile_app/services/api_service.dart';

class TeacherSemesterOverview extends StatefulWidget {
  const TeacherSemesterOverview({Key? key}) : super(key: key);

  @override
  _TeacherSemesterOverviewState createState() => _TeacherSemesterOverviewState();
}

class _TeacherSemesterOverviewState extends State<TeacherSemesterOverview> {
  late Future<Map<String, dynamic>> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = ApiService.getTeacherSemesterOverview();
  }

  Future<void> _refreshOverview() async {
    setState(() {
      _overviewFuture = ApiService.getTeacherSemesterOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Overview'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOverview,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOverview,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CustomLoadingIndicator();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return _buildEmptyState();
            }

            final data = snapshot.data!;
            final subjects = List<Map<String, dynamic>>.from(data['subjects'] ?? []);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildSummaryCards(subjects),
                  const SizedBox(height: 16),
                  _buildSubjectsList(subjects),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<Map<String, dynamic>> subjects) {
    int totalStudents = 0;
    double totalAttendance = 0.0;
    int totalClasses = 0;

    for (final subject in subjects) {
      final students = List<Map<String, dynamic>>.from(subject['students'] ?? []);
      totalStudents += students.length;
      totalAttendance += subject['average_attendance'] ?? 0.0;
      totalClasses += 1;
    }

    final averageAttendance = totalClasses > 0 ? totalAttendance / totalClasses : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Students',
              value: totalStudents.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Subjects Teaching',
              value: subjects.length.toString(),
              icon: Icons.book,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Avg. Attendance',
              value: '${averageAttendance.toStringAsFixed(1)}%',
              icon: Icons.analytics,
              color: averageAttendance >= 75 ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList(List<Map<String, dynamic>> subjects) {
    if (subjects.isEmpty) {
      return _buildEmptySubjects();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Subjects',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return _buildSubjectCard(subjects[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final averageAttendance = subject['average_attendance'] ?? 0.0;
    final totalStudents = subject['total_students'] ?? 0;
    final students = List<Map<String, dynamic>>.from(subject['students'] ?? []);
    
    Color attendanceColor = averageAttendance >= 85 ? Colors.green :
                          averageAttendance >= 75 ? Colors.blue :
                          averageAttendance >= 65 ? Colors.orange : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject['subject_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subject['subject_code'] ?? '',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room: ${subject['room'] ?? 'TBA'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getDayName(subject['day_of_week'] ?? 0)} ${subject['start_time']}-${subject['end_time']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$totalStudents', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: attendanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: attendanceColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${averageAttendance.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: attendanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          _buildStudentList(students),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAttendanceHistory(subject),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('View Class History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A69FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return const Text('No students enrolled');
    }

    // Sort students by attendance percentage (lowest first)
    students.sort((a, b) => (a['percentage'] ?? 0.0).compareTo(b['percentage'] ?? 0.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Student Attendance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final percentage = student['percentage'] ?? 0.0;
              Color statusColor = percentage >= 85 ? Colors.green :
                                percentage >= 75 ? Colors.blue :
                                percentage >= 65 ? Colors.orange : Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    radius: 16,
                    child: Text(
                      student['student_name']?.substring(0, 1).toUpperCase() ?? 'S',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    student['student_name'] ?? '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    student['college_id'] ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${student['attended_classes']}/${student['total_classes']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAttendanceHistory(Map<String, dynamic> subject) async {
    try {
      final classId = subject['class_schedule_id'];
      final history = await ApiService.getClassAttendanceHistory(classId);
      
      if (!mounted) return;
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildHistoryBottomSheet(subject, history),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
    }
  }

  Widget _buildHistoryBottomSheet(Map<String, dynamic> subject, Map<String, dynamic> historyData) {
    final history = List<Map<String, dynamic>>.from(historyData['history'] ?? []);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subject['subject_name'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No attendance history available'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index];
                  return _buildHistoryTile(record);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> record) {
    final date = DateTime.parse(record['date']);
    final presentCount = record['present_count'] ?? 0;
    final totalCount = record['total_students'] ?? 0;
    final percentage = record['attendance_percentage'] ?? 0.0;

    Color statusColor = percentage >= 75 ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('$presentCount/$totalCount present (${percentage.toStringAsFixed(1)}%)'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Details:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...List<Map<String, dynamic>>.from(record['students'] ?? [])
                    .map((student) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            student['status'] == 'present' ? Icons.check_circle : Icons.cancel,
                            color: student['status'] == 'present' ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              student['student_name'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            student['college_id'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek % 7];
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshOverview,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No Teaching Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('You are not assigned to teach any subjects yet.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubjects() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.subject_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No subjects assigned',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 4),
            Text(
              'Contact your admin to get subject assignments',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}