// lib/screens/admin_subject_management.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

class AdminSubjectManagement extends StatefulWidget {
  final int institutionId;

  const AdminSubjectManagement({Key? key, required this.institutionId}) : super(key: key);

  @override
  _AdminSubjectManagementState createState() => _AdminSubjectManagementState();
}

class _AdminSubjectManagementState extends State<AdminSubjectManagement> {
  List<Map<String, dynamic>> branches = [];
  List<Map<String, dynamic>> semesters = [];
  List<Map<String, dynamic>> subjects = [];
  int? selectedBranchId;
  int? selectedSemesterId;
  bool isLoadingBranches = true;
  bool isLoadingSemesters = false;
  bool isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => isLoadingBranches = true);
    try {
      final branchesData = await ApiService.getBranches(widget.institutionId);
      setState(() {
        branches = List<Map<String, dynamic>>.from(branchesData);
        isLoadingBranches = false;
      });
    } catch (e) {
      setState(() => isLoadingBranches = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading branches: $e')),
      );
    }
  }

  Future<void> _loadSemesters(int branchId) async {
    setState(() => isLoadingSemesters = true);
    try {
      final semestersData = await ApiService.getSemesters(widget.institutionId, branchId);
      setState(() {
        semesters = List<Map<String, dynamic>>.from(semestersData);
        isLoadingSemesters = false;
        selectedSemesterId = null;
        subjects = [];
      });
    } catch (e) {
      setState(() => isLoadingSemesters = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading semesters: $e')),
      );
    }
  }

  Future<void> _loadSubjects(int semesterId) async {
    setState(() => isLoadingSubjects = true);
    try {
      final subjectsData = await ApiService.getSubjects(widget.institutionId, semesterId);
      setState(() {
        subjects = List<Map<String, dynamic>>.from(subjectsData);
        isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => isLoadingSubjects = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subjects: $e')),
      );
    }
  }

  Future<void> _showAddSubjectDialog() async {
    if (selectedSemesterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a semester first')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddSubjectDialog(),
    );

    if (result != null) {
      try {
        await ApiService.createSubject(widget.institutionId, selectedSemesterId!, result);
        _loadSubjects(selectedSemesterId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject created successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating subject: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Management'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Branch and Semester Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Branch Dropdown
                DropdownButtonFormField<int>(
                  value: selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Select Branch',
                    border: OutlineInputBorder(),
                  ),
                  items: branches.map((branch) => DropdownMenuItem<int>(
                    value: branch['id'],
                    child: Text('${branch['name']} (${branch['code']})'))),
                  ).toList(),
                  onChanged: isLoadingBranches ? null : (value) {
                    setState(() {
                      selectedBranchId = value;
                      selectedSemesterId = null;
                      subjects = [];
                    });
                    if (value != null) {
                      _loadSemesters(value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Semester Dropdown
                DropdownButtonFormField<int>(
                  value: selectedSemesterId,
                  decoration: const InputDecoration(
                    labelText: 'Select Semester',
                    border: OutlineInputBorder(),
                  ),
                  items: semesters.map((semester) => DropdownMenuItem<int>(
                    value: semester['id'],
                    child: Text('Semester ${semester['number']} ${semester['name'] ?? ''}'))),
                  ).toList(),
                  onChanged: (isLoadingSemesters || selectedBranchId == null) ? null : (value) {
                    setState(() => selectedSemesterId = value);
                    if (value != null) {
                      _loadSubjects(value);
                    }
                  },
                ),
              ],
            ),
          ),
          // Subjects List
          Expanded(
            child: _buildSubjectsList(),
          ),
        ],
      ),
      floatingActionButton: selectedSemesterId != null
          ? FloatingActionButton(
              onPressed: _showAddSubjectDialog,
              backgroundColor: const Color(0xFF4A69FF),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildSubjectsList() {
    if (selectedSemesterId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Select Branch and Semester', 
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Choose a branch and semester to view subjects',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    if (isLoadingSubjects) {
      return const Center(child: CircularProgressIndicator());
    }

    if (subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No subjects found', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tap + to add a new subject', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.menu_book, color: Colors.white),
            ),
            title: Text(subject['name'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${subject['code'] ?? ''}'),
                if (subject['description'] != null)
                  Text('Description: ${subject['description']}'),
                Text('Credits: ${subject['credits'] ?? 3}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // Handle edit/delete actions
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AddSubjectDialog extends StatefulWidget {
  const AddSubjectDialog({Key? key}) : super(key: key);

  @override
  _AddSubjectDialogState createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<AddSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _credits = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Subject'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter subject name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Subject Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter subject code' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _credits,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3, 4, 5, 6].map((credits) => DropdownMenuItem(
                  value: credits,
                  child: Text('$credits credits'),
                )).toList(),
                onChanged: (value) => setState(() => _credits = value ?? 3),
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
                'name': _nameController.text,
                'code': _codeController.text,
                'description': _descriptionController.text,
                'credits': _credits,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
