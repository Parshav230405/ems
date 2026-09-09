import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/student_provider.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/url_helper.dart';

class CertificateGeneratorScreen extends StatefulWidget {
  final String? initialStudentId;

  const CertificateGeneratorScreen({super.key, this.initialStudentId});

  @override
  State<CertificateGeneratorScreen> createState() => _CertificateGeneratorScreenState();
}

class _CertificateGeneratorScreenState extends State<CertificateGeneratorScreen> {
  final ApiService _api = ApiService();
  String? _selectedStudentId;
  final _titleController = TextEditingController(text: 'CERTIFICATE OF ACHIEVEMENT');
  final _bodyController = TextEditingController(
    text: 'Has successfully demonstrated outstanding academic performance, exemplary character, and distinguished leadership throughout the academic term 2025-2026.',
  );
  String _certificateType = 'Achievement';
  bool _isGenerating = false;
  List<dynamic> _issuedCertificates = [];

  final Map<String, Map<String, String>> _templates = {
    'Achievement': {
      'title': 'CERTIFICATE OF ACHIEVEMENT',
      'body': 'Has successfully demonstrated outstanding academic performance, exemplary character, and distinguished leadership throughout the academic term 2025-2026.',
    },
    'Merit': {
      'title': 'CERTIFICATE OF ACADEMIC MERIT',
      'body': 'In high recognition of achieving exceptional academic standing, scholarly diligence, and highest honors in the annual curricular examinations.',
    },
    'Character': {
      'title': 'CERTIFICATE OF EXEMPLARY CONDUCT',
      'body': 'Awarded for demonstrating impeccable integrity, civic responsibility, respectful peer collaboration, and consistent moral character.',
    },
    'Attendance': {
      'title': '100% ATTENDANCE EXCELLENCE AWARD',
      'body': 'In sincere appreciation of maintaining an unblemished 100% punctuality and perfect attendance record for the entire academic session.',
    },
    'CoCurricular': {
      'title': 'SPECIAL DISTINCTION IN CO-CURRICULARS',
      'body': 'Recognized for meritorious participation, creativity, sportsmanship, and outstanding dedication to institutional clubs and athletic events.',
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sp = Provider.of<StudentProvider>(context, listen: false);
      await sp.fetchStudents();
      if (_selectedStudentId == null && sp.students.isNotEmpty) {
        setState(() {
          _selectedStudentId = sp.students.first.id;
        });
      }
      _fetchIssuedCertificates();
    });
  }

  void _onTemplateSelected(String type) {
    setState(() {
      _certificateType = type;
      final template = _templates[type];
      if (template != null) {
        _titleController.text = template['title']!;
        _bodyController.text = template['body']!;
      }
    });
  }

  void _fetchIssuedCertificates() async {
    try {
      final res = await _api.get('/certificates');
      setState(() {
        _issuedCertificates = res['data'] ?? [];
      });
    } catch (_) {}
  }

  void _generateCertificate() async {
    if (_selectedStudentId == null) return;
    setState(() => _isGenerating = true);

    try {
      final res = await _api.post('/certificates/generate', {
        'studentId': _selectedStudentId,
        'type': _certificateType,
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
      });

      setState(() => _isGenerating = false);
      _fetchIssuedCertificates();

      final downloadUrl = res['downloadUrl'];
      if (downloadUrl != null) {
        UrlHelper.openUrl(downloadUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate generated, logged in audit trail, and PDF downloaded!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<StudentProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Generator Card
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
                const Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: AppColors.warning, size: 28),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Institutional Certificate Generator',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generate official institutional letterhead-styled certificates with audit trail logging',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.cardBorder),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Form Inputs
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Certificate Award Category *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCategoryChip('Achievement', 'Achievement'),
                              _buildCategoryChip('Merit', 'Academic Merit'),
                              _buildCategoryChip('Character', 'Conduct / Character'),
                              _buildCategoryChip('Attendance', '100% Attendance'),
                              _buildCategoryChip('CoCurricular', 'Co-Curricular'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text('Select Student *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedStudentId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              isDense: true,
                            ),
                            items: sp.students.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text('${s.name} (${s.admissionNumber}) - Class ${s.classDivision}'),
                            )).toList(),
                            onChanged: (v) => setState(() => _selectedStudentId = v),
                          ),

                          const SizedBox(height: 16),

                          const Text('Certificate Title (Editable) *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'e.g. CERTIFICATE OF ACHIEVEMENT',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 16),

                          const Text('Certificate Body / Achievement Note *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _bodyController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Enter 1-3 lines detailing student achievement and merit...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            onPressed: _isGenerating ? null : _generateCertificate,
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: _isGenerating
                                ? const Text('Generating PDF...')
                                : const Text('Generate & Download Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 32),

                    // Right: Live Certificate Preview
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFDF9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD97706), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'BRIGHT FUTURE PUBLIC SCHOOL',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
                            ),
                            const Text(
                              'Smart Management for a Brighter Future',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _titleController.text.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                            const Divider(height: 24, color: Color(0xFFB45309), thickness: 1, indent: 60, endIndent: 60),
                            const Text('This is to certify that', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text(
                              sp.students.firstWhere((s) => s.id == _selectedStudentId, orElse: () => sp.students.first).name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'of Class ${sp.students.firstWhere((s) => s.id == _selectedStudentId, orElse: () => sp.students.first).classDivision}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _bodyController.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5),
                            ),
                            const SizedBox(height: 36),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Date: 09 September 2025', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                Column(
                                  children: [
                                    Text('Dr. S. K. Mukherjee', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text('Principal / Authorized Signatory', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Audit Log Table of Issued Certificates
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Issued Certificates Audit Trail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Immutable log of all generated certificates for student verification and dispute resolution',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (_issuedCertificates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No certificates issued yet.', style: TextStyle(color: AppColors.textMuted))),
                  )
                else
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('Certificate No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Issued Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: _issuedCertificates.map<DataRow>((c) {
                      final dateStr = (c['issuedDate'] as String).split('T')[0];
                      return DataRow(
                        cells: [
                          DataCell(Text(c['certificateNo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataCell(Text(c['student']?['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                          DataCell(Text(c['title'], style: const TextStyle(fontSize: 12))),
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                          DataCell(
                            OutlinedButton.icon(
                              onPressed: () {
                                UrlHelper.openUrl('/api/certificates/${c['certificateNo']}/download');
                              },
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: const Text('Download PDF', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String type, String label) {
    final isSelected = _certificateType == type;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.textPrimary)),
      selected: isSelected,
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.background,
      side: BorderSide(color: isSelected ? AppColors.accent : AppColors.cardBorder),
      onSelected: (_) => _onTemplateSelected(type),
    );
  }
}
