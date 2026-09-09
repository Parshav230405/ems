import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_academic_provider.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String? _filterClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ac = Provider.of<AcademicProvider>(context, listen: false);
      ac.fetchClasses();
      ac.fetchSubjects();
      Provider.of<TeacherProvider>(context, listen: false).fetchTeachers();
    });
  }

  void _showAddSubjectDialog() {
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final teachers = Provider.of<TeacherProvider>(context, listen: false).teachers;
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String? classId = academic.classes.isNotEmpty ? academic.classes.first.id : null;
    String? teacherId = teachers.isNotEmpty ? teachers.first.id : null;
    final formKey = GlobalKey<FormState>();

    Widget buildFormField({
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
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.accent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
            validator: validator,
          ),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Course / Subject',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Configure subject title, course code, and faculty assignment', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const Divider(height: 24, color: AppColors.cardBorder),
                    buildFormField(
                      label: 'Subject Name *',
                      controller: nameCtrl,
                      hint: 'e.g. Mathematics, Science',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Subject name required' : null,
                    ),
                    const SizedBox(height: 14),
                    buildFormField(
                      label: 'Subject Code',
                      controller: codeCtrl,
                      hint: 'e.g. MTH10, SCI10',
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Class *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: classId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            isDense: true,
                          ),
                          items: academic.classes.map((c) => DropdownMenuItem(value: c.id, child: Text('Class ${c.name} - ${c.division}'))).toList(),
                          onChanged: (v) => setState(() => classId = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign Faculty (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: teacherId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('None (Unassigned)')),
                            ...teachers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                          ],
                          onChanged: (v) => setState(() => teacherId = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate() && classId != null) {
                              await academic.createSubject(nameCtrl.text.trim(), codeCtrl.text.trim(), classId!, teacherId);
                              if (mounted) Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add Subject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Course & Subject Management',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Assign subject courses to classes and allocate faculty teachers',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (auth.isAdmin)
                    ElevatedButton.icon(
                      onPressed: _showAddSubjectDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Subject'),
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

            // Class Filter
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 220,
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: _filterClassId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        isDense: true,
                      ),
                      hint: const Text('All Classes', style: TextStyle(fontSize: 12)),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Classes', style: TextStyle(fontSize: 12))),
                        ...academic.classes.map((c) => DropdownMenuItem(value: c.id, child: Text('Class ${c.name}-${c.division}', style: const TextStyle(fontSize: 12)))),
                      ],
                      onChanged: (val) {
                        setState(() => _filterClassId = val);
                        academic.fetchSubjects(classId: val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (academic.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (academic.subjects.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No subjects found.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Subject Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Subject Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Assigned Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Assigned Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: academic.subjects.map((sub) {
                  return DataRow(
                    cells: [
                      DataCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      DataCell(Text(sub.code ?? 'N/A', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                      DataCell(Text(sub.className ?? '', style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 16, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(sub.teacherName ?? 'Unassigned', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      DataCell(
                        auth.isAdmin
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                tooltip: 'Delete Subject',
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete Subject'),
                                      content: Text('Are you sure you want to delete ${sub.name}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await academic.deleteSubject(sub.id, classId: _filterClassId);
                                  }
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
