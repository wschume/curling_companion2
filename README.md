# Curling Companion

Public Flutter web first draft for curling marketplaces, tournaments, and event player discovery.

## Firebase setup

1. Install FlutterFire CLI and run `flutterfire configure`.
2. Replace the placeholder `lib/firebase_options.dart` with the generated file.
3. Copy `.firebaserc.example` to `.firebaserc` and set the Firebase project ID.
4. Enable Email/Password authentication, Cloud Firestore, and Cloud Storage in Firebase.

### Cloud Storage CORS

Marketplace images are loaded directly by the Flutter web client. Apply the
included CORS configuration to the Firebase Storage bucket once (requires the
Google Cloud CLI and Storage Admin access):

```sh
gcloud storage buckets update gs://curling-companion-28e7a.firebasestorage.app \
  --cors-file=storage.cors.json
```

The configuration permits browser `GET` requests from any origin. This is
appropriate for marketplace images because they are intentionally public.

Without Firebase configuration, the app deliberately uses placeholder in-memory data so the UI and tests can run locally.

## Run locally

In VS Code, select **Flutter Chrome** and use **Run > Run Without Debugging**
(`Ctrl+F5`). The launch task installs dependencies and generates model mappers
automatically before opening Chrome.

From a terminal:

```sh
flutter pub get
dart run build_runner build
flutter run -d chrome --release
```

## Checks

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web
```

The self-hosted GitHub Actions workflow validates every push and pull request, and deploys Hosting, Firestore/Storage rules, and the verified-email image-upload function from `main`. Configure `FIREBASE_PROJECT_ID` and `FIREBASE_TOKEN` repository secrets before enabling deployment.

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

To run analysis and tests before deploying, add `--run-tests`. To deploy Firestore rules and indexes, Cloud Storage rules, and Hosting, add `--include-firestore`:

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

## Email verification

New accounts receive a verification email in the app's selected language.
Unverified accounts can browse public content, manage account settings, and
remove their own content, but cannot post, edit, or upload listing images.
After following the email link, users can select **I've verified my email**;
the app also refreshes the user and ID token when returning to the browser tab.
The verification screen supports resending failed or missing emails.

In Firebase Console, open **Authentication → Templates → Email address
verification** and configure the sender name and email template. Firebase's
hosted handler processes the verification link. An optional return button can
point back to the app by building with:

```sh
flutter build web --release \
  --dart-define=EMAIL_VERIFICATION_RETURN_URL=https://YOUR_SITE/verify-email
```

Add that return URL's domain under **Authentication → Settings → Authorized
domains**. Without this build setting, the Firebase hosted handler is used
without an app-specific return URL. Email changes also require confirmation;
the previous email stays visible and active until Firebase confirms the new one.

Deploy all verification enforcement together, including the image-upload
function (a Hosting-only deployment does not update backend permissions):

```sh
npm --prefix functions install
firebase deploy --project YOUR_FIREBASE_PROJECT_ID \
  --only hosting,firestore:rules,functions:uploadMarketplaceImage
```

Build the web app before this deployment. No account migration is needed.
Any retained Firebase Authentication accounts must verify as well; clearing
Firestore does not clear Authentication accounts. When Firebase is unavailable,
the verification screen has a **Simulate verification (local demo)** button.

Backend checks use Node 22. The Firestore emulator also requires Java 21 with
the current Firebase CLI:

```sh
npm --prefix functions install
npm --prefix functions test
npm --prefix functions run test:rules
```

The rules tests run against the isolated `demo-curling-verification` emulator
project, using `firebase.test.json`, and do not access the live database.
