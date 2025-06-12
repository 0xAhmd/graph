import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ig_mate/features/profile/presentation/widgets/user_list_tile.dart';
import 'package:ig_mate/features/search/presentation/cubit/search_cubit.dart';
import 'package:ig_mate/layout/constrained_scaffold.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  late final searchCubit = context.read<SearchCubit>();

  void onSearchChanges() {
    final query = searchController.text;
    searchCubit.filter(query);
  }

  @override
  void initState() {
    searchController.addListener(onSearchChanges);
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedScaffold(
      appBar: AppBar(
        centerTitle: true,
        title: TextField(
          maxLines: 2,

          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
          controller: searchController,
          decoration: InputDecoration(
            hint: const Text("Search users..."),
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state is SearchLoading) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (state is SearchError) {
            return Center(child: Text("Error: ${state.errMessage}"));
          } else if (state is SearchLoaded) {
            if (state.profiles.isEmpty) {
              return Center(
                child: Text(
                  "No Users Found...",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: state.profiles.length,
              itemBuilder: (context, index) {
                final profile = state.profiles[index];

                return UserListTile(profileUserEntity: profile);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}
