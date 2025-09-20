// lib/screens/admin_enrollment_management.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

class AdminEnrollmentManagement extends StatefulWidget {
  final int institutionId;

  const AdminEnrollmentManagement({Key? key, required this.institutionId}) : super(key: key);

  @override
  _AdminEnrollmentManagementState createState() => _AdminEnrollmentManagementState();
}

class _AdminEnrollmentManagementState extends State<AdminEnrollmentManagement> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> semesters = [];
  Map<String, dynamic>? selectedStudent;
  int? selectedBranchId;
  int? selectedSemesterId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final studentsData = await ApiService.getUsers(widget.institutionId, 'student');
      final branchesData = await ApiService.getBranches(widget.institutionId);
      
      setState(() {
        students = List<Map<String, dynamic>>.from(studentsData);
        branches = List<Map<String, dynamic>>.from(branchesData);
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
      final semestersData = await ApiService.getSemesters(widget.institutionId, branchId);
      setState(() {
        semesters = List<Map<String, dynamic>>.from(semestersData);
        selectedSemesterId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading semesters: $e')),
      );
    }
  }

  Future<void> _enrollStudent() async {
    if (selectedStudent == null || selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both student and semester')),
      );
      return;
    }

    try {
      await ApiService.enrollStudent(
        widget.institutionId, 
        selectedStudent!['id'], 
        selectedSemesterId!
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student enrolled successfully!')),
      );
      
      // Reset selections
      setState(() {
        selectedStudent = null;
        selectedBranchId = null;
        selectedSemesterId = null;
        semesters = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enrolling student: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Enrollment'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enroll Students in Semesters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a student, choose their branch and semester, then enroll them.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Student Selection
                  const Text(
                    'Select Student',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Map<String, dynamic>>(
                      value: selectedStudent,
                      hint: const Text('Choose a student'),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: students.map((student) => DropdownMenuItem<Map<String, dynamic>>(
                        value: student,
                        child: Text('${student['name']} (${student['college_id']})')),
                      ).toList(),
                      onChanged: (student) {
                        setState(() {
                          selectedStudent = student;
                          selectedBranchId = null;
                          selectedSemesterId = null;
                          semesters = [];
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Branch Selection
                  const Text(
                    'Select Branch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedStudent == null ? Colors.grey.shade300 : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: selectedBranchId,
                      hint: const Text('Choose a branch'),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: selectedStudent == null ? [] : branches.map((branch) => DropdownMenuItem<int>(
                        value: branch['id'],
                        child: Text('${branch['name']} (${branch['code']})')),
                      ).toList(),
                      onChanged: selectedStudent == null ? null : (branchId) {
                        setState(() => selectedBranchId = branchId);
                        if (branchId != null) {
                          _loadSemesters(branchId);
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Semester Selection
                  const Text(
                    'Select Semester',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedBranchId == null ? Colors.grey.shade300 : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<int>(
                      value: selectedSemesterId,
                      hint: const Text('Choose a semester'),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: selectedBranchId == null ? [] : semesters.map((semester) => DropdownMenuItem<int>(
                        value: semester['id'],
                        child: Text('Semester ${semester['number']} ${semester['name'] ?? ''}')),
                      ).toList(),
                      onChanged: selectedBranchId == null ? null : (semesterId) {
                        setState(() => selectedSemesterId = semesterId);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Enroll Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (selectedStudent != null && selectedSemesterId != null) 
                          ? _enrollStudent 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A69FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Enroll Student',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  if (selectedStudent != null) ..[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Student Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Name: ${selectedStudent!['name']}'),
                          Text('College ID: ${selectedStudent!['college_id']}'),
                          if (selectedStudent!['email'] != null)
                            Text('Email: ${selectedStudent!['email']}'),
                          if (selectedBranchId != null) ..[
                            const SizedBox(height: 8),
                            Text('Branch: ${branches.firstWhere((b) => b['id'] == selectedBranchId)['name']}'),
                          ],
                          if (selectedSemesterId != null) ..[
                            Text('Semester: ${semesters.firstWhere((s) => s['id'] == selectedSemesterId)['number']}'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
