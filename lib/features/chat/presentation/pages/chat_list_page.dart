// // lib/features/chat/presentation/pages/chat_list_page.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../layout/constrained_scaffold.dart';
// import '../../../auth/presentation/cubit/cubit/auth_cubit.dart';
// import '../../domain/entities/chat_user.dart';
// import '../cubit/chat_cubit.dart';
// import '../widgets/chat_user_tile.dart';
// import 'chat_page.dart';

// class ChatListPage extends StatefulWidget {
//   const ChatListPage({super.key});

//   @override
//   State<ChatListPage> createState() => _ChatListPageState();
// }

// class _ChatListPageState extends State<ChatListPage> {
//   @override
//   void initState() {
//     super.initState();
//     _loadAvailableUsers();
//   }

//   void _loadAvailableUsers() {
//     final currentUser = context.read<AuthCubit>().currentUser;
//     if (currentUser != null) {
//       context.read<ChatCubit>().loadAvailableUsers(currentUser.uid);
//     }
//   }

//   void _navigateToChat(ChatUser user) async {
//     final currentUser = context.read<AuthCubit>().currentUser;
//     if (currentUser != null) {
//       // Start or get existing conversation
//       await context.read<ChatCubit>().startConversation(
//         currentUser.uid,
//         user.uid,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedScaffold(
//       appBar: AppBar(
//         title: const Text('Direct Messages'),
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
//         titleTextStyle: TextStyle(
//           color: Theme.of(context).colorScheme.primary,
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       body: BlocConsumer<ChatCubit, ChatState>(
//         listener: (context, state) {
//           if (state is ChatError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(state.message),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           } else if (state is ChatConversationCreated) {
//             // Navigate to chat page
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     ChatPage(conversation: state.conversation),
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is ChatLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (state is ChatUsersLoaded) {
//             if (state.users.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.chat_bubble_outline,
//                       size: 80,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.primary.withOpacity(0.5),
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No users available to chat with',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.primary.withOpacity(0.7),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Follow some users to start chatting!',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Theme.of(
//                           context,
//                         ).colorScheme.primary.withOpacity(0.5),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             return RefreshIndicator(
//               onRefresh: () async => _loadAvailableUsers(),
//               child: ListView.builder(
//                 padding: const EdgeInsets.all(8),
//                 itemCount: state.users.length,
//                 itemBuilder: (context, index) {
//                   final user = state.users[index];
//                   return ChatUserTile(
//                     user: user,
//                     onTap: () => _navigateToChat(user),
//                   );
//                 },
//               ),
//             );
//           }

//           if (state is ChatError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.error_outline,
//                     size: 80,
//                     color: Colors.red.withOpacity(0.7),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Something went wrong',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     state.message,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Theme.of(
//                         context,
//                       ).colorScheme.primary.withOpacity(0.7),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _loadAvailableUsers,
//                     child: const Text('Try Again'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           // Initial state or unknown state
//           return const Center(child: CircularProgressIndicator());
//         },
//       ),
//     );
//   }
// }
