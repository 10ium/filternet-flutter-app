import 'package.flutter/material.dart';
import 'package.flutter/services.dart';
import 'package:simple_tracert/simple_tracert.dart'; // Replaced the old import

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final _textController = TextEditingController();
  
  bool _isTracing = false;
  final List<String> _traceResults = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _runTraceroute() async {
    FocusScope.of(context).unfocus();
    final host = _textController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isTracing = true;
      _traceResults.clear();
      _traceResults.add('🚀 شروع ردیابی مسیر به سمت $host ...');
    });

    final tracert = SimpleTracert();

    try {
      final result = await tracert.execute(host, timeout: 5);

      final formattedResults = <String>[];
      if (result.destIp != null) {
        formattedResults.add('IP مقصد: ${result.destIp}');
      }
      formattedResults.add('-----------------------------------');

      for (final hop in result.hops) {
        final rtt = hop.rtt1.isNotEmpty ? '${hop.rtt1} ms' : '*';
        final ip = hop.ip.isNotEmpty ? hop.ip : 'Request timed out.';
        formattedResults.add('${hop.hop.toString().padLeft(2)}.   $rtt   $ip');
      }

      setState(() {
        _traceResults.clear(); // Clear the "starting..." message
        _traceResults.addAll(formattedResults);
        _traceResults.add('-----------------------------------');
        _traceResults.add('🏁 ردیابی کامل شد.');
      });

    } catch (e) {
      setState(() {
        _traceResults.add('❌ خطایی رخ داد:');
        _traceResults.add(e.toString());
      });
    } finally {
      setState(() {
        _isTracing = false;
      });
    }
  }
  
  void _copyResultsToClipboard() {
    final resultsText = _traceResults.join('\n');
    Clipboard.setData(ClipboardData(text: resultsText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نتایج در کلیپ‌بورد کپی شد.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceroute'),
        actions: [
          if (_traceResults.isNotEmpty && !_isTracing)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'کپی نتایج',
              onPressed: _copyResultsToClipboard,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _textController,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'آدرس دامنه یا IP',
                    hintText: 'google.com',
                  ),
                  onSubmitted: (_) => _isTracing ? null : _runTraceroute(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _isTracing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3))
                        : const Icon(Icons.route),
                    label: Text(_isTracing ? 'در حال ردیابی...' : 'شروع ردیابی'),
                    onPressed: _isTracing ? null : _runTraceroute,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _traceResults.isEmpty
                  ? const Center(child: Text('برای شروع، یک آدرس وارد کرده و ردیابی را آغاز کنید.'))
                  : ListView.builder(
                      itemCount: _traceResults.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _traceResults[index],
                          style: const TextStyle(fontFamily: 'monospace', fontSiz
