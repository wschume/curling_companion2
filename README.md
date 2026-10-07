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

## Excel tournament importer (Python)

The standalone importer requires Python 3.10+ and uses Firebase Admin credentials.
Create an environment and install its pinned dependencies:

```sh
cd tools/tournament-import
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt -c requirements-lock.txt
python import_tournaments.py template tournaments.xlsx
```

On Linux Mint, install `python3-venv` if environment creation reports missing
`ensurepip`. Fill in the `Tournaments` worksheet; its instructions sheet lists
required fields, date formats, and validation rules. Keep the headers unchanged.
Native Excel dates and `YYYY-MM-DD` text are accepted; formulas are rejected.
The importer follows the app form: name, city, country, club, contact and dates
are required; events must last more than zero and at most five days.

### Google authentication

The importer uses Application Default Credentials (ADC). For local use with
your Google account, first [install the Google Cloud CLI](https://cloud.google.com/sdk/docs/install),
then run:

```sh
gcloud auth application-default login
gcloud auth application-default set-quota-project curling-companion-28e7a
```

Complete the browser login with the Google account that has access to the target
Firebase project. Replace `curling-companion-28e7a` when using another project.
The quota-project step is required for Firebase Auth with these user credentials;
passing `--project` to the importer does not configure the ADC quota project.
If this step fails with a permission error, ask a project administrator to grant
your account `serviceusage.services.use`, for example through the Service Usage
Consumer role. Your account also needs permission to read Firebase Auth users
and read/write Firestore tournaments in the target project.

If `GOOGLE_APPLICATION_CREDENTIALS` is already set, it takes precedence over the
local Google login. To use your Google account instead, run
`unset GOOGLE_APPLICATION_CREDENTIALS` in the terminal running the importer.

Alternatively, use a service-account JSON key with the required project access.
Keep the key outside this repository and set its absolute path in the same
terminal where you run the importer:

```sh
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
```

See Google's [local ADC setup guide](https://cloud.google.com/docs/authentication/set-up-adc-local-dev-environment)
and [quota-project command reference](https://docs.cloud.google.com/sdk/gcloud/reference/auth/application-default/set-quota-project).

### Preview and import

After authenticating, run a dry run first, then import:

```sh
python import_tournaments.py import tournaments.xlsx \
  --project curling-companion-28e7a --organizer-id FIREBASE_AUTH_UID --dry-run
python import_tournaments.py import tournaments.xlsx \
  --project curling-companion-28e7a --organizer-id FIREBASE_AUTH_UID
```

The organizer must exist in Firebase Auth. Firebase CLI login alone does not
supply Admin SDK credentials. Admin SDK access uses IAM rather than the app's
Firestore rules. The dry run still verifies the organizer and existing records.
Every parsed field is printed before the interactive `IMPORT` confirmation.
Validation errors and duplicates block the entire list; no records are updated.
At most 500 records are created in one atomic batch. Duplicate identity is
Unicode-normalized, case-insensitive name and city plus the stored start calendar
date. Stable IDs prevent competing importer runs from creating duplicates;
simultaneous manual app creation can still race with the final duplicate check.
Dates are stored as UTC-midnight ISO strings compatible with the Flutter mapper.

Tests:

```sh
pip install -r requirements-dev.txt -c requirements-lock.txt
python -m pytest tests
```

The emulator integration test runs when `FIRESTORE_EMULATOR_HOST` and
`FIREBASE_AUTH_EMULATOR_HOST` are both set. Use a Firebase Emulator Suite
configuration enabling Firestore and Auth, with a `demo-` project; the test uses
isolated project IDs and checks atomic conflict behavior. Without both variables,
that test is skipped. No test writes to production Firebase.

From the repository root, run the emulator tests with:

```sh
firebase emulators:exec --config tools/tournament-import/emulators.json \
  --project demo-tournament-import --only auth,firestore \
  'tools/tournament-import/.venv/bin/python -m pytest tools/tournament-import/tests -q'
```

A Dart round-trip checker is included at
`tools/tournament-import/tests/mapper_roundtrip.dart`. After generating mappers,
run it with a JSON document emitted by the Python `document()` function:

```sh
dart --packages=.dart_tool/package_config.json \
  tools/tournament-import/tests/mapper_roundtrip.dart /path/to/document.json
```
