import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/check_result.dart';

class HistoryService {
  static const String _historyBoxName = 'domain_check_history';

  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  Box<DomainCheckResult>? _historyBox;

  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    // CORRECTED typo in variable name below
    await Hive.initFlutter(appDocumentDir.path);

    if (!Hive.isAdapterRegistered(DomainCheckResultAdapter().typeId)) {
      Hive.registerAdapter(DomainCheckResultAdapter());
    }
    if (!Hive.isAdapterRegistered(CheckStatusAdapter().typeId)) {
      Hive.registerAdapter(CheckStatusAdapter());
    }

    _historyBox = await Hive.openBox<DomainCheckResult>(_historyBoxName);
  }

  Future<void> addToHistory(DomainCheckResult result) async {
    if (_historyBox == null) await init();
    await _historyBox!.put(DateTime.now().toIso8601String(), result);
  }

  Future<List<DomainCheckResult>> getHistory() async {
    if (_historyBox == null) await init();
    
    final sortedKeys = _historyBox!.keys.toList().cast<String>()
      ..sort((a, b) => b.compareTo(a));
      
    return sortedKeys.map((key) => _historyBox!.get(key)!).toList();
  }

  Future<void> clearHistory() async {
    if (_historyBox == null) await init();
    await _historyBox!.clear();
  }
}
