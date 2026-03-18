# DatingApp Flutter Client

Flutter 3.32.1 + Dart 3.5 dating app with dark theme.

## Build & Test
```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Architecture
- Screens: lib/screens/ (onboarding wizard, discover, matches, chat, profile)
- Widgets: lib/widgets/ (reusable UI components)
- Services: lib/services/ (API, messaging, auth, photo)
- Models: lib/models/ (data classes)
- Theme: lib/theme/ (AppTheme with dark mode, primaryColor=coral #FF7F50)
- i18n: lib/l10n/ (Swedish + English)

## Test Patterns
- Widget tests use `buildCoreScreenTestApp()` wrapper from test helpers
- Mock services with Mockito
- Test file mirrors source: lib/screens/x.dart → test/screens/x_test.dart

## Code Style
- analysis_options.yaml with pedantic + lint rules
- All new code must have corresponding widget tests
