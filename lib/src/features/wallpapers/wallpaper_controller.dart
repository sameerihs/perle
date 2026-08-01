import 'package:flutter/foundation.dart';

import '../../data/wallpaper_repository.dart';
import '../../models/wallpaper_photo.dart';

class WallpaperController extends ChangeNotifier {
  WallpaperController(this._repository);

  static const pageSize = 24;

  final WallpaperRepository _repository;
  final Map<int, WallpaperPhoto> _likedById = <int, WallpaperPhoto>{};

  List<WallpaperPhoto> _featuredPhotos = const [];
  List<WallpaperPhoto> _searchPhotos = const [];
  int? _featuredNextPage;
  int? _searchNextPage;
  bool _isLoadingFeatured = false;
  bool _isLoadingMoreFeatured = false;
  bool _isSearching = false;
  bool _isLoadingMoreSearch = false;
  bool _hasSearched = false;
  String? _featuredError;
  String? _featuredLoadMoreError;
  String? _searchError;
  String? _searchLoadMoreError;
  String _lastSearchQuery = '';
  PhotoSearchFilters _searchFilters = const PhotoSearchFilters(
    orientation: PhotoOrientation.portrait,
  );
  RateLimitSnapshot? _rateLimit;
  int _featuredRequestId = 0;
  int _searchRequestId = 0;
  bool _isDisposed = false;

  List<WallpaperPhoto> get featuredPhotos => _featuredPhotos;
  List<WallpaperPhoto> get searchPhotos => _searchPhotos;
  List<WallpaperPhoto> get likedPhotos => _likedById.values
      .toList(growable: false)
      .reversed
      .toList(growable: false);
  bool get isLoadingFeatured => _isLoadingFeatured;
  bool get isLoadingMoreFeatured => _isLoadingMoreFeatured;
  bool get isSearching => _isSearching;
  bool get isLoadingMoreSearch => _isLoadingMoreSearch;
  bool get hasSearched => _hasSearched;
  bool get hasMoreFeatured => _featuredNextPage != null;
  bool get hasMoreSearch => _searchNextPage != null;
  String? get featuredError => _featuredError;
  String? get featuredLoadMoreError => _featuredLoadMoreError;
  String? get searchError => _searchError;
  String? get searchLoadMoreError => _searchLoadMoreError;
  String get lastSearchQuery => _lastSearchQuery;
  PhotoSearchFilters get searchFilters => _searchFilters;
  RateLimitSnapshot? get rateLimit => _rateLimit;

  bool isLiked(WallpaperPhoto photo) => _likedById.containsKey(photo.id);

  Future<void> loadFeatured() async {
    if (_isLoadingFeatured) {
      return;
    }

    final requestId = ++_featuredRequestId;
    _isLoadingFeatured = true;
    _isLoadingMoreFeatured = false;
    _featuredError = null;
    _featuredLoadMoreError = null;
    _notifyListeners();

    var rateLimitChanged = false;
    try {
      final result = await _repository.curated(perPage: pageSize);
      rateLimitChanged = _updateRateLimit(result.rateLimit) || rateLimitChanged;
      if (requestId == _featuredRequestId) {
        _featuredPhotos = List.unmodifiable(result.photos);
        _featuredNextPage = result.nextPage;
        _syncLikedMetadata(result.photos);
      }
    } catch (error) {
      rateLimitChanged =
          _updateRateLimit(_repository.lastKnownRateLimit) || rateLimitChanged;
      if (requestId == _featuredRequestId) {
        _featuredError = _messageFor(error);
      }
    } finally {
      final isCurrentRequest = requestId == _featuredRequestId;
      if (isCurrentRequest) {
        _isLoadingFeatured = false;
      }
      if (isCurrentRequest || rateLimitChanged) {
        _notifyListeners();
      }
    }
  }

  Future<void> loadMoreFeatured() async {
    final nextPage = _featuredNextPage;
    if (nextPage == null || _isLoadingFeatured || _isLoadingMoreFeatured) {
      return;
    }

    final requestId = _featuredRequestId;
    _isLoadingMoreFeatured = true;
    _featuredLoadMoreError = null;
    _notifyListeners();

    var rateLimitChanged = false;
    try {
      final result = await _repository.curated(
        page: nextPage,
        perPage: pageSize,
      );
      rateLimitChanged = _updateRateLimit(result.rateLimit) || rateLimitChanged;
      if (requestId == _featuredRequestId) {
        _featuredPhotos = _appendUnique(_featuredPhotos, result.photos);
        _featuredNextPage = result.nextPage;
        _syncLikedMetadata(result.photos);
      }
    } catch (error) {
      rateLimitChanged =
          _updateRateLimit(_repository.lastKnownRateLimit) || rateLimitChanged;
      if (requestId == _featuredRequestId) {
        _featuredLoadMoreError = _messageFor(error);
      }
    } finally {
      final isCurrentRequest = requestId == _featuredRequestId;
      if (isCurrentRequest) {
        _isLoadingMoreFeatured = false;
      }
      if (isCurrentRequest || rateLimitChanged) {
        _notifyListeners();
      }
    }
  }

  Future<void> search(String query, {PhotoSearchFilters? filters}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return;
    }

    final requestId = ++_searchRequestId;
    _lastSearchQuery = normalizedQuery;
    _searchFilters = filters ?? _searchFilters;
    _hasSearched = true;
    _isSearching = true;
    _isLoadingMoreSearch = false;
    _searchError = null;
    _searchLoadMoreError = null;
    _searchPhotos = const [];
    _searchNextPage = null;
    _notifyListeners();

    var rateLimitChanged = false;
    try {
      final result = await _repository.search(
        normalizedQuery,
        filters: _searchFilters,
        perPage: pageSize,
      );
      rateLimitChanged = _updateRateLimit(result.rateLimit) || rateLimitChanged;
      if (requestId == _searchRequestId) {
        _searchPhotos = List.unmodifiable(result.photos);
        _searchNextPage = result.nextPage;
        _syncLikedMetadata(result.photos);
      }
    } catch (error) {
      rateLimitChanged =
          _updateRateLimit(_repository.lastKnownRateLimit) || rateLimitChanged;
      if (requestId == _searchRequestId) {
        _searchError = _messageFor(error);
      }
    } finally {
      final isCurrentRequest = requestId == _searchRequestId;
      if (isCurrentRequest) {
        _isSearching = false;
      }
      if (isCurrentRequest || rateLimitChanged) {
        _notifyListeners();
      }
    }
  }

  Future<void> loadMoreSearch() async {
    final nextPage = _searchNextPage;
    if (nextPage == null || _isSearching || _isLoadingMoreSearch) {
      return;
    }

    final requestId = _searchRequestId;
    _isLoadingMoreSearch = true;
    _searchLoadMoreError = null;
    _notifyListeners();

    var rateLimitChanged = false;
    try {
      final result = await _repository.search(
        _lastSearchQuery,
        filters: _searchFilters,
        page: nextPage,
        perPage: pageSize,
      );
      rateLimitChanged = _updateRateLimit(result.rateLimit) || rateLimitChanged;
      if (requestId == _searchRequestId) {
        _searchPhotos = _appendUnique(_searchPhotos, result.photos);
        _searchNextPage = result.nextPage;
        _syncLikedMetadata(result.photos);
      }
    } catch (error) {
      rateLimitChanged =
          _updateRateLimit(_repository.lastKnownRateLimit) || rateLimitChanged;
      if (requestId == _searchRequestId) {
        _searchLoadMoreError = _messageFor(error);
      }
    } finally {
      final isCurrentRequest = requestId == _searchRequestId;
      if (isCurrentRequest) {
        _isLoadingMoreSearch = false;
      }
      if (isCurrentRequest || rateLimitChanged) {
        _notifyListeners();
      }
    }
  }

  void toggleLike(WallpaperPhoto photo) {
    if (_likedById.remove(photo.id) == null) {
      _likedById[photo.id] = photo;
    }
    _notifyListeners();
  }

  List<WallpaperPhoto> _appendUnique(
    List<WallpaperPhoto> existing,
    List<WallpaperPhoto> incoming,
  ) {
    final byId = <int, WallpaperPhoto>{
      for (final photo in existing) photo.id: photo,
    };
    for (final photo in incoming) {
      byId[photo.id] = photo;
    }
    return List.unmodifiable(byId.values);
  }

  void _syncLikedMetadata(List<WallpaperPhoto> photos) {
    for (final photo in photos) {
      if (_likedById.containsKey(photo.id)) {
        _likedById[photo.id] = photo;
      }
    }
  }

  bool _updateRateLimit(RateLimitSnapshot? snapshot) {
    if (snapshot == null) {
      return false;
    }

    final merged = _rateLimit?.mergedWith(snapshot) ?? snapshot;
    if (merged == _rateLimit) {
      return false;
    }
    _rateLimit = merged;
    return true;
  }

  String _messageFor(Object error) {
    if (error case WallpaperRepositoryException(:final message)) {
      return message;
    }
    return 'We could not load photos. Check your connection and try again.';
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _featuredRequestId += 1;
    _searchRequestId += 1;
    _repository.close();
    super.dispose();
  }
}
