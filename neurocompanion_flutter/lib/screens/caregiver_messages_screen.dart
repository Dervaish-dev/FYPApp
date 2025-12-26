import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class CaregiverMessagesScreen extends StatefulWidget {
  const CaregiverMessagesScreen({super.key});

  @override
  State<CaregiverMessagesScreen> createState() => _CaregiverMessagesScreenState();
}

class _CaregiverMessagesScreenState extends State<CaregiverMessagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          appBar: AppBar(
            backgroundColor: theme.card,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Messages',
              style: TextStyle(color: theme.text),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: theme.text.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Messaging Feature',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coming soon',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
