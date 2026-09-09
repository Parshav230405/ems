import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = false;
  List<dynamic> _notices = [];

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  void _fetchNotices() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/notices');
      setState(() {
        _notices = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddNoticeDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Publish New Notice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Broadcast announcements and circulars to students and staff', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const Divider(height: 24, color: AppColors.cardBorder),
                const Text('Notice Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Sports Day Announcement',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Notice Content *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter full circular details, date, and instructions...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
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
                        if (titleCtrl.text.trim().isNotEmpty && bodyCtrl.text.trim().isNotEmpty) {
                          await _api.post('/notices', {
                            'title': titleCtrl.text.trim(),
                            'body': bodyCtrl.text.trim(),
                          });
                          if (mounted) Navigator.pop(ctx);
                          _fetchNotices();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Publish Notice'),
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

  @override
  Widget build(BuildContext context) {
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
                      Text('Notice Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('Create and broadcast official school announcements and circulars', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddNoticeDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Notice'),
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

            if (_isLoading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else if (_notices.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No notices posted.', style: TextStyle(color: AppColors.textMuted))))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notices.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 1),
                itemBuilder: (context, index) {
                  final n = _notices[index];
                  final date = (n['postedDate'] as String).split('T')[0];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.warning, size: 24),
                    ),
                    title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(n['body'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                      child: Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
