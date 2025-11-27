import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Voice Assistant',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Talk to your AI companion',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Voice Interface
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        // Microphone Button
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.primary, theme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 48,
                            ),
                            onPressed: () {
                              print('Voice recording started'); // Debug print
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to speak',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything about your mental health',
                          style: TextStyle(
                            color: theme.text.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Commands
                  Text(
                    'Quick Commands',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCommandCard(theme, 'How am I feeling today?', Icons.favorite),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'What tasks do I have?', Icons.check_box),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'Tell me a joke', Icons.sentiment_very_satisfied),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'Help me relax', Icons.spa),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandCard(AppTheme theme, String command, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              command,
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: theme.text.withOpacity(0.5),
            size: 16,
          ),
        ],
      ),
    );
  }
}