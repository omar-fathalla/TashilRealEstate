#!/usr/bin/env bash
# Builds the web app after checking FIREBASE_ENV (TAQ-82). `flutter build web` accepts any
# --dart-define value and a typo only shows up as a white screen at start-up, so refuse anything
# but prod or dev here. Without the define the build is prod, as before.
#
#   tool/build_web.sh --release [--dart-define=FIREBASE_ENV=dev --dart-define=DEV_FIREBASE_WEB_API_KEY=...]
#
# Every argument is passed on to `flutter build web`. FLUTTER overrides the flutter command.
set -euo pipefail

env_value="prod"
seen=0
for arg in "$@"; do
  case "$arg" in
    --dart-define=FIREBASE_ENV=*)
      env_value="${arg#--dart-define=FIREBASE_ENV=}"
      seen=$((seen + 1))
      ;;
    --dart-define=FIREBASE_ENV)
      echo "build_web: pass FIREBASE_ENV as --dart-define=FIREBASE_ENV=prod|dev" >&2
      exit 2
      ;;
  esac
done

if [ "$seen" -gt 1 ]; then
  echo "build_web: FIREBASE_ENV is given more than once" >&2
  exit 2
fi
if [ "$env_value" != "prod" ] && [ "$env_value" != "dev" ]; then
  echo "build_web: FIREBASE_ENV must be prod or dev, got '$env_value'" >&2
  exit 2
fi

cd "$(dirname "$0")/.."
exec ${FLUTTER:-flutter} build web "$@"
