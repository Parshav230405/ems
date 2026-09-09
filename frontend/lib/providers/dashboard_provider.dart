import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  DashboardSummary? _summary;
  List<RecentAdmissionItem> _recentAdmissions = [];
  List<NoticeItem> _recentNotices = [];
  List<MonthlyFeeItem> _monthlyFees = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardSummary? get summary => _summary;
  List<RecentAdmissionItem> get recentAdmissions => _recentAdmissions;
  List<NoticeItem> get recentNotices => _recentNotices;
  List<MonthlyFeeItem> get monthlyFees => _monthlyFees;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/dashboard');

      _summary = DashboardSummary.fromJson(res['summary']);

      if (res['recentAdmissions'] is List) {
        _recentAdmissions = (res['recentAdmissions'] as List)
            .map((item) => RecentAdmissionItem.fromJson(item))
            .toList();
      }

      if (res['recentNotices'] is List) {
        _recentNotices = (res['recentNotices'] as List)
            .map((item) => NoticeItem.fromJson(item))
            .toList();
      }

      if (res['feeCollectionOverview'] is List) {
        _monthlyFees = (res['feeCollectionOverview'] as List)
            .map((item) => MonthlyFeeItem.fromJson(item))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
