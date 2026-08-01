import 'package:perle/src/models/wallpaper_photo.dart';

WallpaperPhoto makePhoto(
  int id, {
  String? alt,
  String photographer = 'Test Photographer',
}) {
  return WallpaperPhoto(
    id: id,
    width: 3000,
    height: 4500,
    pexelsUrl: Uri.parse('https://www.pexels.com/photo/$id/'),
    photographer: photographer,
    photographerUrl: Uri.parse('https://www.pexels.com/@photographer-$id'),
    photographerId: id + 1000,
    averageColorHex: '#445566',
    sources: PhotoSources(
      original: 'https://images.example.com/$id-original.jpg',
      large2x: 'https://images.example.com/$id-large2x.jpg',
      large: 'https://images.example.com/$id-large.jpg',
      medium: 'https://images.example.com/$id-medium.jpg',
      small: 'https://images.example.com/$id-small.jpg',
      portrait: 'https://images.example.com/$id-portrait.jpg',
      landscape: 'https://images.example.com/$id-landscape.jpg',
      tiny: 'https://images.example.com/$id-tiny.jpg',
    ),
    alt: alt ?? 'Test photo $id',
  );
}

PhotoPage makePage(
  List<WallpaperPhoto> photos, {
  int page = 1,
  int? nextPage,
  RateLimitSnapshot? rateLimit,
}) {
  return PhotoPage(
    photos: photos,
    page: page,
    perPage: 24,
    totalResults: photos.length,
    nextPage: nextPage,
    rateLimit: rateLimit,
  );
}
