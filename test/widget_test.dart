import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perle/src/app.dart';
import 'package:perle/src/data/wallpaper_repository.dart';
import 'package:perle/src/features/wallpapers/widgets/page_header.dart';
import 'package:perle/src/features/wallpapers/widgets/pexels_attribution.dart';
import 'package:perle/src/features/wallpapers/widgets/wallpaper_detail.dart';
import 'package:perle/src/features/wallpapers/widgets/wallpaper_grid.dart';
import 'package:perle/src/models/wallpaper_photo.dart';

import 'test_data.dart';

void main() {
  testWidgets('opens directly in curated Explore with attribution', (
    tester,
  ) async {
    final repository = FakeWallpaperRepository();

    await tester.pumpWidget(PerleApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('A changing collection curated by Pexels.'), findsOne);
    expect(find.text('Photos provided by Pexels'), findsOne);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
    expect(find.text('Sign In'), findsNothing);
    expect(find.text('Register'), findsNothing);
    expect(find.text('Log Out'), findsNothing);
    expect(repository.curatedCalls, [1]);
  });

  testWidgets('search sends its query and active filters', (tester) async {
    final repository = FakeWallpaperRepository();

    await tester.pumpWidget(PerleApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'calm ocean');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.searchCalls.single.query, 'calm ocean');
    expect(
      repository.searchCalls.single.filters.orientation,
      PhotoOrientation.portrait,
    );
    expect(find.text('No photos found'), findsOne);
  });

  testWidgets('filter sheet applies a color to the next search', (
    tester,
  ) async {
    final repository = FakeWallpaperRepository();

    await tester.pumpWidget(PerleApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filters · 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Blue'));
    await tester.ensureVisible(find.text('Show results'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sky');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repository.searchCalls.single.filters.color, PhotoColor.blue);
  });

  testWidgets('renders an odd-sized response and opens photo details', (
    tester,
  ) async {
    final photo = makePhoto(11, alt: 'A quiet mountain lake');
    final repository = FakeWallpaperRepository(curatedPage: makePage([photo]));

    await tester.pumpWidget(PerleApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.byType(WallpaperTile), findsOne);
    await tester.tap(find.byType(WallpaperTile));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('A quiet mountain lake'), findsOne);
    expect(find.textContaining('Photo by Test Photographer'), findsOne);
    expect(find.text('Open photo on Pexels'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a load-more control when another page exists', (
    tester,
  ) async {
    final repository = FakeWallpaperRepository(
      curatedPage: makePage([makePhoto(1)], nextPage: 2),
    );

    await tester.pumpWidget(PerleApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Load more photos'), findsOne);
  });

  testWidgets('does not display a negative unlimited-quota sentinel', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PexelsAttribution(
            rateLimit: RateLimitSnapshot(
              limit: -1,
              remaining: -1,
              resetsAt: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('-1 requests left'), findsNothing);
  });

  testWidgets(
    'largest text keeps the Explore header and attribution scrollable without overflow',
    (tester) async {
      _useCompactScreenWithLargestText(tester);
      final repository = FakeWallpaperRepository(
        curatedPage: makePage(
          [for (var index = 0; index < 6; index++) makePhoto(index + 1)],
          rateLimit: const RateLimitSnapshot(
            limit: 25000,
            remaining: 24999,
            resetsAt: null,
          ),
        ),
      );

      await tester.pumpWidget(PerleApp(repository: repository));
      await tester.pumpAndSettle();

      final scrollView = find.byType(CustomScrollView);
      expect(scrollView, findsOne);
      final scrollable = find.descendant(
        of: scrollView,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));

      final headerTitle = find.descendant(
        of: find.byType(PageHeader),
        matching: find.text('Explore'),
      );
      final initialTop = tester.getTopLeft(headerTitle).dy;
      await tester.scrollUntilVisible(
        find.text('Photos provided by Pexels'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('Photos provided by Pexels'), findsOne);
      expect(find.text('24999 requests left'), findsOne);

      expect(tester.getTopLeft(headerTitle).dy, lessThan(initialTop));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grid uses an orientation-aware image source and aspect ratio', (
    tester,
  ) async {
    final photo = makePhoto(17);

    Future<(String, double)> renderedGrid(PhotoOrientation orientation) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WallpaperGrid(
              photos: [photo],
              orientation: orientation,
              isLiked: (_) => false,
              onToggleLike: (_) {},
              hasMore: false,
              isLoadingMore: false,
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      final imageUrl = (image.image as NetworkImage).url;
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      return (imageUrl, delegate.childAspectRatio);
    }

    final portrait = await renderedGrid(PhotoOrientation.portrait);
    expect(portrait.$1, photo.sources.portrait);
    expect(portrait.$2, lessThan(1));

    final landscape = await renderedGrid(PhotoOrientation.landscape);
    expect(landscape.$1, photo.sources.landscape);
    expect(landscape.$2, greaterThan(1));

    final square = await renderedGrid(PhotoOrientation.square);
    expect(square.$1, photo.sources.large);
    expect(square.$2, closeTo(1, 0.001));
  });

  testWidgets(
    'failed refresh keeps retained photos and shows one visible error state',
    (tester) async {
      final photo = makePhoto(23);
      final repository = FakeWallpaperRepository(
        curatedResponses: [
          makePage([photo]),
          StateError('refresh failed'),
        ],
      );

      await tester.pumpWidget(PerleApp(repository: repository));
      await tester.pumpAndSettle();
      expect(find.byType(WallpaperTile), findsOne);

      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      await refreshIndicator.onRefresh();
      await tester.pumpAndSettle();

      expect(find.byType(WallpaperTile), findsOne);
      expect(find.text('Could not refresh photos'), findsOne);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('pagination action stays stable and announces every state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final photo = makePhoto(31);

    Widget paginationState({
      required bool isLoading,
      required bool hasMore,
      String? error,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: WallpaperGrid(
            photos: [photo],
            isLiked: (_) => false,
            onToggleLike: (_) {},
            hasMore: hasMore,
            isLoadingMore: isLoading,
            loadMoreError: error,
            onLoadMore: () {},
          ),
        ),
      );
    }

    await tester.pumpWidget(paginationState(isLoading: true, hasMore: true));
    await tester.pump();
    final actionElement = tester.element(
      find.byKey(const ValueKey('pagination-action')),
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('pagination-footer')))
          .label,
      contains('Loading more photos'),
    );

    await tester.pumpWidget(
      paginationState(
        isLoading: false,
        hasMore: true,
        error: 'Could not load another page',
      ),
    );
    await tester.pump();
    expect(
      tester.element(find.byKey(const ValueKey('pagination-action'))),
      same(actionElement),
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('pagination-footer')))
          .label,
      contains('Could not load another page'),
    );

    await tester.pumpWidget(paginationState(isLoading: false, hasMore: false));
    await tester.pump();
    expect(
      tester.element(find.byKey(const ValueKey('pagination-action'))),
      same(actionElement),
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('pagination-footer')))
          .label,
      contains('All photos loaded'),
    );
    semantics.dispose();
  });

  testWidgets(
    'detail exposes one description and scrollable metadata at largest text',
    (tester) async {
      _useCompactScreenWithLargestText(tester, height: 600);
      final semantics = tester.ensureSemantics();
      const description =
          'A very long accessible description of a quiet mountain lake at '
          'sunrise with pine trees reflected in the water.';
      final photo = makePhoto(
        41,
        alt: description,
        photographer:
            'A photographer with an intentionally long attribution name',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WallpaperDetail(
            photo: photo,
            initiallyLiked: false,
            onToggleLike: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(description), findsOneWidget);
      final metadata = find.byKey(
        const ValueKey('wallpaper-detail-metadata-scroll'),
      );
      expect(metadata, findsOneWidget);
      final metadataScrollable = find.descendant(
        of: metadata,
        matching: find.byType(Scrollable),
      );
      expect(
        tester
            .state<ScrollableState>(metadataScrollable)
            .position
            .maxScrollExtent,
        greaterThan(0),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('Likes explains that saved photos last for this session only', (
    tester,
  ) async {
    await tester.pumpWidget(PerleApp(repository: FakeWallpaperRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('session'), findsOneWidget);
  });
}

class FakeWallpaperRepository implements WallpaperRepository {
  FakeWallpaperRepository({
    PhotoPage? curatedPage,
    List<Object>? curatedResponses,
  }) : curatedPage = curatedPage ?? makePage(const []),
       _curatedResponses = List<Object>.of(curatedResponses ?? const []);

  final PhotoPage curatedPage;
  final List<Object> _curatedResponses;
  final List<int> curatedCalls = [];
  final List<SearchCall> searchCalls = [];

  @override
  RateLimitSnapshot? get lastKnownRateLimit => null;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) async {
    curatedCalls.add(page);
    if (_curatedResponses.isNotEmpty) {
      final response = _curatedResponses.removeAt(0);
      if (response case final PhotoPage page) {
        return page;
      }
      throw response;
    }
    return curatedPage;
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) async {
    searchCalls.add(SearchCall(query, filters));
    return makePage(const []);
  }

  @override
  void close() {}
}

void _useCompactScreenWithLargestText(
  WidgetTester tester, {
  double height = 844,
}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(390, height);
  tester.platformDispatcher.textScaleFactorTestValue = 3.2;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class SearchCall {
  const SearchCall(this.query, this.filters);

  final String query;
  final PhotoSearchFilters filters;
}
