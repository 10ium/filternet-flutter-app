import 'package:flutter/material.dart'; // CORRECTED import statement
import 'tools/traceroute_screen.dart';

// A data class for our tools
class ToolInfo {
  final String title;
  final String description;
  final IconData icon;
  final Widget? targetScreen;

  ToolInfo({
    required this.title,
    required this.description,
    required this.icon,
    this.targetScreen,
  });
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ToolInfo> tools = [
      ToolInfo(
        title: 'Traceroute',
        description: 'مسیر بسته‌های شبکه تا مقصد را ردیابی کنید',
        icon: Icons.route,
        targetScreen: const TracerouteScreen(),
      ),
      ToolInfo(
        title: 'تست سرعت',
        description: 'سرعت دانلود و آپلود اینترنت خود را بسنجید',
        icon: Icons.speed,
        targetScreen: null,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ابزارهای شبکه'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final isEnabled = tool.targetScreen != null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: ListTile(
              leading: Icon(tool.icon, size: 32),
              title: Text(tool.title),
              subtitle: Text(tool.description),
              trailing: isEnabled ? const Icon(Icons.chevron_right) : null,
              enabled: isEnabled,
              onTap: isEnabled
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => tool.targetScreen!),
                      );
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }
}
