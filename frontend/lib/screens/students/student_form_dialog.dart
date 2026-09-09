import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/student_provider.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/student_model.dart';

class StudentFormDialog extends StatefulWidget {
  final StudentModel? studentToEdit;

  const StudentFormDialog({super.key, this.studentToEdit});

  static Future<bool?> show(BuildContext context, {StudentModel? studentToEdit}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StudentFormDialog(studentToEdit: studentToEdit),
    );
  }

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _admissionNoController;
  late TextEditingController _dobController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentContactController;
  late TextEditingController _parentEmailController;

  String _gender = 'Male';
  String? _selectedClassId;
  String _status = 'ACTIVE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.studentToEdit;
    _nameController = TextEditingController(text: s?.name ?? '');
    _admissionNoController = TextEditingController(text: s?.admissionNumber ?? '');
    _dobController = TextEditingController(
      text: s?.dob.isNotEmpty == true ? s!.dob.split('T')[0] : '2012-05-15',
    );
    _parentNameController = TextEditingController(text: s?.parentName ?? '');
    _parentContactController = TextEditingController(text: s?.parentContact ?? '');
    _parentEmailController = TextEditingController(text: s?.parentEmail ?? '');

    if (s != null) {
      _gender = s.gender;
      _selectedClassId = s.classId;
      _status = s.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNoController.dispose();
    _dobController.dispose();
    _parentNameController.dispose();
    _parentContactController.dispose();
    _parentEmailController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      if (_admissionNoController.text.trim().isNotEmpty)
        'admissionNumber': _admissionNoController.text.trim(),
      'dob': _dobController.text.trim(),
      'gender': _gender,
      'classId': _selectedClassId,
      'parentName': _parentNameController.text.trim(),
      'parentContact': _parentContactController.text.trim(),
      if (_parentEmailController.text.trim().isNotEmpty)
        'parentEmail': _parentEmailController.text.trim(),
      'status': _status,
    };

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    bool success;

    if (widget.studentToEdit != null) {
      success = await studentProvider.updateStudent(widget.studentToEdit!.id, data);
    } else {
      success = await studentProvider.createStudent(data);
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.studentToEdit != null ? 'Student updated successfully' : 'Student admitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(studentProvider.errorMessage ?? 'Failed to save student'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);
    final classes = academic.classes;
    if (_selectedClassId == null && classes.isNotEmpty) {
      _selectedClassId = classes.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.studentToEdit != null ? 'Edit Student Details' : 'Add Student',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter student details and parent contact information',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Divider(height: 24, color: AppColors.cardBorder),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Information Section
                        const Text(
                          'Personal Information',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Student Name *',
                                controller: _nameController,
                                hint: 'Enter student name',
                                validator: (v) => v == null || v.trim().isEmpty ? 'Student name is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Admission No.',
                                controller: _admissionNoController,
                                hint: 'Auto-generated (e.g. ADM031)',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Date of Birth *',
                                controller: _dobController,
                                hint: 'YYYY-MM-DD',
                                validator: (v) => v == null || v.trim().isEmpty ? 'DOB is required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _gender,
                                    decoration: _inputDecoration('Select gender'),
                                    items: ['Male', 'Female', 'Other']
                                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _gender = v ?? 'Male'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Class *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedClassId,
                                    decoration: _inputDecoration('Select class'),
                                    items: classes
                                        .map((c) => DropdownMenuItem(
                                              value: c.id,
                                              child: Text('Class ${c.name} (Div ${c.division})'),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => _selectedClassId = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _status,
                                    decoration: _inputDecoration('Select status'),
                                    items: ['ACTIVE', 'INACTIVE']
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) => setState(() => _status = v ?? 'ACTIVE'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Parent Information Section
                        const Text(
                          'Parent Information',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),

                        _buildTextField(
                          label: "Parent / Guardian Name *",
                          controller: _parentNameController,
                          hint: "Enter parent or guardian name",
                          validator: (v) => v == null || v.trim().isEmpty ? "Parent name is required" : null,
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Mobile No. *',
                                controller: _parentContactController,
                                hint: '10-digit phone number',
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Contact is required';
                                  if (v.trim().length < 10) return 'At least 10 digits';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Email',
                                controller: _parentEmailController,
                                hint: 'parent@example.com',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 24, color: AppColors.cardBorder),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Student'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }
}
