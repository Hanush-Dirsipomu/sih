import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AdminMainDashboard extends StatelessWidget {
  final int institutionId;
  final String institutionName;

  const AdminMainDashboard({
    super.key, 
    required this.institutionId, 
    required this.institutionName
  });

  Future<void> _handleBulkUpload(BuildContext context, String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      try {
        final response = await ApiService.uploadCsv(file, type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success: Created ${response['created']}, Updated ${response['updated']}")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload Failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(institutionName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Super Admin Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildUploadCard(context, "Import Students (Batch/Section)", "students"),
            _buildUploadCard(context, "Import Teachers", "teachers"),
            _buildUploadCard(context, "Import Timetable", "timetable"),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, String title, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.file_upload, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _handleBulkUpload(context, type),
      ),
    );
  }
}