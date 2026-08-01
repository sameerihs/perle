import 'package:url_launcher/url_launcher.dart';

const pexelsHomeUrl = 'https://www.pexels.com/';

Future<bool> openPexelsLink(Uri uri) async {
  if (!_isTrustedPexelsUri(uri)) {
    return false;
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

bool _isTrustedPexelsUri(Uri uri) {
  final host = uri.host.toLowerCase();
  return uri.scheme == 'https' &&
      (host == 'pexels.com' || host.endsWith('.pexels.com'));
}
