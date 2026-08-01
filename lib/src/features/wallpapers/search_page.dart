import 'package:flutter/material.dart';

import '../../models/wallpaper_photo.dart';
import 'wallpaper_controller.dart';
import 'widgets/page_header.dart';
import 'widgets/pexels_attribution.dart';
import 'widgets/photo_color.dart';
import 'widgets/wallpaper_grid.dart';
import 'widgets/wallpaper_page_scroll_view.dart';
import 'widgets/wallpaper_status.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.controller});

  final WallpaperController controller;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _queryController = TextEditingController();
  late PhotoSearchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.controller.searchFilters;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final controller = widget.controller;
    final headerWidgets = <Widget>[
      const PageHeader(
        title: 'Search',
        subtitle: 'Find photos by subject, shape, size, and color.',
      ),
      PexelsAttribution(rateLimit: controller.rateLimit),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: SearchBar(
          controller: _queryController,
          hintText: 'Mountains, abstract, night…',
          leading: const Icon(Icons.search),
          trailing: [
            IconButton(
              tooltip: 'Search photos',
              onPressed: _submitSearch,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
          onSubmitted: (_) => _submitSearch(),
          textInputAction: TextInputAction.search,
        ),
      ),
      _FilterSummary(filters: _filters, onPressed: _showFilters),
      const SizedBox(height: 8),
    ];

    if (controller.isSearching) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.searchError case final error?) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        child: WallpaperStatus(
          icon: Icons.cloud_off_outlined,
          title: 'Search failed',
          message: error,
          actionLabel: 'Try again',
          onAction: () => controller.search(
            controller.lastSearchQuery,
            filters: controller.searchFilters,
          ),
        ),
      );
    }

    if (!controller.hasSearched) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        child: const WallpaperStatus(
          icon: Icons.travel_explore,
          title: 'What are you looking for?',
          message: 'Try a color, place, style, or subject.',
        ),
      );
    }

    if (controller.searchPhotos.isEmpty) {
      return WallpaperPageScrollView(
        headerWidgets: headerWidgets,
        child: const WallpaperStatus(
          icon: Icons.search_off,
          title: 'No photos found',
          message: 'Try a broader phrase or fewer filters.',
        ),
      );
    }

    return WallpaperGrid(
      headerWidgets: headerWidgets,
      photos: controller.searchPhotos,
      isLiked: controller.isLiked,
      onToggleLike: controller.toggleLike,
      hasMore: controller.hasMoreSearch,
      isLoadingMore: controller.isLoadingMoreSearch,
      loadMoreError: controller.searchLoadMoreError,
      onLoadMore: controller.loadMoreSearch,
      onRefresh: () => controller.search(
        controller.lastSearchQuery,
        filters: controller.searchFilters,
      ),
      orientation: controller.searchFilters.orientation,
    );
  }

  void _submitSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.controller.search(_queryController.text, filters: _filters);
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<PhotoSearchFilters>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SearchFilterSheet(initialFilters: _filters),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _filters = result);
    if (_queryController.text.trim().isNotEmpty) {
      await widget.controller.search(_queryController.text, filters: _filters);
    }
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.filters, required this.onPressed});

  final PhotoSearchFilters filters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filters.orientation != null) filters.orientation!.label,
      if (filters.minimumSize != null) filters.minimumSize!.label,
      if (filters.color != null) filters.color!.label,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: Text(
              filters.activeCount == 0
                  ? 'Filters'
                  : 'Filters · ${filters.activeCount}',
            ),
            onPressed: onPressed,
          ),
          for (final label in labels) ...[
            const SizedBox(width: 8),
            Chip(label: Text(label)),
          ],
        ],
      ),
    );
  }
}

class _SearchFilterSheet extends StatefulWidget {
  const _SearchFilterSheet({required this.initialFilters});

  final PhotoSearchFilters initialFilters;

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late PhotoOrientation? _orientation;
  late PhotoSize? _minimumSize;
  late PhotoColor? _color;

  @override
  void initState() {
    super.initState();
    _orientation = widget.initialFilters.orientation;
    _minimumSize = widget.initialFilters.minimumSize;
    _color = widget.initialFilters.color;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Search filters',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _FilterDropdown<PhotoOrientation>(
            label: 'Orientation',
            value: _orientation,
            values: PhotoOrientation.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => setState(() => _orientation = value),
          ),
          const SizedBox(height: 16),
          _FilterDropdown<PhotoSize>(
            label: 'Minimum size',
            value: _minimumSize,
            values: PhotoSize.values,
            itemLabel: (value) => value.label,
            onChanged: (value) => setState(() => _minimumSize = value),
          ),
          const SizedBox(height: 20),
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Any'),
                selected: _color == null,
                onSelected: (_) => setState(() => _color = null),
              ),
              for (final color in PhotoColor.values)
                ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: photoPlaceholderColor(color.swatchHex),
                    child: color == PhotoColor.white
                        ? const Icon(Icons.circle_outlined, size: 18)
                        : null,
                  ),
                  label: Text(color.label),
                  selected: _color == color,
                  onSelected: (_) => setState(() => _color = color),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(const PhotoSearchFilters());
                },
                child: const Text('Clear all'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(
                    PhotoSearchFilters(
                      orientation: _orientation,
                      minimumSize: _minimumSize,
                      color: _color,
                    ),
                  );
                },
                child: const Text('Show results'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isExpanded: true,
          items: [
            DropdownMenuItem<T?>(value: null, child: const Text('Any')),
            for (final item in values)
              DropdownMenuItem<T?>(value: item, child: Text(itemLabel(item))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
