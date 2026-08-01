enum PhotoOrientation {
  portrait('portrait', 'Portrait'),
  landscape('landscape', 'Landscape'),
  square('square', 'Square');

  const PhotoOrientation(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum PhotoSize {
  large('large', 'Large · 24 MP+'),
  medium('medium', 'Medium · 12 MP+'),
  small('small', 'Small · 4 MP+');

  const PhotoSize(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

enum PhotoColor {
  red('red', 'Red', '#E5484D'),
  orange('orange', 'Orange', '#F28C28'),
  yellow('yellow', 'Yellow', '#F5D90A'),
  green('green', 'Green', '#30A46C'),
  turquoise('turquoise', 'Turquoise', '#12A594'),
  blue('blue', 'Blue', '#3E63DD'),
  violet('violet', 'Violet', '#8E4EC6'),
  pink('pink', 'Pink', '#D6409F'),
  brown('brown', 'Brown', '#8D6E63'),
  black('black', 'Black', '#111111'),
  gray('gray', 'Gray', '#8B8D98'),
  white('white', 'White', '#FFFFFF');

  const PhotoColor(this.apiValue, this.label, this.swatchHex);

  final String apiValue;
  final String label;
  final String swatchHex;
}

class PhotoSearchFilters {
  const PhotoSearchFilters({
    this.orientation,
    this.minimumSize,
    this.color,
    this.locale,
  });

  final PhotoOrientation? orientation;
  final PhotoSize? minimumSize;
  final PhotoColor? color;
  final String? locale;

  int get activeCount =>
      [orientation, minimumSize, color].where((value) => value != null).length;

  @override
  bool operator ==(Object other) {
    return other is PhotoSearchFilters &&
        other.orientation == orientation &&
        other.minimumSize == minimumSize &&
        other.color == color &&
        other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(orientation, minimumSize, color, locale);
}

class WallpaperPhoto {
  const WallpaperPhoto({
    required this.id,
    required this.width,
    required this.height,
    required this.pexelsUrl,
    required this.photographer,
    required this.photographerUrl,
    required this.averageColorHex,
    required this.sources,
    required this.alt,
    this.photographerId,
  });

  final int id;
  final int width;
  final int height;
  final Uri pexelsUrl;
  final String photographer;
  final Uri photographerUrl;
  final int? photographerId;
  final String? averageColorHex;
  final PhotoSources sources;
  final String alt;

  String get accessibleDescription => alt.trim().isEmpty ? 'Photo' : alt.trim();

  @override
  bool operator ==(Object other) => other is WallpaperPhoto && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class PhotoSources {
  const PhotoSources({
    required this.original,
    required this.large2x,
    required this.large,
    required this.medium,
    required this.small,
    required this.portrait,
    required this.landscape,
    required this.tiny,
  });

  final String original;
  final String large2x;
  final String large;
  final String medium;
  final String small;
  final String portrait;
  final String landscape;
  final String tiny;
}

class PhotoPage {
  const PhotoPage({
    required this.photos,
    required this.page,
    required this.perPage,
    required this.totalResults,
    required this.nextPage,
    required this.rateLimit,
  });

  final List<WallpaperPhoto> photos;
  final int page;
  final int perPage;
  final int totalResults;
  final int? nextPage;
  final RateLimitSnapshot? rateLimit;

  bool get hasMore => nextPage != null;
}

class RateLimitSnapshot {
  const RateLimitSnapshot({
    required this.limit,
    required this.remaining,
    required this.resetsAt,
  });

  final int? limit;
  final int? remaining;
  final DateTime? resetsAt;

  RateLimitSnapshot mergedWith(RateLimitSnapshot incoming) {
    final currentReset = resetsAt?.toUtc();
    final incomingReset = incoming.resetsAt?.toUtc();

    if (currentReset != null && incomingReset != null) {
      if (incomingReset.isBefore(currentReset)) {
        return this;
      }
      if (incomingReset.isAfter(currentReset)) {
        return RateLimitSnapshot(
          limit: incoming.limit ?? limit,
          remaining: incoming.remaining,
          resetsAt: incomingReset,
        );
      }
    }

    return RateLimitSnapshot(
      limit: incoming.limit ?? limit,
      remaining: _lowestKnown(remaining, incoming.remaining),
      resetsAt: incomingReset ?? currentReset,
    );
  }

  static int? _lowestKnown(int? current, int? incoming) {
    if (current == null) {
      return incoming;
    }
    if (incoming == null) {
      return current;
    }
    return current < incoming ? current : incoming;
  }

  @override
  bool operator ==(Object other) {
    return other is RateLimitSnapshot &&
        other.limit == limit &&
        other.remaining == remaining &&
        other.resetsAt == resetsAt;
  }

  @override
  int get hashCode => Object.hash(limit, remaining, resetsAt);
}
