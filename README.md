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

### Windows (PowerShell)

Install Python 3.10+ and the Google Cloud CLI, then open PowerShell in the
repository root. Use the virtual environment's Python directly; activation is
not required:

```powershell
cd tools\tournament-import
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt -c requirements-lock.txt
.\.venv\Scripts\python.exe import_tournaments.py template tournaments.xlsx
gcloud auth application-default login
gcloud auth application-default set-quota-project curling-companion-28e7a
```

Fill in and save the workbook. Replace `FIREBASE_AUTH_UID` below with the
organizer's Firebase Auth user ID. Preview and validate with `-n`, then run
without `-n` and type `IMPORT` when prompted:

```powershell
.\.venv\Scripts\python.exe import_tournaments.py import tournaments.xlsx -p curling-companion-28e7a -oid FIREBASE_AUTH_UID -n
.\.venv\Scripts\python.exe import_tournaments.py import tournaments.xlsx -p curling-companion-28e7a -oid FIREBASE_AUTH_UID
```

If using a service-account key instead of Google login, set its path in the
same PowerShell session before running the importer:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\outside-repository\service-account.json"
```

To switch back to your Google login, clear that override:

```powershell
Remove-Item Env:GOOGLE_APPLICATION_CREDENTIALS -ErrorAction SilentlyContinue
```

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

## Explicit terms acceptance

Registration requires an unchecked **I accept the Terms of use** checkbox.
The adjacent **Read terms** link opens the same German or English terms shown
on the legal notice page, without clearing the registration form. The selected
language is saved with the acceptance.

After account creation, acceptance is recorded at
`users/{uid}/termsAcceptances/2026-10-07` with `version`, `accepted: true`,
`acceptedAt` (a Firestore server timestamp), and `language`. Firestore rules
allow users to create only their own valid current-version record and prohibit
client updates or deletion. Retries read the existing record and preserve the
original timestamp. Profile fields cannot grant terms acceptance.

Posting, editing, and image uploads require both verified email and recorded
acceptance. Browsing, settings, and owned-content deletion remain available.
If saving acceptance fails after account creation, the registration form
allows a retry without registering another account. No migration or
existing-user rollout is implemented; existing accounts will be removed by
the project owner.

Immutable German and English snapshots are in `docs/terms/2026-10-07.*.md`.
When changing the terms, archive a new version and update the version in
`lib/terms.dart`, `firestore.rules`, and `functions/authorization.js` together.
The backend tests check that these versions and the displayed text agree.
Deploy the web app, Firestore rules, and `uploadMarketplaceImage` together
using the deployment command in the email verification section.
