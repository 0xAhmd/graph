// lib/features/profile/presentation/pages/privacy_settings_page.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/private/presentation/cubit/follow_request_cubit.dart';
import 'package:ig_mate/features/private/presentation/cubit/privacy_cubit.dart';

class PrivacySettingsPage extends StatefulWidget {
  final String userId;

  const PrivacySettingsPage({super.key, required this.userId});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrivacyCubit>().loadPrivacySettings(widget.userId);
    context.read<FollowRequestCubit>().loadFollowRequests(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocBuilder<PrivacyCubit, PrivacyState>(
        builder: (context, privacyState) {
          return BlocBuilder<FollowRequestCubit, FollowRequestState>(
            builder: (context, requestState) {
              if (privacyState is PrivacyLoading) {
                return const Center(child: CupertinoActivityIndicator());
              }

              if (privacyState is PrivacyError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        privacyState.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<PrivacyCubit>().loadPrivacySettings(
                            widget.userId,
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (privacyState is PrivacyLoaded) {
                final settings = privacyState.privacySettings;
                final incomingCount = requestState is FollowRequestLoaded
                    ? requestState.incomingCount
                    : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Private Account Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    settings.isPrivate
                                        ? Icons.lock
                                        : Icons.lock_open,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Private Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch.adaptive(
                                    value: settings.isPrivate,
                                    onChanged: (value) {
                                      _showPrivacyConfirmationDialog(
                                        context,
                                        value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                settings.isPrivate
                                    ? 'Your account is private. Only followers can see your posts and stories.'
                                    : 'Your account is public. Anyone can see your posts and stories.',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Follow Requests Section (only show if private)
                      if (settings.isPrivate) ...[
                        Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.person_add,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Follow Requests'),
                            subtitle: incomingCount > 0
                                ? Text('$incomingCount pending requests')
                                : const Text('No pending requests'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (incomingCount > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      incomingCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/follow-requests',
                                arguments: widget.userId,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Privacy Information
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Privacy Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                'Public Account',
                                'Anyone can follow you, see your posts, and view your stories.',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoItem(
                                'Private Account',
                                'Only approved followers can see your posts and stories. New followers need your approval.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return const Center(child: Text('Something went wrong'));
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  void _showPrivacyConfirmationDialog(BuildContext context, bool newValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            newValue ? 'Make Account Private?' : 'Make Account Public?',
          ),
          content: Text(
            newValue
                ? 'Your account will be private. Only approved followers will be able to see your posts and stories.'
                : 'Your account will be public. Anyone will be able to see your posts and stories.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<PrivacyCubit>().updatePrivacySettings(
                  userId: widget.userId,
                  isPrivate: newValue,
                );
              },
              child: Text(newValue ? 'Make Private' : 'Make Public'),
            ),
          ],
        );
      },
    );
  }
}
