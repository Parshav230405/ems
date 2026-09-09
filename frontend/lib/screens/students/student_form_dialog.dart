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

  Future<void> _selectDob() async {
    DateTime initialDate = DateTime(2012, 5, 15);
    final current = _dobController.text.trim();
    if (current.isNotEmpty) {
      final parts = current.split(RegExp(r'[-/]'));
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) initialDate = DateTime(y, m, d);
        } else if (parts[2].length == 4) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) initialDate = DateTime(y, m, d);
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showQuickCreateClassDialog() {
    final nameCtrl = TextEditingController(text: '10');
    final divCtrl = TextEditingController(text: 'A');
    final yearCtrl = TextEditingController(text: '2025-2026');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Class & Division'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class / Grade * (e.g. 10)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Class required' : null,
              ),
              TextFormField(
                controller: divCtrl,
                decoration: const InputDecoration(labelText: 'Division / Section * (e.g. A)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Division required' : null,
              ),
              TextFormField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Academic Year * (e.g. 2025-2026)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Year required' : null,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final created = await Provider.of<AcademicProvider>(context, listen: false).createClass(
                  nameCtrl.text.trim(),
                  divCtrl.text.trim(),
                  yearCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  if (created) {
                    await Provider.of<AcademicProvider>(context, listen: false).fetchClasses();
                    final updatedClasses = Provider.of<AcademicProvider>(context, listen: false).classes;
                    if (updatedClasses.isNotEmpty) {
                      setState(() {
                        _selectedClassId = updatedClasses.last.id;
                      });
                    }
                  }
                }
              }
            },
            child: const Text('Create Class'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class before saving student'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final rawEmail = _parentEmailController.text.trim();
    if (rawEmail.isNotEmpty && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(rawEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address (e.g. parent@example.com) or leave it blank'), backgroundColor: AppColors.danger),
      );
      return;
    }

    String rawDob = _dobController.text.trim();
    final ddmmyyyy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(rawDob);
    if (ddmmyyyy != null) {
      final day = ddmmyyyy.group(1)!.padLeft(2, '0');
      final month = ddmmyyyy.group(2)!.padLeft(2, '0');
      final year = ddmmyyyy.group(3)!;
      rawDob = '$year-$month-$day';
    }

    setState(() => _isSubmitting = true);

    final data = {
      'name': _nameController.text.trim(),
      if (_admissionNoController.text.trim().isNotEmpty)
        'admissionNumber': _admissionNoController.text.trim(),
      'dob': rawDob,
      'gender': _gender,
      'classId': _selectedClassId,
      'parentName': _parentNameController.text.trim(),
      'parentContact': _parentContactController.text.trim(),
      if (rawEmail.isNotEmpty)
        'parentEmail': rawEmail,
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
                        if (classes.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'No classes found for this school yet. Please create a class first.',
                                    style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showQuickCreateClassDialog,
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add Class', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                                hint: 'YYYY-MM-DD or DD/MM/YYYY',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                                  onPressed: _selectDob,
                                  tooltip: 'Pick date from calendar',
                                ),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Class *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      if (classes.isNotEmpty)
                                        InkWell(
                                          onTap: _showQuickCreateClassDialog,
                                          child: const Text(
                                            '+ Add Class',
                                            style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                    ],
                                  ),
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
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
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
