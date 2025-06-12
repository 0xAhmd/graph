import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ig_mate/features/auth/presentation/cubit/cubit/auth_cubit.dart';
import 'package:ig_mate/features/settings/block_list_page.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Account Settings"),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          // Handle different states after delete account attempt
          if (state is AuthError) {
            Fluttertoast.showToast(
              msg: "Error deleting account ${state.errMessage}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.red, // or Colors.green, etc.
              textColor: Colors.white,
            );
          } else if (state is AccountDeleted) {
            // Account deleted successfully, navigate to login/welcome screen
            Fluttertoast.showToast(
              msg: "Account Deleted Successfully",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green, // or Colors.green, etc.
              textColor: Colors.white,
            );
            Navigator.of(context).pushReplacementNamed('/login');
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockListPage(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      child: ListTile(
                        title: Text(
                          "Blocked Users ",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Delete Account Button
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _showDeleteConfirmationDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isLoading ? Colors.grey : Colors.redAccent,
                      ),
                      child: isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Text(
                              "Delete Account",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Warning text
                  const Text(
                    "This action cannot be undone. All your data will be permanently deleted.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            "Delete Account",
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          content: Text(
            "Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.",

            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Use the original context here, not dialogContext
                context.read<AuthCubit>().deleteAccount();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
