import 'package:flutter/material.dart';

import 'wallpaper_controller.dart';
import 'widgets/page_header.dart';
import 'widgets/pexels_attribution.dart';
import 'widgets/wallpaper_grid.dart';
import 'widgets/wallpaper_page_scroll_view.dart';
import 'widgets/wallpaper_status.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key, required this.controller});

  final WallpaperController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final headerWidgets = <Widget>[
      const PageHeader(
        title: 'Explore',
        subtitle: 'A changing collection curated by Pexels.',
      ),
      PexelsAttribution(rateLimit: controller.rateLimit),
      if (controller.featuredError case final error?
          when controller.featuredPhotos.isNotEmpty)
        _RefreshErrorBanner(message: error, onRetry: controller.loadFeatured),
    ];

    if (controller.isLoadingFeatured && controller.featuredPhotos.isEmpty) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.featuredError case final error?
        when controller.featuredPhotos.isEmpty) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        onRefresh: controller.loadFeatured,
        child: WallpaperStatus(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load wallpapers',
          message: error,
          actionLabel: 'Try again',
          onAction: controller.loadFeatured,
        ),
      );
    }

    if (controller.featuredPhotos.isEmpty) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        onRefresh: controller.loadFeatured,
        child: WallpaperStatus(
          icon: Icons.image_not_supported_outlined,
          title: 'No wallpapers found',
          message: 'Pull to refresh or try again in a moment.',
          actionLabel: 'Refresh',
          onAction: controller.loadFeatured,
        ),
      );
    }

    return WallpaperGrid(
      headerWidgets: headerWidgets,
      photos: controller.featuredPhotos,
      isLiked: controller.isLiked,
      onToggleLike: controller.toggleLike,
      hasMore: controller.hasMoreFeatured,
      isLoadingMore: controller.isLoadingMoreFeatured,
      loadMoreError: controller.featuredLoadMoreError,
      onLoadMore: controller.loadMoreFeatured,
      onRefresh: controller.loadFeatured,
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Could not refresh photos. $message',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Could not refresh photos',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Retry refresh',
                  color: colors.onErrorContainer,
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
