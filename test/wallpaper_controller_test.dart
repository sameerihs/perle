import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:perle/src/data/wallpaper_repository.dart';
import 'package:perle/src/features/wallpapers/wallpaper_controller.dart';
import 'package:perle/src/models/wallpaper_photo.dart';

import 'test_data.dart';

void main() {
  test('loads curated photos and manages likes by photo ID', () async {
    final photo = makePhoto(1);
    final repository = StubWallpaperRepository(
      curatedPages: {
        1: makePage([photo]),
      },
    );
    final controller = WallpaperController(repository);
    addTearDown(controller.dispose);

    await controller.loadFeatured();

    expect(controller.featuredPhotos, [photo]);
    expect(controller.featuredError, isNull);

    controller.toggleLike(photo);
    expect(controller.isLiked(photo), isTrue);
    expect(controller.likedPhotos, [photo]);

    controller.toggleLike(photo);
    expect(controller.isLiked(photo), isFalse);
  });

  test('loads another curated page and deduplicates updated photos', () async {
    final repository = StubWallpaperRepository(
      curatedPages: {
        1: makePage([makePhoto(1), makePhoto(2)], nextPage: 2),
        2: makePage([
          makePhoto(2, alt: 'Updated photo 2'),
          makePhoto(3),
        ], page: 2),
      },
    );
    final controller = WallpaperController(repository);
    addTearDown(controller.dispose);

    await controller.loadFeatured();
    await controller.loadMoreFeatured();

    expect(controller.featuredPhotos.map((photo) => photo.id), [1, 2, 3]);
    expect(controller.featuredPhotos[1].alt, 'Updated photo 2');
    expect(controller.hasMoreFeatured, isFalse);
    expect(repository.curatedCalls, [1, 2]);
  });

  test('search applies filters and a new search replaces results', () async {
    const filters = PhotoSearchFilters(
      orientation: PhotoOrientation.square,
      color: PhotoColor.orange,
    );
    final repository = StubWallpaperRepository(
      searchPages: {
        'first': {
          1: makePage([makePhoto(1)]),
        },
        'second': {
          1: makePage([makePhoto(2)]),
        },
      },
    );
    final controller = WallpaperController(repository);
    addTearDown(controller.dispose);

    await controller.search('first', filters: filters);
    expect(controller.searchPhotos.single.id, 1);

    await controller.search('second', filters: filters);
    expect(controller.searchPhotos.single.id, 2);
    expect(controller.lastSearchQuery, 'second');
    expect(repository.searchCalls.last.filters, filters);
  });

  test(
    'the latest overlapping search wins while stale quota still merges',
    () async {
      final repository = ControlledWallpaperRepository();
      final controller = WallpaperController(repository);
      addTearDown(controller.dispose);
      final resetTime = DateTime.utc(2030);
      final observedRemaining = <int?>[];
      controller.addListener(() {
        observedRemaining.add(controller.rateLimit?.remaining);
      });

      final firstSearch = controller.search('first');
      final secondSearch = controller.search('second');
      repository.complete(
        'second',
        makePage(
          [makePhoto(2)],
          rateLimit: RateLimitSnapshot(
            limit: 200,
            remaining: 99,
            resetsAt: resetTime,
          ),
        ),
      );
      await secondSearch;
      observedRemaining.clear();
      repository.complete(
        'first',
        makePage(
          [makePhoto(1)],
          rateLimit: RateLimitSnapshot(
            limit: 200,
            remaining: 98,
            resetsAt: resetTime,
          ),
        ),
      );
      await firstSearch;

      expect(controller.searchPhotos.single.id, 2);
      expect(controller.lastSearchQuery, 'second');
      expect(controller.rateLimit?.remaining, 98);
      expect(observedRemaining, contains(98));
    },
  );

  test('surfaces repository failures as UI-safe errors', () async {
    final controller = WallpaperController(FailingWallpaperRepository());
    addTearDown(controller.dispose);

    await controller.loadFeatured();

    expect(controller.featuredPhotos, isEmpty);
    expect(controller.featuredError, 'Not available right now.');
    expect(controller.isLoadingFeatured, isFalse);
  });

  test('captures quota metadata from a response that fails parsing', () async {
    final quota = RateLimitSnapshot(
      limit: 200,
      remaining: 12,
      resetsAt: DateTime.utc(2030),
    );
    final controller = WallpaperController(
      QuotaFailingWallpaperRepository(quota),
    );
    addTearDown(controller.dispose);

    await controller.loadFeatured();

    expect(controller.featuredError, 'The response was invalid.');
    expect(controller.rateLimit, quota);
    expect(controller.isLoadingFeatured, isFalse);
  });
}

class StubWallpaperRepository implements WallpaperRepository {
  StubWallpaperRepository({
    this.curatedPages = const {},
    this.searchPages = const {},
  });

  final Map<int, PhotoPage> curatedPages;
  final Map<String, Map<int, PhotoPage>> searchPages;
  final List<int> curatedCalls = [];
  final List<SearchCall> searchCalls = [];

  @override
  RateLimitSnapshot? get lastKnownRateLimit => null;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) async {
    curatedCalls.add(page);
    return curatedPages[page] ?? makePage(const [], page: page);
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) async {
    searchCalls.add(SearchCall(query, filters, page));
    return searchPages[query]?[page] ?? makePage(const [], page: page);
  }

  @override
  void close() {}
}

class FailingWallpaperRepository implements WallpaperRepository {
  @override
  RateLimitSnapshot? get lastKnownRateLimit => null;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) {
    throw const WallpaperRepositoryException(
      kind: WallpaperRepositoryErrorKind.server,
      message: 'Not available right now.',
    );
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

class ControlledWallpaperRepository implements WallpaperRepository {
  final Map<String, Completer<PhotoPage>> _requests = {};

  @override
  RateLimitSnapshot? get lastKnownRateLimit => null;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) async {
    return makePage(const []);
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) {
    return (_requests[query] = Completer<PhotoPage>()).future;
  }

  void complete(String query, PhotoPage page) {
    _requests[query]!.complete(page);
  }

  @override
  void close() {}
}

class QuotaFailingWallpaperRepository implements WallpaperRepository {
  QuotaFailingWallpaperRepository(this.quota);

  final RateLimitSnapshot quota;
  RateLimitSnapshot? _lastKnownRateLimit;

  @override
  RateLimitSnapshot? get lastKnownRateLimit => _lastKnownRateLimit;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) async {
    _lastKnownRateLimit = quota;
    throw const WallpaperRepositoryException(
      kind: WallpaperRepositoryErrorKind.invalidResponse,
      message: 'The response was invalid.',
    );
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) {
    throw UnimplementedError();
  }

  @override
  void close() {}
}

class SearchCall {
  const SearchCall(this.query, this.filters, this.page);

  final String query;
  final PhotoSearchFilters filters;
  final int page;
}
