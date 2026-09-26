#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

cd "$SCRIPT_DIR"

if [ ! -f "$ENV_FILE" ]; then
  if [ -f "$SCRIPT_DIR/.env.example" ]; then
    echo "Notice: .env not found. Creating from .env.example..."
    cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
    echo "Set IMGBB_API_KEY in apps/mobile/.env before building."
    exit 1
  fi
fi

IMGBB_API_KEY=$(grep -E '^IMGBB_API_KEY=' "$ENV_FILE" 2>/dev/null | cut -d '=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r' || true)

BUILD_ARGS=()
if [ -n "$IMGBB_API_KEY" ] && [ "$IMGBB_API_KEY" != "your_imgbb_api_key_here" ]; then
  BUILD_ARGS+=("--dart-define=IMGBB_API_KEY=$IMGBB_API_KEY")
else
  echo "Warning: IMGBB_API_KEY not configured. Building without photo upload key."
fi

echo "Building release APK..."
flutter build apk --release "${BUILD_ARGS[@]}" "$@"

echo "Build complete: apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
