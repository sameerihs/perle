# Perle

Perle is a minimal Flutter wallpaper browser powered by the Pexels API.

The app opens directly on the Explore screen. It has no account, authentication,
Firebase, or logout flow. Explore, Search, and Likes share one small controller,
and all remote loading has explicit progress, empty, error, and retry states.

Current prototype features include:

- Pexels' live curated photo feed
- Paginated Explore and Search results with ID-based deduplication
- Orientation, minimum-size, and color search filters
- Dominant-color loading placeholders
- Full-screen zoomable photo details
- Photographer attribution and links back to Pexels
- Local, session-only Likes shared across every screen
- Pexels API quota tracking from response headers

## Project status

- The legacy Firebase and authentication flows have been removed completely.
- A fresh launch opens directly on Explore and loads the live curated feed.
- iOS 13 is the minimum deployment target; URL launching is integrated through
  Flutter's generated Swift Package Manager package.
- The current build was verified on an iPhone 17 Pro simulator running iOS 26.5.
- `flutter analyze` is clean, all 31 tests pass, and the unsigned iOS Simulator
  build succeeds with the local API configuration.
- Firebase wiring has also been removed from Android, but the legacy Android
  Gradle toolchain has not yet been modernized or tested with the current Flutter
  SDK.

## Run locally

Copy the local configuration template and add a Pexels API key:

```sh
cp dart_defines.example.json dart_defines.json
# Edit dart_defines.json, then:
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

`dart_defines.json` is ignored by Git.

To choose a particular iOS simulator:

```sh
flutter devices
flutter run -d <simulator-id> \
  --dart-define-from-file=dart_defines.json
```

The API key that used to be committed in the Dart source should be considered
exposed and rotated. `dart-define` keeps it out of this repository, but a key
embedded in a distributed client app is still discoverable; use a small backend
proxy if the key must be kept secret in production.

## Verify changes

```sh
flutter analyze
flutter test
flutter build ios --simulator \
  --dart-define-from-file=dart_defines.json
```

## Pexels usage notice

[Pexels' current API guidelines](https://www.pexels.com/api/documentation/)
explicitly disallow using its content to create a wallpaper app. This repository
uses the integration only as a private learning prototype. Replace the provider
or obtain written permission before publishing or distributing it.
