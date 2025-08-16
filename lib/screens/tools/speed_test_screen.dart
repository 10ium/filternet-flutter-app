import 'package:flutter/material.dart';
import 'package:internet_speed_test/callbacks_enum.dart';
import 'package:internet_speed_test/internet_speed_test.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final internetSpeedTest = InternetSpeedTest();

  bool _isTesting = false;
  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  int _downloadCompletionTime = 0;
  int _uploadCompletionTime = 0;
  String _unitText = 'Mbps';

  String _currentTask = 'آماده برای تست';

  void _runSpeedTest() {
    setState(() {
      _isTesting = true;
      _downloadRate = 0;
      _uploadRate = 0;
      _currentTask = 'در حال آماده سازی...';
    });

    internetSpeedTest.startSpeedTest(
      onStarted: () {
        setState(() => _currentTask = 'در حال تست سرعت دانلود...');
      },
      onDownloadComplete: (TestResult download, TestResult cumul) {
        setState(() {
          _downloadRate = download.transferRate;
          _unitText = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _downloadProgress = '100';
          _downloadCompletionTime = cumul.durationInMillis;
        });
      },
      onUploadComplete: (TestResult upload, TestResult cumul) {
        setState(() {
          _uploadRate = upload.transferRate;
          _unitText = upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _uploadProgress = '100';
          _uploadCompletionTime = cumul.durationInMillis;
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          if (data.type == TestType.download) {
            _downloadRate = data.transferRate;
            _downloadProgress = percent.toStringAsFixed(2);
            _currentTask = 'در حال تست سرعت دانلود...';
          } else {
            _uploadRate = data.transferRate;
            _uploadProgress = percent.toStringAsFixed(2);
            _currentTask = 'در حال تست سرعت آپلود...';
          }
        });
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() {
          _isTesting = false;
          _currentTask = 'خطا در انجام تست';
        });
      },
      onCompletion: (TestResult testResult) {
        setState(() {
          _isTesting = false;
          _currentTask = 'تست کامل شد';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تست سرعت'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- GAUGE SECTION ---
            _buildGauge(),
            const SizedBox(height: 32),
            // --- RESULTS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultCard(Icons.download, 'دانلود', _downloadRate),
                _buildResultCard(Icons.upload, 'آپلود', _uploadRate),
              ],
            ),
            const SizedBox(height: 32),
            // --- STATUS TEXT ---
            Text(_currentTask, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 32),
            // --- ACTION BUTTON ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              onPressed: _isTesting ? null : _runSpeedTest,
              child: Text(_isTesting ? 'در حال تست...' : 'شروع تست'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge() {
    double progress = (_isTesting ? (_currentTask.contains('دانلود') ? double.tryParse(_downloadProgress) ?? 0 : double.tryParse(_uploadProgress) ?? 0) : 0) / 100;
    double rate = _currentTask.contains('دانلود') ? _downloadRate : _uploadRate;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade800, width: 8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: Colors.grey.shade700,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rate.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _unitText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(IconData icon, String title, double value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 28),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(2)} $_unitText',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
