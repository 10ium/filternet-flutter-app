import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/result_card.dart';
import '../widgets/share_button.dart';
import 'history_screen.dart'; // This is now uncommented

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _runCheck() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    final domain = _textController.text.trim();
    if (domain.isNotEmpty) {
      // Use 'read' inside a callback to call methods
      context.read<AppProvider>().checkDomain(domain);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use 'watch' in the build method to listen for state changes
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('فیلترنت'),
        centerTitle: true,
        // The actions section is now active
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'نمایش تاریخچه',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- INPUT SECTION ---
            TextField(
              controller: _textController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'آدرس دامنه را وارد کنید',
                hintText: 'example.com',
              ),
              onSubmitted: (_) => _runCheck(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: appProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(appProvider.isLoading ? 'در حال بررسی...' : 'بررسی وضعیت'),
              onPressed: appProvider.isLoading ? null : _runCheck,
            ),

            const SizedBox(height: 24),
            
            // --- RESULTS SECTION ---
            if (appProvider.currentDomain != null)
              _buildResultsSection(appProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(AppProvider appProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'نتایج برای: ${appProvider.currentDomain}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...appProvider.currentResults.map((result) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ResultCard(result: result),
          );
        }).toList(),

        if (!appProvider.isLoading)
           Padding(
             padding: const EdgeInsets.only(top: 16.0),
             child: ShareButton(
                domain: appProvider.currentDomain!,
                results: appProvider.currentResults,
              ),
           ),
      ],
    );
  }
}
