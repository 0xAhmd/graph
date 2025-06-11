import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/core/themes/theme_cubit.dart';
import 'package:ig_mate/features/settings/account_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.read<ThemeCubit>();
    bool isDarkMode = themeCubit.isDark;
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Settings", style: TextStyle(fontSize: 18)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: ListTile(
              title: Text(
                "Dark Mode",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              trailing: CupertinoSwitch(
                value: isDarkMode,
                onChanged: (value) {
                  themeCubit.toggle();
                },
              ),
            ),
          ),
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
}
