import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  final speedTest = FlutterInternetSpeedTest();

  bool _isTesting = false;
  // A flag to know which phase (download/upload) is active
  bool _isDownloadPhase = true; 

  double _downloadRate = 0;
  double _uploadRate = 0;
  double _downloadProgress = 0;
  double _uploadProgress = 0;
  String _unitText = 'Mbps';
  String _statusMessage = 'آماده برای تست';

  void _runSpeedTest() {
    // Reset all states before starting a new test
    setState(() {
      _isTesting = true;
      _isDownloadPhase = true;
      _downloadRate = 0;
      _uploadRate = 0;
      _downloadProgress = 0;
      _uploadProgress = 0;
      _statusMessage = 'در حال انتخاب سرور...';
    });

    speedTest.startTesting(
      onDefaultServerSelectionDone: (client) {
        setState(() {
          _statusMessage = 'در حال تست سرعت دانلود...';
        });
      },
      onDownloadComplete: (TestResult data) {
        setState(() {
          _downloadRate = data.transferRate;
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _isDownloadPhase = false; // Switch to upload phase
          _statusMessage = 'در حال تست سرعت آپلود...';
        });
      },
      onUploadComplete: (TestResult data) {
        setState(() {
          _uploadRate = data.transferRate;
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          _isTesting = false; // Test is finished
          _statusMessage = 'تست کامل شد.';
        });
      },
      onProgress: (double percent, TestResult data) {
        setState(() {
          _unitText = data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
          if (_isDownloadPhase) {
            _downloadRate = data.transferRate;
            _downloadProgress = percent / 100;
          } else {
            // Upload phase
            _uploadRate = data.transferRate;
            _uploadProgress = percent / 100;
          }
        });
      },
      onError: (String errorMessage, String speedTestError) {
        setState(() {
          _isTesting = false;
          _statusMessage = 'خطا در انجام تست. لطفا دوباره تلاش کنید.';
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
            _buildGauge(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResultCard(Icons.download_rounded, 'دانلود', _downloadRate),
                _buildResultCard(Icons.upload_rounded, 'آپلود', _uploadRate),
              ],
            ),
            const SizedBox(height: 32),
            Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 32),
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
    double progress = _isDownloadPhase ? _downloadProgress : _uploadProgress;
    double rate = _isDownloadPhase ? _downloadRate : _uploadRate;

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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade300),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rate.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
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
