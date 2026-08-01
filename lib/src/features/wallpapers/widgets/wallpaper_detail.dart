import 'package:flutter/material.dart';

import '../../../models/wallpaper_photo.dart';
import '../../../services/external_links.dart';
import 'photo_color.dart';

class WallpaperDetail extends StatefulWidget {
  const WallpaperDetail({
    super.key,
    required this.photo,
    required this.initiallyLiked,
    required this.onToggleLike,
  });

  final WallpaperPhoto photo;
  final bool initiallyLiked;
  final VoidCallback onToggleLike;

  static Future<void> show(
    BuildContext context, {
    required WallpaperPhoto photo,
    required bool initiallyLiked,
    required VoidCallback onToggleLike,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => WallpaperDetail(
          photo: photo,
          initiallyLiked: initiallyLiked,
          onToggleLike: onToggleLike,
        ),
      ),
    );
  }

  @override
  State<WallpaperDetail> createState() => _WallpaperDetailState();
}

class _WallpaperDetailState extends State<WallpaperDetail> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: photoPlaceholderColor(photo.averageColorHex),
                child: Semantics(
                  image: true,
                  label: photo.accessibleDescription,
                  child: ExcludeSemantics(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        photo.sources.large2x,
                        fit: BoxFit.contain,
                        excludeFromSemantics: true,
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const SizedBox.expand();
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image_outlined, size: 52),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton.filled(
                tooltip: 'Close details',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filledTonal(
                tooltip: _isLiked ? 'Unlike photo' : 'Like photo',
                onPressed: _toggleLike,
                icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xF2000000)],
                  ),
                ),
                child: SingleChildScrollView(
                  key: const Key('wallpaper-detail-metadata-scroll'),
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          photo.accessibleDescription,
                          key: const Key('wallpaper-detail-description'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _openLink(photo.photographerUrl),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Photo by ${photo.photographer} on Pexels',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${photo.width} × ${photo.height} pixels',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _openLink(photo.pexelsUrl),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.open_in_new),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Open photo on Pexels',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
    widget.onToggleLike();
  }

  Future<void> _openLink(Uri uri) async {
    final opened = await openPexelsLink(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this Pexels link.')),
      );
    }
  }
}
