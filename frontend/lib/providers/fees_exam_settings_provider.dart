import 'package:flutter/material.dart';
import '../core/services/api_service.dart';

class FeesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _feeStructures = [];
  Map<String, dynamic>? _selectedStudentFeeStatus;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get feeStructures => _feeStructures;
  Map<String, dynamic>? get selectedStudentFeeStatus => _selectedStudentFeeStatus;

  Future<void> fetchFeeStructures({String? classId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = classId != null ? {'classId': classId} : null;
      final res = await _api.get('/fees/structures', queryParams: query);
      _feeStructures = res['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchStudentFeeStatus(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/fees/students/$studentId');
      _selectedStudentFeeStatus = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> recordPayment({
    required String studentId,
    required double amountPaid,
    required String mode,
    String? notes,
  }) async {
    try {
      await _api.post('/fees/payments', {
        'studentId': studentId,
        'amountPaid': amountPaid,
        'mode': mode,
        'notes': notes,
      });
      await fetchStudentFeeStatus(studentId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class ExamProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _exams = [];
  Map<String, dynamic>? _currentExamMarksData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get exams => _exams;
  Map<String, dynamic>? get currentExamMarksData => _currentExamMarksData;

  Future<void> fetchExams({String? classId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = classId != null ? {'classId': classId} : null;
      final res = await _api.get('/exams', queryParams: query);
      _exams = res['data'] ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchExamMarks(String examId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/exams/$examId/marks');
      _currentExamMarksData = res;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void updateStudentMark(int index, double marks) {
    if (_currentExamMarksData != null && _currentExamMarksData!['students'] is List) {
      final students = _currentExamMarksData!['students'] as List;
      if (index >= 0 && index < students.length) {
        students[index]['marksObtained'] = marks;
        final maxMarks = (_currentExamMarksData!['exam']['maxMarks'] as num).toDouble();
        final pct = maxMarks > 0 ? (marks / maxMarks) * 100 : 0.0;
        students[index]['percentage'] = double.parse(pct.toStringAsFixed(1));
        students[index]['grade'] = _computeGrade(pct);
        students[index]['isPassed'] = marks >= (_currentExamMarksData!['exam']['passMarks'] as num).toDouble();
        notifyListeners();
      }
    }
  }

  String _computeGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 35) return 'D';
    return 'F';
  }

  Future<bool> saveExamMarks(String examId) async {
    if (_currentExamMarksData == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final students = _currentExamMarksData!['students'] as List;
      final marks = students.map((s) => {
        'studentId': s['studentId'],
        'marksObtained': s['marksObtained'],
      }).toList();

      await _api.post('/exams/marks', {
        'examId': examId,
        'marks': marks,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String> _settings = {};
  List<dynamic> _backups = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String> get settings => _settings;
  List<dynamic> get backups => _backups;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/settings');
      final Map<String, dynamic> raw = res['settings'] ?? {};
      _settings = raw.map((k, v) => MapEntry(k, v.toString()));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> updateSettings(Map<String, String> updates) async {
    try {
      await _api.put('/settings', updates);
      await fetchSettings();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchBackups() async {
    try {
      final res = await _api.get('/settings/backups');
      _backups = res['data'] ?? [];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> triggerBackup() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.post('/settings/backup', {});
      await fetchBackups();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
