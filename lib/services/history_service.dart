import 'package:hive_flutter/hive_flutter.dart';
// CORRECTED the malformed import statement below
import 'package:path_provider/path_provider.dart';
import '../models/check_result.dart';

class HistoryService {
  static const String _historyBoxName = 'domain_check_history';

  // A singleton pattern to ensure only one instance of the service
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  Box<DomainCheckResult>? _historyBox;

  Future<void> init() async {
    // Initialize Hive
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentarDir.path);

    // Registering the adapter that we will generate
    if (!Hive.isAdapterRegistered(DomainCheckResultAdapter().typeId)) {
      Hive.registerAdapter(DomainCheckResultAdapter());
    }
    if (!Hive.isAdapterRegistered(CheckStatusAdapter().typeId)) {
      Hive.registerAdapter(CheckStatusAdapter());
    }

    // Open the box
    _historyBox = await Hive.openBox<DomainCheckResult>(_historyBoxName);
  }

  Future<void> addToHistory(DomainCheckResult result) async {
    if (_historyBox == null) await init();
    // Using a timestamp-based key to ensure uniqueness and order
    await _historyBox!.put(DateTime.now().toIso8601String(), result);
  }

  Future<List<DomainCheckResult>> getHistory() async {
    if (_historyBox == null) await init();
    
    // Sort the results by timestamp in descending order (newest first)
    final sortedKeys = _historyBox!.keys.toList().cast<String>()
      ..sort((a, b) => b.compareTo(a));
      
    return sortedKeys.map((key) => _historyBox!.get(key)!).toList();
  }

  Future<void> clearHistory() async {
    if (_historyBox == null) await init();
    await _historyBox!.clear();
  }
}
