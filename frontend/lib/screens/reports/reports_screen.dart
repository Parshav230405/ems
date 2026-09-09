import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/url_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _schoolSummary;

  @override
  void initState() {
    super.initState();
    _fetchSchoolSummary();
  }

  void _fetchSchoolSummary() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/reports/school-summary');
      setState(() {
        _schoolSummary = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _openReport(String type) {
    switch (type) {
      case 'Student Report':
        _showStudentReportDialog();
        break;
      case 'Student Internship Report':
        _showInternshipReportDialog();
        break;
      case 'Attendance Report':
        _showAttendanceReportDialog();
        break;
      case 'Fee Report':
        _showFeeReportDialog();
        break;
      case 'Result Report':
        _showResultReportDialog();
        break;
      case 'Class-wise Report':
        _showClassReportDialog();
        break;
      case 'Teacher Report':
        _showTeacherReportDialog();
        break;
    }
  }

  void _showInternshipReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _StudentInternshipReportModal(),
    );
  }

  void _showStudentReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _StudentReportModal(),
    );
  }

  void _showAttendanceReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _AttendanceReportModal(),
    );
  }

  void _showFeeReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _FeeReportModal(),
    );
  }

  void _showResultReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _ResultReportModal(),
    );
  }

  void _showClassReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _ClassReportModal(),
    );
  }

  void _showTeacherReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _TeacherReportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reports & School Analytics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Generate comprehensive academic report cards, attendance summaries, and fee collection analysis in real time',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _fetchSchoolSummary,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28, color: AppColors.cardBorder),

                // Report Cards Grid with interactive click & hover
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildReportTypeCard(
                      'Student Report',
                      'View individual student profiles, marksheets & performance cards',
                      Icons.person_rounded,
                      const Color(0xFFEFF6FF),
                      AppColors.accent,
                    ),
                    _buildReportTypeCard(
                      'Student Internship Report',
                      'Generate university-compliant DOCX project reports with cover page & certificate',
                      Icons.assignment_turned_in_rounded,
                      const Color(0xFFF0FDF4),
                      const Color(0xFF16A34A),
                    ),
                    _buildReportTypeCard(
                      'Attendance Report',
                      'Class-wise attendance rates, daily logs & institutional averages',
                      Icons.event_available_rounded,
                      const Color(0xFFECFDF5),
                      AppColors.success,
                    ),
                    _buildReportTypeCard(
                      'Fee Report',
                      'Annual fee collection, payment mode analytics & pending balances',
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFFFFF7ED),
                      const Color(0xFFEA580C),
                    ),
                    _buildReportTypeCard(
                      'Result Report',
                      'Examination gradebooks, subject averages & top performers',
                      Icons.assessment_rounded,
                      const Color(0xFFF5F3FF),
                      const Color(0xFF7C3AED),
                    ),
                    _buildReportTypeCard(
                      'Class-wise Report',
                      'Enrollment statistics, gender ratios & annual fee revenue',
                      Icons.domain_rounded,
                      const Color(0xFFEFF6FF),
                      const Color(0xFF0284C7),
                    ),
                    _buildReportTypeCard(
                      'Teacher Report',
                      'Faculty directory, qualifications, and course assignments',
                      Icons.school_rounded,
                      const Color(0xFFFEF2F2),
                      AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // School Summary Overview
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_schoolSummary != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Institutional Key Performance Indicators',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('Active Students', _schoolSummary!['activeStudents']?.toString() ?? '0', AppColors.accent),
                      _buildMetricItem('Total Faculty', _schoolSummary!['totalTeachers']?.toString() ?? '0', AppColors.success),
                      _buildMetricItem('Classes Running', _schoolSummary!['totalClasses']?.toString() ?? '0', AppColors.primary),
                      _buildMetricItem('Total Fees Collected', '₹ ${_schoolSummary!['totalFeesCollected'] ?? 0}', const Color(0xFFEA580C)),
                    ],
                  ),
                  const Divider(height: 32, color: AppColors.cardBorder),
                  const Text('Class Enrollment Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_schoolSummary!['classDistribution'] is List && (_schoolSummary!['classDistribution'] as List).isNotEmpty)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: (_schoolSummary!['classDistribution'] as List).map<Widget>((c) {
                        return Container(
                          width: 170,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Class ${c['className']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('${c['studentCount']} Students Enrolled', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text('No classes enrolled yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard(String title, String desc, IconData icon, Color bgColor, Color iconColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openReport(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 12, color: iconColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ==========================================
// 1. STUDENT REPORT MODAL
// ==========================================
class _StudentReportModal extends StatefulWidget {
  const _StudentReportModal();

  @override
  State<_StudentReportModal> createState() => _StudentReportModalState();
}

class _StudentReportModalState extends State<_StudentReportModal> {
  final ApiService _api = ApiService();
  List<dynamic> _students = [];
  String? _selectedStudentId;
  Map<String, dynamic>? _reportData;
  bool _isLoadingList = false;
  bool _isLoadingReport = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    setState(() => _isLoadingList = true);
    try {
      final res = await _api.get('/students', queryParams: {'limit': '100'});
      final list = (res['data'] ?? res['students']) as List<dynamic>? ?? [];
      setState(() {
        _students = list;
        _isLoadingList = false;
        if (list.isNotEmpty) {
          _selectedStudentId = list.first['id'];
          _fetchStudentReport(list.first['id']);
        }
      });
    } catch (_) {
      setState(() => _isLoadingList = false);
    }
  }

  void _fetchStudentReport(String studentId) async {
    setState(() => _isLoadingReport = true);
    try {
      final res = await _api.get('/reports/student/$studentId');
      setState(() {
        _reportData = res;
        _isLoadingReport = false;
      });
    } catch (_) {
      setState(() => _isLoadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_rounded, color: AppColors.accent, size: 24),
                      SizedBox(width: 8),
                      Text('Student Academic & Attendance Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoadingList)
                const LinearProgressIndicator()
              else if (_students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No students found in this school tenant.'),
                )
              else
                Row(
                  children: [
                    const Text('Select Student: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: _students.map((s) {
                          final cls = s['class'] != null
                              ? '${s['class']['name']}-${s['class']['division']}'
                              : (s['className'] ?? '');
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text('${s['name']} (${s['admissionNumber']}) - Class $cls', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedStudentId = val);
                            _fetchStudentReport(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              Expanded(
                child: _isLoadingReport
                    ? const Center(child: CircularProgressIndicator())
                    : _reportData == null
                        ? const Center(child: Text('Select a student to load report details'))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_reportData!['student']?['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text('Adm No: ${_reportData!['student']?['admissionNumber'] ?? ''} | Class: ${_reportData!['student']?['class'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Parent: ${_reportData!['student']?['parentName'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          Text('Contact: ${_reportData!['student']?['parentContact'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    _buildPill('Attendance Rate', '${_reportData!['attendance']?['percentage'] ?? 100}%', AppColors.accent),
                                    const SizedBox(width: 12),
                                    _buildPill('Overall Score', '${_reportData!['academics']?['overallPercentage'] ?? 0}%', AppColors.success),
                                    const SizedBox(width: 12),
                                    _buildPill('Overall Grade', '${_reportData!['academics']?['overallGrade'] ?? "N/A"}', const Color(0xFF7C3AED)),
                                    const SizedBox(width: 12),
                                    _buildPill('Pending Fees', '₹ ${_reportData!['fees']?['pendingFee'] ?? 0}', AppColors.danger),
                                  ],
                                ),

                                const SizedBox(height: 20),
                                const Text('Examination Performance Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),

                                if (_reportData!['academics']?['exams'] is List && (_reportData!['academics']?['exams'] as List).isNotEmpty)
                                  DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Exam Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: (_reportData!['academics']['exams'] as List).map<DataRow>((e) {
                                      final isPassed = e['isPassed'] == true;
                                      return DataRow(cells: [
                                        DataCell(Text(e['examName'] ?? '')),
                                        DataCell(Text(e['subject'] ?? '')),
                                        DataCell(Text('${e['marksObtained']} / ${e['maxMarks']}')),
                                        DataCell(Text('${e['percentage']}%')),
                                        DataCell(Text(e['grade'] ?? '')),
                                        DataCell(Text(isPassed ? 'PASSED' : 'FAILED', style: TextStyle(color: isPassed ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold))),
                                      ]);
                                    }).toList(),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No examination records registered yet for this student.', style: TextStyle(color: AppColors.textMuted)),
                                  ),
                              ],
                            ),
                          ),
              ),

              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _selectedStudentId == null
                        ? null
                        : () {
                            UrlHelper.openUrl('http://localhost:5000/api/reports/student/$_selectedStudentId/download');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generating official Student Report Card (PDF)...'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Export Official Report Card (PDF)'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. ATTENDANCE REPORT MODAL
// ==========================================
class _AttendanceReportModal extends StatefulWidget {
  const _AttendanceReportModal();

  @override
  State<_AttendanceReportModal> createState() => _AttendanceReportModalState();
}

class _AttendanceReportModalState extends State<_AttendanceReportModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await _api.get('/reports/attendance');
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: AppColors.success, size: 24),
                      SizedBox(width: 8),
                      Text('Attendance Analytics Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_data == null)
                const Expanded(child: Center(child: Text('Unable to load attendance analytics')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatBox('Overall Rate', '${_data!['overallPercentage']}%', AppColors.success),
                            const SizedBox(width: 12),
                            _buildStatBox('Present Logs', '${_data!['presentCount']}', AppColors.accent),
                            const SizedBox(width: 12),
                            _buildStatBox('Absent Logs', '${_data!['absentCount']}', AppColors.danger),
                            const SizedBox(width: 12),
                            _buildStatBox('On Leave', '${_data!['leaveCount']}', AppColors.warning),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Class-Wise Attendance Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        if (_data!['classBreakdown'] is List && (_data!['classBreakdown'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Class & Section', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Enrolled Students', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Attendance Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['classBreakdown'] as List).map<DataRow>((c) {
                              return DataRow(cells: [
                                DataCell(Text('Class ${c['className']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('${c['totalStudents']} Students')),
                                DataCell(
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: LinearProgressIndicator(
                                          value: ((c['attendanceRate'] as num?) ?? 100) / 100,
                                          backgroundColor: AppColors.cardBorder,
                                          valueColor: AlwaysStoppedAnimation<Color>((c['attendanceRate'] ?? 100) >= 75 ? AppColors.success : AppColors.danger),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${c['attendanceRate']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No class attendance logs registered.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. FEE REPORT MODAL
// ==========================================
class _FeeReportModal extends StatefulWidget {
  const _FeeReportModal();

  @override
  State<_FeeReportModal> createState() => _FeeReportModalState();
}

class _FeeReportModalState extends State<_FeeReportModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await _api.get('/reports/fees');
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFEA580C), size: 24),
                      SizedBox(width: 8),
                      Text('Fee Collection & Dues Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_data == null)
                const Expanded(child: Center(child: Text('Unable to load fee analytics')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildCard('Total Expected', '₹ ${_data!['totalExpected']}', AppColors.textPrimary),
                            const SizedBox(width: 12),
                            _buildCard('Total Collected', '₹ ${_data!['totalCollected']}', AppColors.success),
                            const SizedBox(width: 12),
                            _buildCard('Total Pending', '₹ ${_data!['totalPending']}', AppColors.danger),
                            const SizedBox(width: 12),
                            _buildCard('Collection Rate', '${_data!['collectionRate']}%', AppColors.accent),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text('Class-Wise Fee Collection Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        if (_data!['classBreakdown'] is List && (_data!['classBreakdown'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Fee Title', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Enrolled', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Expected', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Collected', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Pending', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['classBreakdown'] as List).map<DataRow>((c) {
                              return DataRow(cells: [
                                DataCell(Text('Class ${c['className']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(c['title'] ?? '')),
                                DataCell(Text('${c['studentCount']} Students')),
                                DataCell(Text('₹ ${c['expected']}')),
                                DataCell(Text('₹ ${c['collected']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))),
                                DataCell(Text('₹ ${c['pending']}', style: TextStyle(color: (c['pending'] ?? 0) > 0 ? AppColors.danger : AppColors.textMuted, fontWeight: FontWeight.w600))),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No fee structures configured yet.', style: TextStyle(color: AppColors.textMuted)),

                        const SizedBox(height: 24),
                        const Text('Recent Fee Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        if (_data!['recentTransactions'] is List && (_data!['recentTransactions'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Receipt #', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['recentTransactions'] as List).map<DataRow>((t) {
                              return DataRow(cells: [
                                DataCell(Text(t['receiptNo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataCell(Text(t['studentName'])),
                                DataCell(Text(t['className'])),
                                DataCell(Text('₹ ${t['amountPaid']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                                DataCell(Text(t['mode'])),
                                DataCell(Text(t['paymentDate'])),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No fee payments recorded yet.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. RESULT REPORT MODAL
// ==========================================
class _ResultReportModal extends StatefulWidget {
  const _ResultReportModal();

  @override
  State<_ResultReportModal> createState() => _ResultReportModalState();
}

class _ResultReportModalState extends State<_ResultReportModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await _api.get('/reports/results');
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment_rounded, color: Color(0xFF7C3AED), size: 24),
                      SizedBox(width: 8),
                      Text('Examination Results & Merit Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_data == null)
                const Expanded(child: Center(child: Text('Unable to load result analytics')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStat('Total Exams', '${_data!['totalExams']}', AppColors.accent),
                            const SizedBox(width: 12),
                            _buildStat('Evaluated Papers', '${_data!['totalEvaluated']}', AppColors.primary),
                            const SizedBox(width: 12),
                            _buildStat('Pass Percentage', '${_data!['overallPassRate']}%', AppColors.success),
                            const SizedBox(width: 12),
                            _buildStat('School Average', '${_data!['overallAverage']}%', const Color(0xFF7C3AED)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text('Top Performing Students (Honor Roll)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        if (_data!['topStudents'] is List && (_data!['topStudents'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Adm No', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Overall %', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['topStudents'] as List).asMap().entries.map<DataRow>((entry) {
                              final rank = entry.key + 1;
                              final s = entry.value;
                              return DataRow(cells: [
                                DataCell(Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent))),
                                DataCell(Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(s['admissionNumber'])),
                                DataCell(Text(s['className'])),
                                DataCell(Text('${s['percentage']}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success))),
                                DataCell(Text(s['grade'])),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No student exam marks submitted yet.', style: TextStyle(color: AppColors.textMuted)),

                        const SizedBox(height: 24),
                        const Text('Exam-Wise Performance Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        if (_data!['examAnalytics'] is List && (_data!['examAnalytics'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Exam Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Evaluated', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Average %', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Passed', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['examAnalytics'] as List).map<DataRow>((e) {
                              return DataRow(cells: [
                                DataCell(Text(e['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(e['subject'])),
                                DataCell(Text(e['className'])),
                                DataCell(Text('${e['totalStudents']} Students')),
                                DataCell(Text('${e['averagePercentage']}%')),
                                DataCell(Text('${e['passCount']} Passed', style: const TextStyle(color: AppColors.success))),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No exams recorded.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. CLASS REPORT MODAL
// ==========================================
class _ClassReportModal extends StatefulWidget {
  const _ClassReportModal();

  @override
  State<_ClassReportModal> createState() => _ClassReportModalState();
}

class _ClassReportModalState extends State<_ClassReportModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await _api.get('/reports/classes');
      setState(() {
        _classes = res['classes'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.domain_rounded, color: Color(0xFF0284C7), size: 24),
                      SizedBox(width: 8),
                      Text('Class Enrollment & Capacity Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_classes.isEmpty)
                const Expanded(child: Center(child: Text('No class records found.')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Class & Division', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Academic Year', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Enrolled Students', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Boys / Girls', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Annual Fee', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _classes.map<DataRow>((c) {
                        return DataRow(cells: [
                          DataCell(Text('Class ${c['className']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(c['academicYear'] ?? '')),
                          DataCell(Text('${c['enrolled']} Students', style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text('${c['boys']} B / ${c['girls']} G')),
                          DataCell(Text('₹ ${c['annualFeePerStudent']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),

              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. TEACHER REPORT MODAL
// ==========================================
class _TeacherReportModal extends StatefulWidget {
  const _TeacherReportModal();

  @override
  State<_TeacherReportModal> createState() => _TeacherReportModalState();
}

class _TeacherReportModalState extends State<_TeacherReportModal> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final res = await _api.get('/reports/teachers');
      setState(() {
        _data = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school_rounded, color: AppColors.danger, size: 24),
                      SizedBox(width: 8),
                      Text('Faculty Workload & Directory Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const Divider(height: 20),

              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_data == null)
                const Expanded(child: Center(child: Text('Unable to load faculty report')))
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildInfoBox('Total Faculty', '${_data!['totalTeachers']}', AppColors.accent),
                            const SizedBox(width: 16),
                            _buildInfoBox('Active Faculty', '${_data!['activeTeachers']}', AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text('Faculty Directory & Assignments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        if (_data!['teachers'] is List && (_data!['teachers'] as List).isNotEmpty)
                          DataTable(
                            columns: const [
                              DataColumn(label: Text('Teacher Name', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Email & Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Qualification', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Assigned Subjects', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: (_data!['teachers'] as List).map<DataRow>((t) {
                              final subList = (t['subjects'] as List<dynamic>?)?.join(', ') ?? 'None';
                              return DataRow(cells: [
                                DataCell(Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text('${t['email']}\n${t['contact']}', style: const TextStyle(fontSize: 11))),
                                DataCell(Text(t['qualification'])),
                                DataCell(Text(subList.isNotEmpty ? subList : 'No subjects assigned', style: const TextStyle(fontSize: 12))),
                                DataCell(Text(t['status'], style: TextStyle(color: t['status'] == 'Active' ? AppColors.success : AppColors.danger, fontWeight: FontWeight.bold))),
                              ]);
                            }).toList(),
                          )
                        else
                          const Text('No teachers registered in this school.', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),

              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. STUDENT INTERNSHIP REPORT MODAL (.DOCX)
// ==========================================
class _StudentInternshipReportModal extends StatefulWidget {
  const _StudentInternshipReportModal();

  @override
  State<_StudentInternshipReportModal> createState() => _StudentInternshipReportModalState();
}

class _StudentInternshipReportModalState extends State<_StudentInternshipReportModal> {
  final ApiService _api = ApiService();
  List<dynamic> _students = [];
  String? _selectedStudentId;
  bool _isLoadingStudents = true;
  bool _isGenerating = false;

  late final TextEditingController _projectTitleController;
  late final TextEditingController _internshipTitleController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyAddressController;
  late final TextEditingController _companyGuideController;
  late final TextEditingController _facultyGuideController;
  late final TextEditingController _universityNameController;
  late final TextEditingController _instituteNameController;
  late final TextEditingController _departmentNameController;
  late final TextEditingController _courseCodeController;
  late final TextEditingController _durationController;
  late final TextEditingController _technologiesController;
  late final TextEditingController _abstractController;

  int _selectedPresetIndex = 0;

  @override
  void initState() {
    super.initState();
    _projectTitleController = TextEditingController(text: 'AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM');
    _internshipTitleController = TextEditingController(text: 'Full-Stack Web Development & Cloud Systems');
    _companyNameController = TextEditingController(text: 'Vanshee Infotech');
    _companyAddressController = TextEditingController(text: 'B-327, Sun South Street, South Bopal, Ahmedabad – 380057, Gujarat, India');
    _companyGuideController = TextEditingController(text: 'Bhavi Kansara (CEO)');
    _facultyGuideController = TextEditingController(text: 'Prof. Internal Faculty Guide');
    _universityNameController = TextEditingController(text: 'INDUS UNIVERSITY');
    _instituteNameController = TextEditingController(text: 'INSTITUTE OF TECHNOLOGY AND ENGINEERING');
    _departmentNameController = TextEditingController(text: 'COMPUTER SCIENCE ENGINEERING');
    _courseCodeController = TextEditingController(text: 'CE0523');
    _durationController = TextEditingController(text: '15 Days / 65+ Hours');
    _technologiesController = TextEditingController(text: 'Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, JWT, PDFKit');
    _abstractController = TextEditingController(text: 'The objective of this project is to build a scalable, multi-tenant Education Management System (AURA EMS) serving independent schools with strict data isolation, real-time analytics, automated attendance, fee accounting, and verifiable document generation.');

    _fetchStudents();
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _internshipTitleController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyGuideController.dispose();
    _facultyGuideController.dispose();
    _universityNameController.dispose();
    _instituteNameController.dispose();
    _departmentNameController.dispose();
    _courseCodeController.dispose();
    _durationController.dispose();
    _technologiesController.dispose();
    _abstractController.dispose();
    super.dispose();
  }

  void _applyPreset(int index) {
    setState(() {
      _selectedPresetIndex = index;
      switch (index) {
        case 0:
          _projectTitleController.text = 'AURA EMS: MULTI-TENANT EDUCATION MANAGEMENT SYSTEM';
          _internshipTitleController.text = 'Full-Stack Web Development & Cloud Systems';
          _technologiesController.text = 'Flutter Web, Node.js, Express, TypeScript, PostgreSQL, Prisma ORM, JWT, PDFKit';
          _abstractController.text = 'A modern, multi-tenant Education Management System serving independent schools with strict cryptographic data isolation, real-time analytics, automated attendance, fee accounting, and verifiable document generation.';
          break;
        case 1:
          _projectTitleController.text = 'LIBRARY BOOK VIEWER (WEB DEVELOPMENT)';
          _internshipTitleController.text = 'Web Development & Frontend Design';
          _technologiesController.text = 'HTML, CSS, JavaScript, XML, Responsive Web Design';
          _abstractController.text = 'A responsive web application engineered to catalog, search, and view library book holdings. Implements responsive UI, structured XML data storage, and dynamic client-side DOM manipulation.';
          break;
        case 2:
          _projectTitleController.text = 'STUDENT PERFORMANCE PREDICTION & ANALYTICS';
          _internshipTitleController.text = 'Python & Machine Learning';
          _technologiesController.text = 'Python, Pandas, NumPy, Scikit-learn, Flask, Matplotlib';
          _abstractController.text = 'A machine learning predictive framework designed to analyze student historical academic and attendance records to forecast examination performance and identify students requiring pedagogical intervention.';
          break;
        case 3:
          _projectTitleController.text = 'CAMPUS CONNECT: MOBILE STUDENT PORTAL';
          _internshipTitleController.text = 'Mobile Application Development';
          _technologiesController.text = 'Flutter, Dart SDK, Firebase, REST API, Provider State Management';
          _abstractController.text = 'A cross-platform mobile application providing students and faculty with instantaneous access to academic timetables, attendance alerts, exam results, and digital fee receipts.';
          break;
      }
    });
  }

  void _fetchStudents() async {
    try {
      final res = await _api.get('/students', queryParams: {'limit': '100'});
      final rawList = (res['data'] ?? res['students'] ?? []) as List<dynamic>;
      if (mounted) {
        setState(() {
          _students = rawList;
          _isLoadingStudents = false;
          if (_students.isNotEmpty) {
            _selectedStudentId = _students.first['id'];
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _generateInternshipReport() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student first'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final res = await _api.post('/reports/internship/generate', {
        'studentId': _selectedStudentId,
        'projectTitle': _projectTitleController.text.trim(),
        'internshipTitle': _internshipTitleController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'companyAddress': _companyAddressController.text.trim(),
        'companyGuide': _companyGuideController.text.trim(),
        'facultyGuide': _facultyGuideController.text.trim(),
        'universityName': _universityNameController.text.trim(),
        'instituteName': _instituteNameController.text.trim(),
        'departmentName': _departmentNameController.text.trim(),
        'courseCode': _courseCodeController.text.trim(),
        'duration': _durationController.text.trim(),
        'technologies': _technologiesController.text.trim(),
        'abstract': _abstractController.text.trim(),
      });

      setState(() => _isGenerating = false);

      final downloadUrl = res['downloadUrl'];
      if (downloadUrl != null) {
        UrlHelper.openUrl('http://localhost:5000$downloadUrl');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Official Internship Project Report (.docx) generated and downloaded!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 720,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Internship Project Report (.docx)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generates university-compliant Word report with Cover Page, Certificate & Acknowledgement',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Main Form Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Student Picker
                    const Text('Select Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (_isLoadingStudents)
                      const LinearProgressIndicator()
                    else if (_students.isEmpty)
                      const Text('No students found in this tenant', style: TextStyle(color: AppColors.danger, fontSize: 13))
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: _students.map<DropdownMenuItem<String>>((s) {
                          final className = s['class'] != null
                              ? '${s['class']['name']}-${s['class']['division']}'
                              : (s['className'] ?? '');
                          return DropdownMenuItem<String>(
                            value: s['id'],
                            child: Text(
                              '${s['name']} (${s['admissionNumber']}) - Class $className',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedStudentId = val),
                      ),

                    const SizedBox(height: 18),

                    // 2. Presets Selection
                    const Text('Quick Fill Project Presets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip(0, 'Full-Stack Cloud (AURA EMS)'),
                        _buildPresetChip(1, 'Web Development (Library Viewer)'),
                        _buildPresetChip(2, 'Python & ML'),
                        _buildPresetChip(3, 'Mobile App (Flutter)'),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Form Inputs Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Project Title', _projectTitleController, 'Title of the mini project'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Internship Domain / Title', _internshipTitleController, 'e.g. Web Development'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Host Company Name', _companyNameController, 'e.g. Vanshee Infotech'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Industry Guide / Supervisor', _companyGuideController, 'e.g. Bhavi Kansara (CEO)'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField('Company Address', _companyAddressController, 'Official corporate address of host company'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField('Internal Faculty Guide', _facultyGuideController, 'Faculty guide name'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Course Code', _courseCodeController, 'e.g. CE0523 / CE0318 / CE0726'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField('Duration', _durationController, 'e.g. 15 Days / 65+ Hours'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField('Technologies Used (comma separated)', _technologiesController, 'e.g. Flutter Web, Node.js, Express, PostgreSQL'),
                    const SizedBox(height: 12),

                    _buildTextField('Abstract / Project Summary', _abstractController, 'Summary of student project', maxLines: 3),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateInternshipReport,
                  icon: _isGenerating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.file_download_rounded, size: 18),
                  label: Text(_isGenerating ? 'Generating Word Document...' : 'Generate & Download Report (.docx)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(int index, String label) {
    final isSelected = _selectedPresetIndex == index;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: const Color(0xFFDCFCE7),
      backgroundColor: AppColors.background,
      side: BorderSide(color: isSelected ? const Color(0xFF16A34A) : AppColors.cardBorder),
      onSelected: (_) => _applyPreset(index),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

