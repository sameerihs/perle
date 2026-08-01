import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:perle/src/data/wallpaper_repository.dart';
import 'package:perle/src/models/wallpaper_photo.dart';

void main() {
  test('parses photo metadata, pagination, filters, and quota', () async {
    late http.Request capturedRequest;
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'page': 2,
            'per_page': 24,
            'total_results': 80,
            'next_page': 'https://api.pexels.com/v1/search?page=3&per_page=24',
            'photos': [
              _photoJson(42),
              _photoJson(42),
              {'id': 'malformed'},
            ],
          }),
          200,
          headers: {
            'x-ratelimit-limit': '20000',
            'x-ratelimit-remaining': '19998',
            'x-ratelimit-reset': '1893456000',
          },
        );
      }),
    );
    addTearDown(repository.close);

    final page = await repository.search(
      'calm ocean',
      filters: const PhotoSearchFilters(
        orientation: PhotoOrientation.portrait,
        minimumSize: PhotoSize.large,
        color: PhotoColor.blue,
        locale: 'en-US',
      ),
      page: 2,
      perPage: 24,
    );

    expect(page.photos, hasLength(1));
    expect(page.photos.single.id, 42);
    expect(page.photos.single.photographer, 'Photographer 42');
    expect(page.photos.single.photographerId, 1042);
    expect(page.photos.single.sources.portrait, contains('portrait'));
    expect(page.photos.single.alt, 'Photo 42');
    expect(page.nextPage, 3);
    expect(page.rateLimit?.remaining, 19998);
    expect(repository.lastKnownRateLimit?.limit, 20000);

    expect(capturedRequest.headers['Authorization'], 'test-key');
    expect(capturedRequest.url.path, '/v1/search');
    expect(
      capturedRequest.url.queryParameters,
      containsPair('query', 'calm ocean'),
    );
    expect(
      capturedRequest.url.queryParameters,
      containsPair('orientation', 'portrait'),
    );
    expect(capturedRequest.url.queryParameters, containsPair('size', 'large'));
    expect(capturedRequest.url.queryParameters, containsPair('color', 'blue'));
    expect(
      capturedRequest.url.queryParameters,
      containsPair('locale', 'en-US'),
    );
    expect(capturedRequest.url.queryParameters, containsPair('page', '2'));
  });

  test('uses the curated endpoint and handles the final page', () async {
    late http.Request capturedRequest;
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'page': 1,
            'per_page': 24,
            'total_results': 1,
            'photos': [_photoJson(7)],
          }),
          200,
        );
      }),
    );
    addTearDown(repository.close);

    final page = await repository.curated();

    expect(capturedRequest.url.path, '/v1/curated');
    expect(page.photos.single.id, 7);
    expect(page.hasMore, isFalse);
  });

  test('maps authorization and rate-limit errors', () async {
    for (final testCase in [
      (401, WallpaperRepositoryErrorKind.unauthorized),
      (429, WallpaperRepositoryErrorKind.rateLimited),
      (503, WallpaperRepositoryErrorKind.server),
    ]) {
      final repository = PexelsWallpaperRepository(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response('Unavailable', testCase.$1),
        ),
      );

      await expectLater(
        repository.curated(),
        throwsA(
          isA<WallpaperRepositoryException>().having(
            (error) => error.kind,
            'kind',
            testCase.$2,
          ),
        ),
      );
      repository.close();
    }
  });

  test('requires an API key before making a request', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: '',
      client: MockClient((_) async {
        fail('The client should not be called without an API key.');
      }),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.curated(),
      throwsA(
        isA<WallpaperRepositoryException>().having(
          (error) => error.kind,
          'kind',
          WallpaperRepositoryErrorKind.missingKey,
        ),
      ),
    );
  });

  test('rejects malformed JSON and invalid pagination', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((_) async => http.Response('{not-json', 200)),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.curated(),
      throwsA(
        isA<WallpaperRepositoryException>().having(
          (error) => error.kind,
          'kind',
          WallpaperRepositoryErrorKind.invalidResponse,
        ),
      ),
    );
    expect(() => repository.curated(page: 0), throwsRangeError);
    expect(() => repository.curated(perPage: 81), throwsRangeError);
  });

  test('rejects mismatched response pages and invalid next cursors', () async {
    Future<void> expectInvalidResponse({
      required int responsePage,
      Object? nextPage,
    }) async {
      final repository = PexelsWallpaperRepository(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'page': responsePage,
              'per_page': 24,
              'total_results': 1,
              'next_page': ?nextPage,
              'photos': [_photoJson(1)],
            }),
            200,
          ),
        ),
      );

      await expectLater(
        repository.curated(),
        throwsA(
          isA<WallpaperRepositoryException>().having(
            (error) => error.kind,
            'kind',
            WallpaperRepositoryErrorKind.invalidResponse,
          ),
        ),
      );
      repository.close();
    }

    await expectInvalidResponse(responsePage: 2);
    for (final nextPage in <Object>[
      'https://api.pexels.com/v1/curated?page=1',
      'https://api.pexels.com/v1/curated?page=0',
      'https://example.com/v1/curated?page=2',
      'https://api.pexels.com/v1/search?page=2',
      'https://api.pexels.com/v1/curated',
      2,
    ]) {
      await expectInvalidResponse(responsePage: 1, nextPage: nextPage);
    }
  });

  test('accepts Pexels cursors with a repeated API-version segment', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'page': 1,
            'per_page': 24,
            'total_results': 2,
            'next_page':
                'https://api.pexels.com/v1/v1/curated?page=2&per_page=24',
            'photos': [_photoJson(1)],
          }),
          200,
        ),
      ),
    );
    addTearDown(repository.close);

    final result = await repository.curated();

    expect(result.nextPage, 2);
  });

  test('merges concurrent quota snapshots without moving backwards', () async {
    final firstResponse = Completer<http.Response>();
    final secondResponse = Completer<http.Response>();
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient((request) {
        return switch (request.url.queryParameters['page']) {
          '1' => firstResponse.future,
          '2' => secondResponse.future,
          _ => throw StateError('Unexpected request: ${request.url}'),
        };
      }),
    );
    addTearDown(repository.close);

    final firstPageFuture = repository.curated(page: 1);
    final secondPageFuture = repository.curated(page: 2);

    secondResponse.complete(
      _photoResponse(page: 2, remaining: 98, resetSeconds: 1893456000),
    );
    final secondPage = await secondPageFuture;

    firstResponse.complete(
      _photoResponse(page: 1, remaining: 99, resetSeconds: 1893456000),
    );
    final firstPage = await firstPageFuture;

    expect(secondPage.rateLimit?.remaining, 98);
    expect(firstPage.rateLimit?.remaining, 98);
    expect(repository.lastKnownRateLimit?.remaining, 98);
  });

  test(
    'preserves known quota fields when headers are partial or absent',
    () async {
      var callCount = 0;
      final repository = PexelsWallpaperRepository(
        apiKey: 'test-key',
        client: MockClient((_) async {
          callCount += 1;
          return switch (callCount) {
            1 => _photoResponse(
              page: 1,
              limit: 200,
              remaining: 150,
              resetSeconds: 1893456000,
            ),
            2 => _photoResponse(page: 1, remaining: 149),
            _ => _photoResponse(page: 1),
          };
        }),
      );
      addTearDown(repository.close);

      await repository.curated();
      final partialPage = await repository.curated();
      final headerlessPage = await repository.curated();

      expect(partialPage.rateLimit?.limit, 200);
      expect(partialPage.rateLimit?.remaining, 149);
      expect(partialPage.rateLimit?.resetsAt, DateTime.utc(2030));
      expect(headerlessPage.rateLimit, partialPage.rateLimit);
      expect(repository.lastKnownRateLimit, partialPage.rateLimit);
    },
  );

  test('retains quota headers when the response body is invalid', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          '{not-json',
          200,
          headers: {
            'x-ratelimit-limit': '200',
            'x-ratelimit-remaining': '12',
            'x-ratelimit-reset': '1893456000',
          },
        ),
      ),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.curated(),
      throwsA(isA<WallpaperRepositoryException>()),
    );
    expect(repository.lastKnownRateLimit?.remaining, 12);
    expect(repository.lastKnownRateLimit?.resetsAt, DateTime.utc(2030));
  });

  test('ignores unsafe quota header values', () async {
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => _photoResponse(
          page: 1,
          rawLimit: '-1',
          remaining: 10,
          rawReset: '8640000000001',
        ),
      ),
    );
    addTearDown(repository.close);

    final page = await repository.curated();

    expect(page.rateLimit?.limit, isNull);
    expect(page.rateLimit?.remaining, 10);
    expect(page.rateLimit?.resetsAt, isNull);
  });

  test('rejects photo records with insecure image source URLs', () async {
    final photo = _photoJson(1);
    (photo['src'] as Map<String, dynamic>)['portrait'] =
        'http://images.example.com/insecure.jpg';
    final repository = PexelsWallpaperRepository(
      apiKey: 'test-key',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'page': 1,
            'per_page': 24,
            'total_results': 1,
            'photos': [photo],
          }),
          200,
        ),
      ),
    );
    addTearDown(repository.close);

    await expectLater(
      repository.curated(),
      throwsA(
        isA<WallpaperRepositoryException>().having(
          (error) => error.kind,
          'kind',
          WallpaperRepositoryErrorKind.invalidResponse,
        ),
      ),
    );
  });

  test('merges rate limits by reset window', () {
    final current = RateLimitSnapshot(
      limit: 200,
      remaining: 10,
      resetsAt: DateTime.utc(2030),
    );
    final older = RateLimitSnapshot(
      limit: 300,
      remaining: 1,
      resetsAt: DateTime.utc(2029),
    );
    final sameWindow = RateLimitSnapshot(
      limit: null,
      remaining: 20,
      resetsAt: DateTime.utc(2030),
    );
    final newer = RateLimitSnapshot(
      limit: null,
      remaining: 190,
      resetsAt: DateTime.utc(2031),
    );

    expect(current.mergedWith(older), current);
    expect(current.mergedWith(sameWindow).remaining, 10);
    expect(current.mergedWith(newer).remaining, 190);
    expect(current.mergedWith(newer).limit, 200);
    expect(current.mergedWith(newer).resetsAt, DateTime.utc(2031));
  });
}

http.Response _photoResponse({
  required int page,
  int? limit,
  int? remaining,
  int? resetSeconds,
  String? rawLimit,
  String? rawReset,
}) {
  return http.Response(
    jsonEncode({
      'page': page,
      'per_page': 24,
      'total_results': 1,
      'photos': [_photoJson(page)],
    }),
    200,
    headers: {
      if (limit != null || rawLimit != null)
        'x-ratelimit-limit': rawLimit ?? '$limit',
      if (remaining != null) 'x-ratelimit-remaining': '$remaining',
      if (resetSeconds != null || rawReset != null)
        'x-ratelimit-reset': rawReset ?? '$resetSeconds',
    },
  );
}

Map<String, dynamic> _photoJson(int id) {
  return {
    'id': id,
    'width': 3000,
    'height': 4500,
    'url': 'https://www.pexels.com/photo/$id/',
    'photographer': 'Photographer $id',
    'photographer_id': id + 1000,
    'photographer_url': 'https://www.pexels.com/@photographer-$id',
    'avg_color': '#445566',
    'alt': 'Photo $id',
    'src': {
      'original': 'https://images.example.com/$id-original.jpg',
      'large2x': 'https://images.example.com/$id-large2x.jpg',
      'large': 'https://images.example.com/$id-large.jpg',
      'medium': 'https://images.example.com/$id-medium.jpg',
      'small': 'https://images.example.com/$id-small.jpg',
      'portrait': 'https://images.example.com/$id-portrait.jpg',
      'landscape': 'https://images.example.com/$id-landscape.jpg',
      'tiny': 'https://images.example.com/$id-tiny.jpg',
    },
  };
}
