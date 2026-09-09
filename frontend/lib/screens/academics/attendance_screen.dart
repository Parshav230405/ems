import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/teacher_academic_provider.dart';
import '../../providers/dashboard_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final academic = Provider.of<AcademicProvider>(context, listen: false);
      await academic.fetchClasses();
      if (academic.classes.isNotEmpty) {
        academic.fetchAttendance();
      }
    });
  }

  void _selectDate(BuildContext context) async {
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: academic.selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) {
      academic.setAttendanceDate(picked);
    }
  }

  void _saveAttendance() async {
    final academic = Provider.of<AcademicProvider>(context, listen: false);
    final success = await academic.saveAttendance();
    if (mounted) {
      if (success) {
        Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Attendance saved successfully!' : 'Failed to save attendance'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final academic = Provider.of<AcademicProvider>(context);
    final dateStr = DateFormat('yyyy-MM-dd').format(academic.selectedDate);

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
                        'Attendance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mark and manage daily student attendance per class',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: academic.isLoading ? null : _saveAttendance,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Save Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.cardBorder),

            // Controls Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Date Picker Button
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.background,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Class Selector
                  SizedBox(
                    width: 200,
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      value: academic.selectedClassId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        isDense: true,
                      ),
                      items: academic.classes.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('Class ${c.name}-${c.division}', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) academic.setAttendanceClass(val);
                      },
                    ),
                  ),

                  const Spacer(),

                  // Quick Action: Mark All Present
                  if (academic.attendanceList.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () {
                        for (int i = 0; i < academic.attendanceList.length; i++) {
                          academic.updateStudentAttendanceStatus(i, 'PRESENT');
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Marked all students as Present'),
                            duration: Duration(seconds: 1),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.success),
                      label: const Text('Mark All Present', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                ],
              ),
            ),

            // Attendance Table
            if (academic.isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (academic.attendanceList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No students found for this class.', style: TextStyle(color: AppColors.textMuted))),
              )
            else
              DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Absent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: List.generate(academic.attendanceList.length, (index) {
                  final student = academic.attendanceList[index];
                  final status = student['status'] ?? 'PRESENT';

                  return DataRow(
                    cells: [
                      DataCell(Text(student['rollNo'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataCell(
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(
                                (student['studentName'] as String).isNotEmpty
                                    ? (student['studentName'] as String).substring(0, 1)
                                    : 'S',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(student['studentName'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                      // Present Radio
                      DataCell(
                        Radio<String>(
                          value: 'PRESENT',
                          groupValue: status,
                          activeColor: AppColors.accent,
                          onChanged: (v) => academic.updateStudentAttendanceStatus(index, v!),
                        ),
                      ),
                      // Absent Radio
                      DataCell(
                        Radio<String>(
                          value: 'ABSENT',
                          groupValue: status,
                          activeColor: AppColors.danger,
                          onChanged: (v) => academic.updateStudentAttendanceStatus(index, v!),
                        ),
                      ),
                      // Leave Radio
                      DataCell(
                        Radio<String>(
                          value: 'LEAVE',
                          groupValue: status,
                          activeColor: AppColors.warning,
                          onChanged: (v) => academic.updateStudentAttendanceStatus(index, v!),
                        ),
                      ),
                    ],
                  );
                }),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
