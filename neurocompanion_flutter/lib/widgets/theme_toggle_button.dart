import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? color;
  
  const ThemeToggleButton({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.currentTheme.name == 'Midnight Dark';
        final theme = themeProvider.currentTheme;

        return IconButton(
          onPressed: () {
            if (isDark) {
              themeProvider.setTheme('ocean');
            } else {
              themeProvider.setTheme('midnight');
            }
          },
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: color ?? theme.text,
          ),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}
