import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/academic_models.dart';
import '../../widgets/confirm_dialog.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeacherProvider>(context, listen: false).fetchTeachers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTeacherDialog({TeacherModel? teacher}) {
    final nameCtrl = TextEditingController(text: teacher?.name ?? '');
    final emailCtrl = TextEditingController(text: teacher?.email ?? '');
    final contactCtrl = TextEditingController(text: teacher?.contact ?? '');
    final qualCtrl = TextEditingController(text: teacher?.qualification ?? 'M.Sc. B.Ed.');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(teacher != null ? 'Edit Teacher' : 'Add Teacher'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Teacher Name *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
              ),
              TextFormField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone *'),
                validator: (v) => v == null || v.length < 10 ? 'At least 10 digits' : null,
              ),
              TextFormField(
                controller: qualCtrl,
                decoration: const InputDecoration(labelText: 'Qualification *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Qualification required' : null,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final data = {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'contact': contactCtrl.text.trim(),
                  'qualification': qualCtrl.text.trim(),
                };
                final tp = Provider.of<TeacherProvider>(context, listen: false);
                final success = teacher != null ? await tp.updateTeacher(teacher.id, data) : await tp.createTeacher(data);
                if (mounted) {
                  if (success) {
                    Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
                  }
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacherProvider = Provider.of<TeacherProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teacher Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage faculty directory, qualifications, and subject assignments',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (auth.isAdmin)
                    ElevatedButton.icon(
                      onPressed: () => _showTeacherDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Teacher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Toolbar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 320,
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search teacher name, contact...',
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.cardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        isDense: true,
                      ),
                      onSubmitted: (val) => teacherProvider.setSearchQuery(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => teacherProvider.setSearchQuery(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Search', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Table
            if (teacherProvider.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (teacherProvider.teachers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No teachers found.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  columns: const [
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Qualification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: teacherProvider.teachers.map((teacher) {
                    final subjectNames = teacher.subjects.isNotEmpty
                        ? teacher.subjects.map((s) => s.name).join(', ')
                        : 'Unassigned';

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  teacher.name.isNotEmpty ? teacher.name.substring(0, 1) : 'T',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        DataCell(Text(teacher.contact, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(subjectNames, style: const TextStyle(fontSize: 12, color: AppColors.primary))),
                        DataCell(Text(teacher.qualification, style: const TextStyle(fontSize: 12))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              teacher.status,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (auth.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  tooltip: 'Edit Teacher',
                                  onPressed: () => _showTeacherDialog(teacher: teacher),
                                ),
                              if (auth.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                  tooltip: 'Delete Teacher',
                                  onPressed: () async {
                                    final confirmed = await ConfirmDialog.show(
                                      context,
                                      title: 'Delete Teacher',
                                      message: 'Are you sure you want to remove ${teacher.name}? All assigned subjects will be unlinked.',
                                    );
                                    if (confirmed) {
                                      final deleted = await teacherProvider.deleteTeacher(teacher.id);
                                      if (deleted && context.mounted) {
                                        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
                                      }
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
