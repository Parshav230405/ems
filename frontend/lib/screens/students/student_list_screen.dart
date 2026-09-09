import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/url_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/confirm_dialog.dart';
import '../certificates/certificate_generator_screen.dart';
import 'student_form_dialog.dart';
import 'student_profile_dialog.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudents();
      Provider.of<AcademicProvider>(context, listen: false).fetchClasses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);
    final academicProvider = Provider.of<AcademicProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
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
                          'Student Management',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage student records, admission details, and profiles',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => StudentFormDialog.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('+ Add Student'),
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

              // Search & Filter Toolbar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search bar
                    SizedBox(
                      width: 280,
                      height: 40,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, adm no...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        onSubmitted: (val) => studentProvider.setSearchQuery(val),
                      ),
                    ),

                    // Class Dropdown Filter
                    SizedBox(
                      width: 180,
                      height: 40,
                      child: DropdownButtonFormField<String>(
                        value: studentProvider.selectedClassId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        hint: const Text('All Classes', style: TextStyle(fontSize: 12)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes', style: TextStyle(fontSize: 12))),
                          ...academicProvider.classes.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('Class ${c.name}-${c.division}', style: const TextStyle(fontSize: 12)),
                              )),
                        ],
                        onChanged: (val) => studentProvider.setClassFilter(val),
                      ),
                    ),

                    // Status Dropdown Filter
                    SizedBox(
                      width: 150,
                      height: 40,
                      child: DropdownButtonFormField<String>(
                        value: studentProvider.selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          isDense: true,
                        ),
                        hint: const Text('All Status', style: TextStyle(fontSize: 12)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Status', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Active', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (val) => studentProvider.setStatusFilter(val),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () => studentProvider.setSearchQuery(_searchController.text),
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

              // Data Table
              if (studentProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (studentProvider.students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('No student records found matching the criteria.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Admission No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Parent Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Parent Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: studentProvider.students.map((student) {
                      return DataRow(
                        cells: [
                          DataCell(Text(student.admissionNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          DataCell(Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          DataCell(Text(student.classDivision, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(student.parentName, style: const TextStyle(fontSize: 12))),
                          DataCell(Text(student.parentContact, style: const TextStyle(fontSize: 12))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: student.status == 'ACTIVE' ? AppColors.successBg : AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                student.status == 'ACTIVE' ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: student.status == 'ACTIVE' ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.accent),
                                  tooltip: 'View Profile',
                                  onPressed: () => StudentProfileDialog.show(context, student.id),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Color(0xFF0284C7)),
                                  tooltip: 'Download Report Card (PDF)',
                                  onPressed: () {
                                    UrlHelper.openUrl('http://localhost:5000/api/reports/student/${student.id}/download');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Downloading Report Card for ${student.name}...'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.workspace_premium_outlined, size: 18, color: Color(0xFFD97706)),
                                  tooltip: 'Issue Certificate',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 750),
                                          child: Stack(
                                            children: [
                                              CertificateGeneratorScreen(initialStudentId: student.id),
                                              Positioned(
                                                top: 12,
                                                right: 12,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close_rounded),
                                                  onPressed: () => Navigator.of(ctx).pop(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  tooltip: 'Edit Student',
                                  onPressed: () => StudentFormDialog.show(context, studentToEdit: student),
                                ),
                                if (auth.isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                    tooltip: 'Delete Student',
                                    onPressed: () async {
                                      final confirmed = await ConfirmDialog.show(
                                        context,
                                        title: 'Delete Student',
                                        message: 'Are you sure you want to delete ${student.name} (${student.admissionNumber})? This action cannot be undone.',
                                      );
                                      if (confirmed) {
                                        final deleted = await studentProvider.deleteStudent(student.id);
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

              const Divider(height: 1, color: AppColors.cardBorder),

              // Pagination Footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${studentProvider.students.length} of ${studentProvider.totalStudents} entries',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: studentProvider.currentPage > 1
                              ? () => studentProvider.fetchStudents(page: studentProvider.currentPage - 1)
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(studentProvider.totalPages, (i) {
                          final pageNum = i + 1;
                          final isCurrent = pageNum == studentProvider.currentPage;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              onPressed: () => studentProvider.fetchStudents(page: pageNum),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrent ? AppColors.accent : Colors.white,
                                foregroundColor: isCurrent ? Colors.white : AppColors.textPrimary,
                                elevation: 0,
                                side: BorderSide(color: isCurrent ? AppColors.accent : AppColors.cardBorder),
                                minimumSize: const Size(32, 32),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(pageNum.toString(), style: const TextStyle(fontSize: 11)),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: studentProvider.currentPage < studentProvider.totalPages
                              ? () => studentProvider.fetchStudents(page: studentProvider.currentPage + 1)
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: AppColors.cardBorder),
                          ),
                          child: const Text('Next', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
