import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';

class AttendanceActionScreen extends StatefulWidget {
  final int classId;
  const AttendanceActionScreen({super.key, required this.classId});

  @override
  _AttendanceActionScreenState createState() => _AttendanceActionScreenState();
}

class _AttendanceActionScreenState extends State<AttendanceActionScreen> {
  bool _isLoading = false;

  Future<void> _takeAttendancePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        // Updated backend route identifies students by College ID from sample folders
        final result = await ApiService.markAttendance(File(image.path));
        
        // Navigate to result screen with the list of present College IDs
        Navigator.pushNamed(context, '/attendance-results', arguments: {
          'class_id': widget.classId,
          'present_ids': result['present_college_ids'],
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator()
          : ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture Classroom Photo"),
              onPressed: _takeAttendancePhoto,
            ),
      ),
    );
  }
}