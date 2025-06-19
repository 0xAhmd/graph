// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/themes/theme_cubit.dart';
import 'package:ig_mate/features/settings/account_settings_page.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Settings", style: TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          // Theme Selection Container
          GestureDetector(
            onTap: () => _showThemeSelector(context),
            child: Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  String currentTheme;
                  switch (themeMode) {
                    case ThemeMode.light:
                      currentTheme = "Light Mode";
                      break;
                    case ThemeMode.dark:
                      currentTheme = "Dark Mode";
                      break;
                    case ThemeMode.system:
                      currentTheme = "System Default";
                      break;
                  }

                  return ListTile(
                    title: Text(
                      "Theme",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    subtitle: Text(
                      currentTheme,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.palette_outlined),
                  );
                },
              ),
            ),
          ),

          // Account Settings Container
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsPage(),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondary,
              ),
              child: ListTile(
                title: Text(
                  "Account Settings",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Choose Theme',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            // Theme Options
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, currentThemeMode) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System Default'),
                      subtitle: const Text('Follow device theme'),
                      value: ThemeMode.system,
                      groupValue: currentThemeMode,
                      onChanged: (value) {
                        themeCubit.setThemeMode(value!);
                        Navigator.pop(context);
                      },
                      secondary: const Icon(Icons.phone_android),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light Mode'),
                      subtitle: const Text('Always use light theme'),
                      value: ThemeMode.light,
                      groupValue: currentThemeMode,
                      onChanged: (value) {
                        themeCubit.setThemeMode(value!);
                        Navigator.pop(context);
                      },
                      secondary: const Icon(Icons.light_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Always use dark theme'),
                      value: ThemeMode.dark,
                      groupValue: currentThemeMode,
                      onChanged: (value) {
                        themeCubit.setThemeMode(value!);
                        Navigator.pop(context);
                      },
                      secondary: const Icon(Icons.dark_mode),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
