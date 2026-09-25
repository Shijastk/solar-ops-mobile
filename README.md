# Solar Ops Mobile

Flutter mobile client for the Solar Ops workflow.

This repository starts with a clean, simple dashboard UI inspired by the provided reference image and is structured to connect to the existing Solar Ops backend in later phases.

## Run locally

```bash
flutter pub get
flutter run
```

## Checks

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

GitHub Actions runs analyze, tests, and build checks on pushes and pull requests to `main`.
