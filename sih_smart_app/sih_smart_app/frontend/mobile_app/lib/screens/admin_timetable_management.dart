// lib/screens/admin_timetable_management.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

class AdminTimetableManagement extends StatefulWidget {
  final int institutionId;

  const AdminTimetableManagement({Key? key, required this.institutionId}) : super(key: key);

  @override
  _AdminTimetableManagementState createState() => _AdminTimetableManagementState();
}

class _AdminTimetableManagementState extends State<AdminTimetableManagement> {
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> semesters = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> teachers = [];
  int? selectedBranchId;
  int? selectedSemesterId;
  int? selectedSubjectId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final branchesData = await ApiService.getBranches(widget.institutionId);
      final teachersData = await ApiService.getUsers(widget.institutionId, 'teacher');
      
      setState(() {
        branches = List<Map<String, dynamic>>.from(branchesData);
        teachers = List<Map<String, dynamic>>.from(teachersData);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _showAddScheduleDialog() async {
    if (selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddScheduleDialog(teachers: teachers),
    );

    if (result != null) {
      try {
        await ApiService.createClassSchedule(widget.institutionId, selectedSubjectId!, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule created successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Timetable Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Select subjects from Subject Management to create schedules', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class AddScheduleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;

  const AddScheduleDialog({Key? key, required this.teachers}) : super(key: key);

  @override
  _AddScheduleDialogState createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  int? _selectedTeacherId;
  int _dayOfWeek = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Class Schedule'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Teacher Dropdown
              DropdownButtonFormField<int>(
                value: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Select Teacher',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Please select a teacher' : null,
                items: widget.teachers.map((teacher) => DropdownMenuItem<int>(
                  value: teacher['id'],
                  child: Text(teacher['name'] ?? ''),
                )).toList(),
                onChanged: (value) => setState(() => _selectedTeacherId = value),
              ),
              const SizedBox(height: 16),
              // Day Dropdown
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: dayNames.asMap().entries.map((entry) => DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value),
                )).toList(),
                onChanged: (value) => setState(() => _dayOfWeek = value ?? 0),
              ),
              const SizedBox(height: 16),
              // Room
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.pop(context, {
                'teacher_id': _selectedTeacherId,
                'day_of_week': _dayOfWeek,
                'start_time': '09:00',
                'end_time': '10:00',
                'room': _roomController.text.isEmpty ? null : _roomController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
