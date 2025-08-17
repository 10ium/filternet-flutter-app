import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileOutput extends LogOutput {
  final File file;
  FileOutput({required this.file});

  @override
  void output(OutputEvent event) {
    file.writeAsStringSync(event.lines.join('\n') + '\n', mode: FileMode.append);
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  late Logger _logger;
  late File _logFile;
  static const String _logFileName = 'app_logs.txt';

  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/$_logFileName');

    // Ensure the file exists
    if (!await _logFile.exists()) {
      await _logFile.create(recursive: true);
    }

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0, // No method calls in log
        errorMethodCount: 5, // Print 5 method calls in error logs
        lineLength: 80, // Wrap messages
        colors: false, // No colors in file
        printEmojis: false, // No emojis in file
        printTime: true, // Print time for log messages
      ),
      output: FileOutput(file: _logFile),
      // Set level to Verbose to capture all logs (fine-grained control)
      level: Level.verbose,
    );
  }

  Logger get logger => _logger;

  Future<String> getLogs() async {
    if (!await _logFile.exists()) {
      return 'No logs available.';
    }
    return _logFile.readAsString();
  }

  Future<void> clearLogs() async {
    if (await _logFile.exists()) {
      await _logFile.writeAsString(''); // Clear content
    }
  }

  // Example of using the logger
  void debug(String message, [dynamic error, StackTrace? stackTrace]) => _logger.d(message, error, stackTrace);
  void info(String message, [dynamic error, StackTrace? stackTrace]) => _logger.i(message, error, stackTrace);
  void warning(String message, [dynamic error, StackTrace? stackTrace]) => _logger.w(message, error, stackTrace);
  void error(String message, [dynamic error, StackTrace? stackTrace]) => _logger.e(message, error, stackTrace);
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) => _logger.f(message, error, stackTrace);
}