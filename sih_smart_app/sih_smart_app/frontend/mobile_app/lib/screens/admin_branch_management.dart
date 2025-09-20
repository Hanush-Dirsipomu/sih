// lib/screens/admin_branch_management.dart
import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

class AdminBranchManagement extends StatefulWidget {
  final int institutionId;

  const AdminBranchManagement({Key? key, required this.institutionId}) : super(key: key);

  @override
  _AdminBranchManagementState createState() => _AdminBranchManagementState();
}

class _AdminBranchManagementState extends State<AdminBranchManagement> {
  List<Map<String, dynamic>> branches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => isLoading = true);
    try {
      final branchesData = await ApiService.getBranches(widget.institutionId);
      setState(() {
        branches = List<Map<String, dynamic>>.from(branchesData);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading branches: $e')),
      );
    }
  }

  Future<void> _showAddBranchDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddBranchDialog(),
    );

    if (result != null) {
      try {
        await ApiService.createBranch(widget.institutionId, result);
        _loadBranches();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Branch created successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating branch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Management'),
        backgroundColor: const Color(0xFF4A69FF),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : branches.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No branches found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Tap + to add a new branch', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: branches.length,
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.account_tree, color: Colors.white),
                        ),
                        title: Text(branch['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${branch['code'] ?? ''}'),
                            if (branch['description'] != null)
                              Text('Description: ${branch['description']}'),
                            Text('Duration: ${branch['duration_years'] ?? 4} years'),
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBranchDialog,
        backgroundColor: const Color(0xFF4A69FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddBranchDialog extends StatefulWidget {
  const AddBranchDialog({Key? key}) : super(key: key);

  @override
  _AddBranchDialogState createState() => _AddBranchDialogState();
}

class _AddBranchDialogState extends State<AddBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _durationYears = 4;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Branch'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter branch name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Branch Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please enter branch code' : null,
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
                value: _durationYears,
                decoration: const InputDecoration(
                  labelText: 'Duration (Years)',
                  border: OutlineInputBorder(),
                ),
                items: [2, 3, 4, 5].map((years) => DropdownMenuItem(
                  value: years,
                  child: Text('$years years'),
                )).toList(),
                onChanged: (value) => setState(() => _durationYears = value ?? 4),
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
                'duration_years': _durationYears,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}