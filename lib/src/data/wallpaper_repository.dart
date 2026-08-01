import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wallpaper_photo.dart';

abstract interface class WallpaperRepository {
  Future<PhotoPage> curated({int page = 1, int perPage = 24});

  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  });

  RateLimitSnapshot? get lastKnownRateLimit;

  void close();
}

class PexelsWallpaperRepository implements WallpaperRepository {
  PexelsWallpaperRepository({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  RateLimitSnapshot? _lastKnownRateLimit;

  @override
  RateLimitSnapshot? get lastKnownRateLimit => _lastKnownRateLimit;

  @override
  Future<PhotoPage> curated({int page = 1, int perPage = 24}) {
    _validatePagination(page, perPage);
    return _getPhotoPage(
      Uri.https('api.pexels.com', '/v1/curated', {
        'page': page.toString(),
        'per_page': perPage.toString(),
      }),
      requestedPage: page,
    );
  }

  @override
  Future<PhotoPage> search(
    String query, {
    PhotoSearchFilters filters = const PhotoSearchFilters(),
    int page = 1,
    int perPage = 24,
  }) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      throw ArgumentError.value(
        query,
        'query',
        'Search query cannot be empty.',
      );
    }
    _validatePagination(page, perPage);

    final parameters = <String, String>{
      'query': normalizedQuery,
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (filters.orientation != null)
        'orientation': filters.orientation!.apiValue,
      if (filters.minimumSize != null) 'size': filters.minimumSize!.apiValue,
      if (filters.color != null) 'color': filters.color!.apiValue,
      if (filters.locale case final locale? when locale.trim().isNotEmpty)
        'locale': locale.trim(),
    };

    return _getPhotoPage(
      Uri.https('api.pexels.com', '/v1/search', parameters),
      requestedPage: page,
    );
  }

  Future<PhotoPage> _getPhotoPage(Uri uri, {required int requestedPage}) async {
    if (apiKey.trim().isEmpty) {
      throw const WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.missingKey,
        message: 'A Pexels API key is required in dart_defines.json.',
      );
    }

    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Authorization': apiKey})
          .timeout(const Duration(seconds: 20));
    } on TimeoutException catch (error) {
      throw WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.timeout,
        message: 'Pexels took too long to respond.',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.network,
        message: 'Pexels could not be reached.',
        cause: error,
      );
    }

    final responseRateLimit = _parseRateLimit(response.headers);
    if (responseRateLimit != null) {
      _lastKnownRateLimit =
          _lastKnownRateLimit?.mergedWith(responseRateLimit) ??
          responseRateLimit;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _exceptionForStatus(response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }

      final rawPhotos = payload['photos'];
      if (rawPhotos is! List<dynamic>) {
        throw const FormatException('Expected a photos array.');
      }

      final photosById = <int, WallpaperPhoto>{};
      for (final rawPhoto in rawPhotos.whereType<Map<String, dynamic>>()) {
        final photo = _tryParsePhoto(rawPhoto);
        if (photo != null) {
          photosById[photo.id] = photo;
        }
      }

      if (rawPhotos.isNotEmpty && photosById.isEmpty) {
        throw const FormatException('No valid photo records were returned.');
      }

      final currentPage = _requiredInt(payload, 'page');
      final perPage = _requiredInt(payload, 'per_page');
      final totalResults = _requiredInt(payload, 'total_results');
      if (currentPage != requestedPage) {
        throw FormatException(
          'Expected page $requestedPage but received page $currentPage.',
        );
      }
      if (perPage < 1 || perPage > 80) {
        throw const FormatException('Expected per_page to be from 1 to 80.');
      }
      if (totalResults < 0) {
        throw const FormatException(
          'Expected total_results to be non-negative.',
        );
      }

      return PhotoPage(
        photos: List.unmodifiable(photosById.values),
        page: currentPage,
        perPage: perPage,
        totalResults: totalResults,
        nextPage: _parseNextPage(
          payload['next_page'],
          currentPage,
          expectedPath: uri.path,
        ),
        rateLimit: _lastKnownRateLimit,
      );
    } on FormatException catch (error) {
      throw WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.invalidResponse,
        message: 'Pexels returned an unreadable response.',
        cause: error,
      );
    } on TypeError catch (error) {
      throw WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.invalidResponse,
        message: 'Pexels returned an unexpected response.',
        cause: error,
      );
    }
  }

  WallpaperPhoto? _tryParsePhoto(Map<String, dynamic> json) {
    try {
      final sourcesJson = json['src'];
      if (sourcesJson is! Map<String, dynamic>) {
        return null;
      }

      final portrait = _requiredHttpsUrl(sourcesJson, 'portrait');
      final large2x = _optionalHttpsUrl(sourcesJson, 'large2x') ?? portrait;
      final large = _optionalHttpsUrl(sourcesJson, 'large') ?? large2x;
      final medium = _optionalHttpsUrl(sourcesJson, 'medium') ?? portrait;
      final small = _optionalHttpsUrl(sourcesJson, 'small') ?? medium;
      final landscape = _optionalHttpsUrl(sourcesJson, 'landscape') ?? large;
      final tiny = _optionalHttpsUrl(sourcesJson, 'tiny') ?? small;
      final original = _optionalHttpsUrl(sourcesJson, 'original') ?? large2x;

      final pexelsUrl = _requiredHttpsUri(json, 'url');
      final photographerUrl = _requiredHttpsUri(json, 'photographer_url');

      return WallpaperPhoto(
        id: _requiredPositiveInt(json, 'id'),
        width: _requiredPositiveInt(json, 'width'),
        height: _requiredPositiveInt(json, 'height'),
        pexelsUrl: pexelsUrl,
        photographer: _requiredString(json, 'photographer'),
        photographerUrl: photographerUrl,
        photographerId: _requiredPositiveInt(json, 'photographer_id'),
        averageColorHex: _optionalString(json, 'avg_color'),
        sources: PhotoSources(
          original: original,
          large2x: large2x,
          large: large,
          medium: medium,
          small: small,
          portrait: portrait,
          landscape: landscape,
          tiny: tiny,
        ),
        alt: _optionalString(json, 'alt') ?? '',
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  RateLimitSnapshot? _parseRateLimit(Map<String, String> headers) {
    final limit = _parseNonNegativeHeader(headers['x-ratelimit-limit']);
    final remaining = _parseNonNegativeHeader(headers['x-ratelimit-remaining']);
    final resetsAt = _parseResetTime(headers['x-ratelimit-reset']);

    if (limit == null && remaining == null && resetsAt == null) {
      return null;
    }

    return RateLimitSnapshot(
      limit: limit,
      remaining: remaining,
      resetsAt: resetsAt,
    );
  }

  int? _parseNonNegativeHeader(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  DateTime? _parseResetTime(String? value) {
    final seconds = int.tryParse(value ?? '');
    // Unix timestamps beyond year 9999 are not useful to the app and may be
    // outside the range supported by DateTime on some platforms.
    if (seconds == null || seconds <= 0 || seconds > 253402300799) {
      return null;
    }

    try {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * Duration.millisecondsPerSecond,
        isUtc: true,
      );
    } on RangeError {
      return null;
    }
  }

  WallpaperRepositoryException _exceptionForStatus(int statusCode) {
    return switch (statusCode) {
      401 => WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.unauthorized,
        statusCode: statusCode,
        message: 'The Pexels API key was rejected.',
      ),
      403 => WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.forbidden,
        statusCode: statusCode,
        message: 'Pexels denied this request.',
      ),
      429 => WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.rateLimited,
        statusCode: statusCode,
        message: 'The Pexels request limit has been reached. Try again later.',
      ),
      >= 500 => WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.server,
        statusCode: statusCode,
        message: 'Pexels is temporarily unavailable.',
      ),
      _ => WallpaperRepositoryException(
        kind: WallpaperRepositoryErrorKind.invalidResponse,
        statusCode: statusCode,
        message: 'Pexels could not complete this request (HTTP $statusCode).',
      ),
    };
  }

  int? _parseNextPage(
    Object? value,
    int currentPage, {
    required String expectedPath,
  }) {
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected next_page to be an HTTPS URL.');
    }

    final uri = Uri.tryParse(value.trim());
    final pageValues = uri?.queryParametersAll['page'];
    final nextPage = pageValues?.length == 1
        ? int.tryParse(pageValues!.single)
        : null;
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.toLowerCase() != 'api.pexels.com' ||
        _normalizedPath(uri.path) != _normalizedPath(expectedPath) ||
        nextPage == null ||
        nextPage <= currentPage) {
      throw const FormatException('Invalid next_page cursor.');
    }
    return nextPage;
  }

  String _normalizedPath(String path) {
    final segments = Uri(
      path: path,
    ).pathSegments.where((segment) => segment.isNotEmpty).toList();
    // Pexels currently emits cursors such as `/v1/v1/curated`. We only use
    // the cursor's page number and build the next request ourselves, so treat
    // repeated leading API-version segments as the documented endpoint.
    while (segments.isNotEmpty && segments.first.toLowerCase() == 'v1') {
      segments.removeAt(0);
    }
    return '/${segments.join('/')}';
  }

  void _validatePagination(int page, int perPage) {
    if (page < 1) {
      throw RangeError.range(page, 1, null, 'page');
    }
    if (perPage < 1 || perPage > 80) {
      throw RangeError.range(perPage, 1, 80, 'perPage');
    }
  }

  int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected integer field "$key".');
  }

  int _requiredPositiveInt(Map<String, dynamic> json, String key) {
    final value = _requiredInt(json, key);
    if (value > 0) {
      return value;
    }
    throw FormatException('Expected positive integer field "$key".');
  }

  String _requiredString(Map<String, dynamic> json, String key) {
    final value = _optionalString(json, key);
    if (value != null) {
      return value;
    }
    throw FormatException('Expected string field "$key".');
  }

  String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  Uri _requiredHttpsUri(Map<String, dynamic> json, String key) {
    final uri = Uri.tryParse(_requiredString(json, key));
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('Expected an HTTPS URL in "$key".');
    }
    return uri;
  }

  String _requiredHttpsUrl(Map<String, dynamic> json, String key) {
    final value = _requiredString(json, key);
    _validateHttpsUrl(value, key);
    return value;
  }

  String? _optionalHttpsUrl(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }

    final rawValue = json[key];
    if (rawValue is String && rawValue.trim().isEmpty) {
      return null;
    }
    if (rawValue is! String) {
      throw FormatException('Expected an HTTPS URL in "$key".');
    }

    final value = rawValue.trim();
    _validateHttpsUrl(value, key);
    return value;
  }

  void _validateHttpsUrl(String value, String key) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException('Expected an HTTPS URL in "$key".');
    }
  }

  @override
  void close() {
    _client.close();
  }
}

enum WallpaperRepositoryErrorKind {
  missingKey,
  unauthorized,
  forbidden,
  rateLimited,
  server,
  timeout,
  network,
  invalidResponse,
}

class WallpaperRepositoryException implements Exception {
  const WallpaperRepositoryException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final WallpaperRepositoryErrorKind kind;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}
