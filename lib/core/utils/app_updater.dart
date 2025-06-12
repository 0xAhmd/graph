// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdater {
  static const String _repoOwner = '0xAhmd';
  static const String _repoName = 'graph';
  static const String _snoozeKey = 'update_snooze_timestamp';
  static const String _hasSnoozedKey = 'update_has_snoozed';
  static const String _cachedVersionKey = 'cached_latest_version';
  static const String _cachedUrlKey = 'cached_latest_url';

  static Future<void> checkForUpdate(BuildContext context) async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();

    final snoozedAt = prefs.getInt(_snoozeKey);
    final hasSnoozed = prefs.getBool(_hasSnoozedKey) ?? false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneWeek = const Duration(days: 7).inMilliseconds;

    final bool isSnoozed =
        hasSnoozed && snoozedAt != null && (now - snoozedAt) < oneWeek;
    final bool snoozeExpired =
        hasSnoozed && snoozedAt != null && (now - snoozedAt) >= oneWeek;

    // Use cache if snoozed and skip dialog
    if (isSnoozed) {
      final cachedVersion = prefs.getString(_cachedVersionKey);
      final cachedUrl = prefs.getString(_cachedUrlKey);
      if (cachedVersion != null && cachedUrl != null) {
        if (_isNewerVersion(packageInfo.version, cachedVersion)) {
          debugPrint('Update snoozed: skipping dialog.');
        }
      }
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final release = json.decode(response.body);
        final latestVersion = release['tag_name'].replaceAll('v', '');
        final apkUrl = release['html_url'];

        await prefs.setString(_cachedVersionKey, latestVersion);
        await prefs.setString(_cachedUrlKey, apkUrl);

        if (_isNewerVersion(packageInfo.version, latestVersion)) {
          if (snoozeExpired) {
            _showForcedUpdateDialog(context, apkUrl);
          } else {
            _showUpdateDialog(context, apkUrl, prefs);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    return latest.compareTo(current) > 0;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String url,
    SharedPreferences prefs,
  ) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      barrierDismissible: true,
      title: 'In App Update',
      text: 'A new version is available. Would you like to update?',
      confirmBtnText: 'Update',
      showCancelBtn: true,
      cancelBtnText: 'Later',
      confirmBtnColor: Theme.of(context).colorScheme.primary,
      onConfirmBtnTap: () {
        launchUrl(Uri.parse(url));
        Navigator.pop(context);
      },
      onCancelBtnTap: () async {
        final shouldSnooze = await _showSnoozeDialog(context);
        if (shouldSnooze) {
          await _snoozeForAWeek(prefs);
        }
        Navigator.pop(context);
      },
    );
  }

  static void _showForcedUpdateDialog(BuildContext context, String url) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      barrierDismissible: false,
      title: 'Update Required',
      text: 'You must update the app to continue.',
      confirmBtnText: 'Update Now',
      showCancelBtn: false,
      confirmBtnColor: Theme.of(context).colorScheme.primary,
      onConfirmBtnTap: () {
        launchUrl(Uri.parse(url));
      },
    );
  }

  static Future<bool> _showSnoozeDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Snooze Update'),
            content: const Text(
              'Would you like to snooze this update for a week? You will be required to update afterward.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, Snooze'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<void> _snoozeForAWeek(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_snoozeKey, now);
    await prefs.setBool(_hasSnoozedKey, true);
  }
}
