#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./deploy_local.sh [options]

Builds and deploys the Flutter web site directly through the Firebase CLI.

Options:
  --project ID       Firebase project ID (defaults to FIREBASE_PROJECT_ID)
  --env-file FILE    dotenv file to load (defaults to .env)
  --run-tests        Run flutter analyze and flutter test before deployment
  --include-firestore Deploy Hosting plus Firestore rules/indexes
  -h, --help         Show this help

Authentication:
  Use an interactive `firebase login`, or export FIREBASE_TOKEN for CI-style auth.
EOF
}

ENV_FILE="${ENV_FILE:-.env}"
PROJECT_ID_ARG=""
DEPLOY_TARGETS="hosting"
RUN_TESTS=false

load_dotenv() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    [[ "$line" == export\ * ]] && line="${line#export }"
    [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=(.*)$ ]] || continue

    local key="${BASH_REMATCH[1]}"
    local value="${BASH_REMATCH[2]}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    case "$value" in
      \"*\") value="${value:1:${#value}-2}" ;;
      \'*\') value="${value:1:${#value}-2}" ;;
    esac

    # Keep explicitly exported shell variables ahead of values from .env.
    if [[ -z "${!key+x}" ]]; then
      printf -v "$key" '%s' "$value"
      export "$key"
    fi
  done < "$file"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || { echo "Missing value for --project" >&2; exit 2; }
      PROJECT_ID_ARG="$2"
      shift 2
      ;;
    --env-file)
      [[ $# -ge 2 ]] || { echo "Missing value for --env-file" >&2; exit 2; }
      ENV_FILE="$2"
      shift 2
      ;;
    --include-firestore)
      DEPLOY_TARGETS="hosting,firestore"
      shift
      ;;
    --run-tests)
      RUN_TESTS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

load_dotenv "$ENV_FILE"

PROJECT_ID="${PROJECT_ID_ARG:-${FIREBASE_PROJECT_ID:-}}"

command -v flutter >/dev/null 2>&1 || { echo "Flutter is required but was not found in PATH." >&2; exit 1; }
command -v firebase >/dev/null 2>&1 || { echo "Firebase CLI is required. Install it with: npm install -g firebase-tools" >&2; exit 1; }

if [[ -z "$PROJECT_ID" && -f .firebaserc ]]; then
  PROJECT_ID="$(sed -n 's/.*"default"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .firebaserc | head -n 1)"
fi

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "your-firebase-project-id" ]]; then
  echo "Firebase project ID is missing." >&2
  echo "Pass --project YOUR_PROJECT_ID or set FIREBASE_PROJECT_ID." >&2
  exit 1
fi

echo "==> Resolving Flutter dependencies"
flutter pub get

echo "==> Generating mappers"
dart run build_runner build

if [[ "$RUN_TESTS" == true ]]; then
  echo "==> Running analyzer"
  flutter analyze
  echo "==> Running tests"
  flutter test
fi

echo "==> Building Flutter web application"
flutter build web

firebase_args=(deploy --project "$PROJECT_ID" --only "$DEPLOY_TARGETS")
if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
  firebase_args+=(--token "$FIREBASE_TOKEN")
else
  echo "==> FIREBASE_TOKEN is not set; Firebase CLI will use your local login."
fi

echo "==> Deploying $DEPLOY_TARGETS to Firebase project $PROJECT_ID"
firebase "${firebase_args[@]}"

echo "Deployment completed successfully."
