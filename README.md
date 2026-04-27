# mobile_dejtingapp

Flutter client for the DatingApp platform (mobile + web targets).

## What It Does

The app provides end-user product flows, including:
- Auth and onboarding
- Discovery and swipe interactions
- Match and messaging experiences
- Profile, settings, and verification flows

## Why It Is Interesting

This is the strongest frontend showcase repo in the platform:
- Multi-screen production app architecture
- Service-oriented client layer (`lib/services`)
- Test coverage with widget and service tests
- Integration with multiple backend services

## Stack

- Flutter 3.32.1
- Dart 3.5
- Riverpod-lite patterns
- API + real-time service integrations

## Project Layout

```text
dejtingapp/
  lib/
    screens/      # Product UI and flows
    services/     # API/auth/messaging/swipe/photo services
    models/       # Data models
    widgets/      # Reusable UI components
    theme/        # App design system / theme
  test/           # Widget + service tests
  integration_test/
```

## Setup

```bash
flutter pub get
```

## Run

```bash
flutter run
```

For web target:

```bash
flutter run -d chrome
```

## Analyze and Test

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

## Backends Used

This client integrates with:
- UserService
- MatchmakingService
- swipe-service
- messaging-service
- photo-service
- dejting-yarp gateway

## Status

Most recently updated, high-signal repo for portfolio/demo review.
