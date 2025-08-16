import 'package:flutter/material.dart';
import '../models/check_result.dart';
import '../services/check_service.dart';
import '../services/history_service.dart';

class AppProvider extends ChangeNotifier {
  final CheckService _checkService = CheckService();
  final HistoryService _historyService = HistoryService();

  // State variables
  bool _isLoading = false;
  String? _currentDomain;
  final List<SingleCheckResult> _currentResults = [];
  List<DomainCheckResult> _history = [];

  // Getters to access state from the UI
  bool get isLoading => _isLoading;
  String? get currentDomain => _currentDomain;
  List<SingleCheckResult> get currentResults => _currentResults;
  List<DomainCheckResult> get history => _history;

  AppProvider() {
    // Load history when the app starts
    loadHistory();
  }

  Future<void> loadHistory() async {
    _history = await _historyService.getHistory();
    notifyListeners();
  }

  Future<void> checkDomain(String domain) async {
    if (domain.isEmpty) return;

    // 1. Set loading state and clear previous results
    _isLoading = true;
    _currentDomain = domain;
    _currentResults.clear();
    _currentResults.addAll([
      SingleCheckResult(title: 'DNS', status: CheckStatus.checking, details: 'در حال بررسی...'),
      SingleCheckResult(title: 'HTTP', status: CheckStatus.checking, details: 'در حال بررسی...'),
      SingleCheckResult(title: 'SNI', status: CheckStatus.checking, details: 'در حال بررسی...'),
    ]);
    notifyListeners();

    // 2. Run all checks in parallel
    final results = await Future.wait([
      _checkService.checkDns(domain),
      _checkService.checkHttp(domain),
      _checkService.checkSni(domain),
    ]);

    // 3. Update results and stop loading
    _currentResults.clear();
    _currentResults.addAll(results);
    _isLoading = false;
    notifyListeners();

    // 4. Save the result to history
    await _saveResultToHistory(domain, results);
  }

  Future<void> _saveResultToHistory(String domain, List<SingleCheckResult> results) async {
    final dnsResult = results[0];
    final httpResult = results[1];
    final sniResult = results[2];

    final historyEntry = DomainCheckResult()
      ..domain = domain
      ..timestamp = DateTime.now()
      ..dnsStatus = dnsResult.status
      ..dnsDetails = dnsResult.details
      ..httpStatus = httpResult.status
      ..httpDetails = httpResult.details
      ..sniStatus = sniResult.status
      ..sniDetails = sniResult.details;

    await _historyService.addToHistory(historyEntry);
    // Reload history to show the new entry at the top
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    _history = [];
    notifyListeners();
  }
}
