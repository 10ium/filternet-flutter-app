import 'package.flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_traceroute/flutter_traceroute.dart';

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  
  bool _isTracing = false;
  final List<String> _traceResults = [];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
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

    var traceroute = Traceroute();
    traceroute.trace(host).listen((line) {
      // Callback for each line of traceroute output
      setState(() {
        _traceResults.add(line);
        // Auto-scroll to the bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }).onDone(() {
      // When traceroute is finished
      setState(() {
        _traceResults.add('🏁 ردیابی کامل شد.');
        _isTracing = false;
      });
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
          // --- INPUT SECTION ---
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

          // --- RESULTS SECTION ---
          Expanded(
            child: Container(
              color: Colors.black.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _traceResults.isEmpty
                  ? const Center(child: Text('برای شروع، یک آدرس وارد کرده و ردیابی را آغاز کنید.'))
                  : ListView.builder(
                      controller: _scrollController,
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
