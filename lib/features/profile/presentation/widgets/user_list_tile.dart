import 'package:flutter/material.dart';
import '../../domain/entities/profile_user.dart';
import '../pages/profile_page.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({super.key, required this.profileUserEntity});
  final ProfileUserEntity profileUserEntity;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5),
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: ListTile(
        title: Text(profileUserEntity.name),
        subtitle: Text(profileUserEntity.email),

        leading: const Icon(Icons.person),
        trailing: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(uid: profileUserEntity.uid),
            ),
          ),
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
