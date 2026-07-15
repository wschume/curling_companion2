# Curling Companion

Public Flutter web first draft for curling marketplaces, tournaments, and event player discovery.

## Firebase setup

1. Install FlutterFire CLI and run `flutterfire configure`.
2. Replace the placeholder `lib/firebase_options.dart` with the generated file.
3. Copy `.firebaserc.example` to `.firebaserc` and set the Firebase project ID.
4. Enable Email/Password authentication and Cloud Firestore in Firebase.

Without Firebase configuration, the app deliberately uses placeholder in-memory data so the UI and tests can run locally.

## Checks

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web
```

The self-hosted GitHub Actions workflow validates every push and pull request, and deploys Hosting plus Firestore rules from `main`. Configure `FIREBASE_PROJECT_ID` and `FIREBASE_TOKEN` repository secrets before enabling deployment.

## Local deployment

Install and authenticate the Firebase CLI, then run the same build/deploy flow locally:

```sh
npm install -g firebase-tools
firebase login
./deploy_local.sh --project YOUR_FIREBASE_PROJECT_ID
```

Alternatively, copy `.env.example` to `.env` and set `FIREBASE_PROJECT_ID`. The deployment script loads `.env` automatically; explicitly exported shell variables take precedence. The `.env` file is ignored by Git.

By default, the script resolves dependencies, generates mappers, builds the web application, and deploys Hosting only. To use a CI-style token instead of the local Firebase login:

```sh
export FIREBASE_TOKEN="your-token"
./deploy_local.sh --project YOUR_FIREBASE_PROJECT_ID
```

You may also put `FIREBASE_TOKEN` in `.env` for local-only use. Never commit that file.

To run analysis and tests before deploying, add `--run-tests`. To deploy Firestore rules and indexes as well as Hosting, add `--include-firestore`:

```sh
./deploy_local.sh --run-tests --include-firestore
```


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
