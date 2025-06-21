import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileImageViewer extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String heroTag;

  const ProfileImageViewer({
    super.key,
    required this.imageUrl,
    this.size = 160,
    this.heroTag = 'profile-image',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (imageUrl.isNotEmpty) {
          showDialog(
            context: context,
            barrierDismissible: true,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (context) {
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),
                    Center(
                      child: Hero(
                        tag: heroTag,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
      child: Hero(
        tag: heroTag,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder: (context, imageProvider) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: const CupertinoActivityIndicator(),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Theme.of(context).colorScheme.secondary,
            ),
            child: Icon(
              Icons.person,
              size: size / 2.3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
