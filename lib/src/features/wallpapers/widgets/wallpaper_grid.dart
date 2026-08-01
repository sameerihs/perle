import 'package:flutter/material.dart';

import '../../../models/wallpaper_photo.dart';
import 'photo_color.dart';
import 'wallpaper_detail.dart';

class WallpaperGrid extends StatelessWidget {
  const WallpaperGrid({
    super.key,
    required this.photos,
    required this.isLiked,
    required this.onToggleLike,
    required this.hasMore,
    required this.isLoadingMore,
    this.loadMoreError,
    this.onLoadMore,
    this.onRefresh,
    this.headerWidgets = const [],
    this.orientation = PhotoOrientation.portrait,
  });

  final List<WallpaperPhoto> photos;
  final bool Function(WallpaperPhoto photo) isLiked;
  final ValueChanged<WallpaperPhoto> onToggleLike;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;
  final VoidCallback? onLoadMore;
  final Future<void> Function()? onRefresh;
  final List<Widget> headerWidgets;
  final PhotoOrientation? orientation;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        for (final header in headerWidgets) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columnCount = switch (constraints.crossAxisExtent) {
                >= 900 => 4,
                >= 600 => 3,
                _ => 2,
              };

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: _aspectRatioFor(orientation),
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final photo = photos[index];
                  return WallpaperTile(
                    key: ValueKey(photo.id),
                    photo: photo,
                    isLiked: isLiked(photo),
                    onToggleLike: () => onToggleLike(photo),
                    orientation: orientation,
                  );
                }, childCount: photos.length),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: _PaginationFooter(
            hasMore: hasMore,
            isLoading: isLoadingMore,
            error: loadMoreError,
            onLoadMore: onLoadMore,
          ),
        ),
      ],
    );

    if (onRefresh case final refresh?) {
      return RefreshIndicator(onRefresh: refresh, child: scrollView);
    }
    return scrollView;
  }

  double _aspectRatioFor(PhotoOrientation? orientation) {
    return switch (orientation) {
      PhotoOrientation.portrait => 2 / 3,
      PhotoOrientation.landscape => 16 / 10,
      PhotoOrientation.square => 1,
      null => 1,
    };
  }
}

class WallpaperTile extends StatelessWidget {
  const WallpaperTile({
    super.key,
    required this.photo,
    required this.isLiked,
    required this.onToggleLike,
    this.orientation = PhotoOrientation.portrait,
  });

  final WallpaperPhoto photo;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final PhotoOrientation? orientation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      button: true,
      label:
          '${photo.accessibleDescription}. Photo by ${photo.photographer}. '
          '${isLiked ? 'Liked' : 'Not liked'}.',
      child: GestureDetector(
        onTap: () => _showDetails(context),
        onDoubleTap: onToggleLike,
        onLongPress: () => _showDetails(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: photoPlaceholderColor(photo.averageColorHex),
                child: Image.network(
                  _sourceFor(photo, orientation),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }
                    return const SizedBox.expand();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image_outlined, size: 36),
                    );
                  },
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filledTonal(
                  tooltip: isLiked ? 'Unlike photo' : 'Like photo',
                  onPressed: onToggleLike,
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) {
    return WallpaperDetail.show(
      context,
      photo: photo,
      initiallyLiked: isLiked,
      onToggleLike: onToggleLike,
    );
  }

  String _sourceFor(WallpaperPhoto photo, PhotoOrientation? orientation) {
    return switch (orientation) {
      PhotoOrientation.portrait => photo.sources.portrait,
      PhotoOrientation.landscape => photo.sources.landscape,
      PhotoOrientation.square || null => photo.sources.large,
    };
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.hasMore,
    required this.isLoading,
    required this.error,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoading;
  final String? error;
  final VoidCallback? onLoadMore;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch ((isLoading, error, hasMore)) {
      (true, _, _) => 'Loading more photos',
      (_, final message?, _) =>
        'Could not load more photos. $message. Try again.',
      (_, _, true) => 'More photos are available',
      _ => 'All photos loaded',
    };
    final buttonLabel = switch ((isLoading, error, hasMore)) {
      (true, _, _) => 'Loading more photos…',
      (_, _?, _) => 'Try again',
      (_, _, true) => 'Load more photos',
      _ => 'You’re all caught up',
    };
    final buttonIcon = switch ((isLoading, error, hasMore)) {
      (true, _, _) => const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      (_, _?, _) => const Icon(Icons.refresh),
      (_, _, true) => const Icon(Icons.expand_more),
      _ => const Icon(Icons.check),
    };
    final canLoadMore = !isLoading && (error != null || hasMore);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Semantics(
        key: const Key('pagination-footer'),
        container: true,
        liveRegion: true,
        label: statusLabel,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error case final message?) ...[
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                ],
                FilledButton.tonal(
                  key: const Key('pagination-action'),
                  onPressed: canLoadMore ? onLoadMore : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buttonIcon,
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(buttonLabel, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
