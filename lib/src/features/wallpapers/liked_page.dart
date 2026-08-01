import 'package:flutter/material.dart';

import 'wallpaper_controller.dart';
import 'widgets/page_header.dart';
import 'widgets/wallpaper_grid.dart';
import 'widgets/wallpaper_page_scroll_view.dart';
import 'widgets/wallpaper_status.dart';

class LikedPage extends StatelessWidget {
  const LikedPage({super.key, required this.controller});

  final WallpaperController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          const headerWidgets = <Widget>[
            PageHeader(
              title: 'Likes',
              subtitle: 'Saved for this session only.',
            ),
          ];

          if (controller.likedPhotos.isEmpty) {
            return const WallpaperPageScrollView(
              headerWidgets: headerWidgets,
              child: WallpaperStatus(
                icon: Icons.favorite_border,
                title: 'Nothing liked yet',
                message:
                    'Tap a heart or double-tap a photo. Likes reset when the app closes.',
              ),
            );
          }

          return WallpaperGrid(
            headerWidgets: headerWidgets,
            photos: controller.likedPhotos,
            isLiked: controller.isLiked,
            onToggleLike: controller.toggleLike,
            hasMore: false,
            isLoadingMore: false,
          );
        },
      ),
    );
  }
}
