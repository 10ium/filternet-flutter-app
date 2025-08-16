import 'dart:async';
import 'dart:io';
import 'package:dart_ping/dart_ping.dart'; // Using the correct, reliable package
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final _textController = TextEditingController();
  
  bool _isTracing = false;
  final List<String> _traceResults = [];
  StreamSubscription<PingData>? _pingSubscription;

  @override
  void dispose() {
    _textController.dispose();
    _pingSubscription?.cancel(); // Cancel any ongoing trace when leaving the screen
    super.dispose();
  }

  Future<void> _runTraceroute() async {
    FocusScope.of(context).unfocus();
    final host = _textController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isTracing = true;
      _traceResults.clear();
      _traceResults.add('🚀 شروع ردیابی مسیر به سمت $host ...');
    });

    String? destinationIp;
    try {
      // First, resolve the hostname to an IP address
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        destinationIp = addresses.first.address;
        setState(() {
          _traceResults.add('IP مقصد: $destinationIp');
          _traceResults.add('-----------------------------------');
        });
      } else {
        throw Exception('آدرس IP برای هاست یافت نشد.');
      }
    } catch (e) {
      setState(() {
        _traceResults.add('❌ خطای DNS: $e');
        _isTracing = false;
      });
      return;
    }

    // Loop through TTLs to perform the trace
    for (int ttl = 1; ttl <= 30; ttl++) {
      if (!_isTracing) break; // Allow user to stop the process (future feature)

      final ping = Ping(destinationIp, count: 1, ttl: ttl, timeout: 5, Rss: true);
      final completer = Completer<String>();

      _pingSubscription = ping.stream.listen((data) {
        String hopInfo = '';
        if (data.response != null) {
          final response = data.response!;
          final rtt = response.time?.inMilliseconds ?? 'N/A';
          hopInfo = '${ttl.toString().padLeft(2)}.   ${rtt} ms   ${response.ip}';
          
          // Check if we reached the destination
          if (response.ip == destinationIp) {
            _isTracing = false; // Stop the trace
          }
        }
        if (data.error != null) {
          hopInfo = '${ttl.toString().padLeft(2)}.   *   Request timed out.';
        }
        
        if (!completer.isCompleted) {
          completer.complete(hopInfo);
        }
      });
      
      // Wait for the ping for this TTL to complete
      final hopResult = await completer.future;
      setState(() {
        _traceResults.add(hopResult);
      });
      
      await _pingSubscription?.cancel();

      // If the last hop was the destination, stop the loop
      if (!_isTracing) {
        break;
      }
    }

    setState(() {
      _traceResults.add('-----------------------------------');
      _traceResults.add('🏁 ردیابی کامل شد.');
      _isTracing = false;
    });
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
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white70),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
