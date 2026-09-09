import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../models/client_model.dart';

class ClientProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<ClientModel> _clients = [];
  Map<String, dynamic> _stats = {
    'totalClients': 0,
    'activeClients': 0,
    'suspendedClients': 0,
    'totalStudents': 0,
    'totalUsers': 0,
  };
  bool _isLoading = false;
  String? _errorMessage;

  List<ClientModel> get clients => _clients;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStats() async {
    try {
      final res = await _api.get('/clients/stats');
      _stats = {
        'totalClients': res['totalClients'] ?? 0,
        'activeClients': res['activeClients'] ?? 0,
        'suspendedClients': res['suspendedClients'] ?? 0,
        'totalStudents': res['totalStudents'] ?? 0,
        'totalUsers': res['totalUsers'] ?? 0,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  Future<void> fetchClients({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'all') {
        queryParams['status'] = status;
      }

      final res = await _api.get('/clients', queryParams: queryParams.isNotEmpty ? queryParams : null);
      if (res['clients'] != null) {
        _clients = (res['clients'] as List)
            .map((item) => ClientModel.fromJson(item))
            .toList();
      }
      await fetchStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createClient({
    required String name,
    required String slug,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post('/clients', {
        'name': name,
        'slug': slug,
        'adminName': adminName,
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
      });
      await fetchClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int clientId, String newStatus) async {
    try {
      await _api.patch('/clients/$clientId/status', {'status': newStatus});
      await fetchClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      await _api.delete('/clients/$clientId');
      await fetchClients();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
