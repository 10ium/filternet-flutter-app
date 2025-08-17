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
    // Use the object's key for easier deletion later.
    // The key is the timestamp which is unique enough for our purpose.
    await _historyBox!.put(result.timestamp.toIso8601String(), result);
  }

  Future<List<DomainCheckResult>> getHistory() async {
    if (_historyBox == null) await init();
    
    final sortedKeys = _historyBox!.keys.toList().cast<String>()
      ..sort((a, b) => b.compareTo(a));
      
    return sortedKeys.map((key) {
      final item = _historyBox!.get(key)!;
      // The key from Hive is automatically associated with the HiveObject.
      return item;
    }).toList();
  }
  
  // New method to delete a single item
  Future<void> deleteFromHistory(DomainCheckResult result) async {
    if (_historyBox == null) await init();
    // HiveObject provides a convenient delete method.
    await result.delete();
  }

  Future<void> clearHistory() async {
    if (_historyBox == null) await init();
    await _historyBox!.clear();
  }
}