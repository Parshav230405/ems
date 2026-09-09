import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/url_helper.dart';
import '../../providers/student_provider.dart';
import '../certificates/certificate_generator_screen.dart';

class StudentProfileDialog extends StatefulWidget {
  final String studentId;

  const StudentProfileDialog({super.key, required this.studentId});

  static void show(BuildContext context, String studentId) {
    showDialog(
      context: context,
      builder: (ctx) => StudentProfileDialog(studentId: studentId),
    );
  }

  @override
  State<StudentProfileDialog> createState() => _StudentProfileDialogState();
}

class _StudentProfileDialogState extends State<StudentProfileDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StudentProvider>(context, listen: false).fetchStudentProfile(widget.studentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = Provider.of<StudentProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: studentProvider.isLoading || studentProvider.currentStudentProfile == null
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(studentProvider.currentStudentProfile!),
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final s = data['student'];
    final analytics = data['analytics'] ?? {};
    final feeSummary = analytics['feeSummary'] ?? {};
    final attendanceRate = analytics['attendanceRate'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFEFF6FF),
              child: Text(
                (s['name'] as String).substring(0, 1),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        s['name'] ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['status'] ?? 'ACTIVE',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admission No: ${s['admissionNumber']} • Class: ${s['class']?['name']}-${s['class']?['division']}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    UrlHelper.openUrl('http://localhost:5000/api/reports/student/${s['id']}/download');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading Report Card for ${s['name']}...'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                  label: const Text('Report Card (PDF)', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 750),
                          child: Stack(
                            children: [
                              CertificateGeneratorScreen(initialStudentId: s['id']),
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
                  icon: const Icon(Icons.workspace_premium_rounded, size: 14),
                  label: const Text('Issue Certificate', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Quick Highlights Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryPill('Attendance Rate', '$attendanceRate%', AppColors.accent),
              _buildSummaryPill('Total Fee', '₹ ${feeSummary['totalFee'] ?? 0}', AppColors.textPrimary),
              _buildSummaryPill('Amount Paid', '₹ ${feeSummary['totalPaid'] ?? 0}', AppColors.success),
              _buildSummaryPill('Pending Fee', '₹ ${feeSummary['pendingFee'] ?? 0}', AppColors.danger),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Personal & Parent'),
            Tab(text: 'Academic Marks'),
            Tab(text: 'Attendance Records'),
            Tab(text: 'Fee History'),
          ],
        ),

        const SizedBox(height: 16),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalInfoTab(s),
              _buildAcademicMarksTab(s['marks'] as List? ?? []),
              _buildAttendanceTab(s['attendance'] as List? ?? []),
              _buildFeeHistoryTab(s['feePayments'] as List? ?? []),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPill(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildPersonalInfoTab(Map<String, dynamic> s) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoRow('Full Name', s['name'] ?? ''),
          _buildInfoRow('Admission Number', s['admissionNumber'] ?? ''),
          _buildInfoRow('Date of Birth', s['dob'] != null ? (s['dob'] as String).split('T')[0] : ''),
          _buildInfoRow('Gender', s['gender'] ?? ''),
          _buildInfoRow('Parent / Guardian', s['parentName'] ?? ''),
          _buildInfoRow('Parent Contact', s['parentContact'] ?? ''),
          _buildInfoRow('Parent Email', s['parentEmail'] ?? 'Not provided'),
          _buildInfoRow('Admission Date', s['admissionDate'] != null ? (s['admissionDate'] as String).split('T')[0] : ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicMarksTab(List marks) {
    if (marks.isEmpty) {
      return const Center(child: Text('No examination marks recorded yet.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      itemCount: marks.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder),
      itemBuilder: (context, i) {
        final m = marks[i];
        final exam = m['exam'] ?? {};
        final subject = exam['subject'] ?? {};
        final score = m['marksObtained'] ?? 0;
        final max = exam['maxMarks'] ?? 100;
        return ListTile(
          dense: true,
          title: Text(exam['name'] ?? 'Exam', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('Subject: ${subject['name'] ?? 'Subject'}'),
          trailing: Text(
            '$score / $max',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(List attendance) {
    if (attendance.isEmpty) {
      return const Center(child: Text('No attendance records available.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      itemCount: attendance.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder),
      itemBuilder: (context, i) {
        final a = attendance[i];
        final date = (a['date'] as String).split('T')[0];
        final status = a['status'] as String;
        Color badgeColor = status == 'PRESENT' ? AppColors.success : (status == 'ABSENT' ? AppColors.danger : AppColors.warning);
        return ListTile(
          dense: true,
          title: Text(date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor)),
          ),
        );
      },
    );
  }

  Widget _buildFeeHistoryTab(List payments) {
    if (payments.isEmpty) {
      return const Center(child: Text('No payment records found.', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      itemCount: payments.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder),
      itemBuilder: (context, i) {
        final p = payments[i];
        final date = (p['paymentDate'] as String).split('T')[0];
        return ListTile(
          dense: true,
          title: Text(p['notes'] ?? 'Tuition Fee Installment', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('Receipt: ${p['receiptNo']} • Date: $date • Mode: ${p['mode']}'),
          trailing: Text(
            '₹ ${p['amountPaid']}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
          ),
        );
      },
    );
  }
}
