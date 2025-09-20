// lib/screens/admin_timetable_management.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminTimetableManagement extends StatefulWidget {
  const AdminTimetableManagement({Key? key}) : super(key: key);

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
  int institutionId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      institutionId = int.parse(prefs.getString('institution_id') ?? '0');
      
      final branchesData = await ApiService.getBranches(institutionId);
      final teachersData = await ApiService.getUsers(institutionId, 'teacher');
      
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

  Future<void> _loadSemesters(int branchId) async {
    try {
      final semestersData = await ApiService.getSemesters(institutionId, branchId);
      setState(() {
        semesters = List<Map<String, dynamic>>.from(semestersData);
        selectedSemesterId = null;
        subjects = [];
        selectedSubjectId = null;
        schedules = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading semesters: $e')),
      );
    }
  }

  Future<void> _loadSubjects(int semesterId) async {
    try {
      final subjectsData = await ApiService.getSubjects(institutionId, semesterId);
      setState(() {
        subjects = List<Map<String, dynamic>>.from(subjectsData);
        selectedSubjectId = null;
        schedules = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subjects: $e')),
      );
    }
  }

  Future<void> _loadSchedules(int subjectId) async {
    try {
      final schedulesData = await ApiService.getClassSchedules(institutionId, subjectId);
      setState(() {
        schedules = List<Map<String, dynamic>>.from(schedulesData);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading schedules: $e')),
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
        await ApiService.createClassSchedule(institutionId, selectedSubjectId!, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule created successfully!')),
        );
        _loadSchedules(selectedSubjectId!);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Timetable Management'),
          backgroundColor: const Color(0xFF4A69FF),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branch Selection
            const Text('Select Branch:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedBranchId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Select Branch'),
              items: branches.map((branch) => DropdownMenuItem<int>(
                value: branch['id'],
                child: Text('${branch['name']} (${branch['code']})'),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBranchId = value;
                });
                if (value != null) _loadSemesters(value);
              },
            ),
            const SizedBox(height: 16),

            // Semester Selection
            if (semesters.isNotEmpty) ..[
              const Text('Select Semester:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedSemesterId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Select Semester'),
                items: semesters.map((semester) => DropdownMenuItem<int>(
                  value: semester['id'],
                  child: Text(semester['name'] ?? 'Semester ${semester['number']}'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSemesterId = value;
                  });
                  if (value != null) _loadSubjects(value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Subject Selection
            if (subjects.isNotEmpty) ..[
              const Text('Select Subject:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedSubjectId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Select Subject'),
                items: subjects.map((subject) => DropdownMenuItem<int>(
                  value: subject['id'],
                  child: Text('${subject['name']} (${subject['code']})'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSubjectId = value;
                  });
                  if (value != null) _loadSchedules(value);
                },
              ),
              const SizedBox(height: 16),
            ],

            // Schedules List
            if (selectedSubjectId != null) ..[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Class Schedules:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _showAddScheduleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A69FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: schedules.isEmpty
                    ? const Center(child: Text('No schedules found for this subject'))
                    : ListView.builder(
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = schedules[index];
                          final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                '${dayNames[schedule['day_of_week']]} - ${schedule['start_time']} to ${schedule['end_time']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Room: ${schedule['room'] ?? 'Not assigned'}'),
                                  Text('Teacher: ${schedule['teacher_name'] ?? 'Not assigned'}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  // Delete confirmation dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Schedule'),
                                      content: const Text('Are you sure you want to delete this schedule?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            // Delete schedule and refresh
                                            _loadSchedules(selectedSubjectId!);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] else ..[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Select Branch, Semester & Subject', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Choose the subject to manage its class timetable', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
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
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  
  int? _selectedTeacherId;
  int _dayOfWeek = 0;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _startTimeController.text = _formatTimeOfDay(_startTime);
    _endTimeController.text = _formatTimeOfDay(_endTime);
  }

  @override
  void dispose() {
    _roomController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
              
              // Start Time
              TextFormField(
                controller: _startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  border: OutlineInputBorder(),
                  hintText: 'HH:MM',
                ),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null && picked != _startTime) {
                    setState(() {
                      _startTime = picked;
                      _startTimeController.text = _formatTimeOfDay(picked);
                    });
                  }
                },
                validator: (value) => value?.isEmpty == true ? 'Please select start time' : null,
              ),
              const SizedBox(height: 16),
              
              // End Time
              TextFormField(
                controller: _endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  border: OutlineInputBorder(),
                  hintText: 'HH:MM',
                ),
                readOnly: true,
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (picked != null && picked != _endTime) {
                    setState(() {
                      _endTime = picked;
                      _endTimeController.text = _formatTimeOfDay(picked);
                    });
                  }
                },
                validator: (value) {
                  if (value?.isEmpty == true) return 'Please select end time';
                  if (_endTime.hour < _startTime.hour ||
                      (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
                    return 'End time must be after start time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Room
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., CSE-101',
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter a room' : null,
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
                'start_time': _formatTimeOfDay(_startTime),
                'end_time': _formatTimeOfDay(_endTime),
                'room': _roomController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A69FF),
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}
