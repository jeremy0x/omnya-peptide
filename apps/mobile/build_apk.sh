#!/usr/bin/env bash
# ==============================================================================
# Omnya APK Build Script
# Automatically loads variables from apps/mobile/.env and passes them via --dart-define
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

cd "$SCRIPT_DIR"

# If .env does not exist, provide instructions
if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  No .env file found at apps/mobile/.env"
  if [ -f "$SCRIPT_DIR/.env.example" ]; then
    echo "📋 Creating .env from .env.example..."
    cp "$SCRIPT_DIR/.env.example" "$ENV_FILE"
    echo "Please set your IMGBB_API_KEY in apps/mobile/.env and run again."
    exit 1
  fi
fi

# Parse IMGBB_API_KEY from .env
IMGBB_API_KEY=$(grep -E '^IMGBB_API_KEY=' "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'" | tr -d '\r')

if [ -z "$IMGBB_API_KEY" ] || [ "$IMGBB_API_KEY" = "your_imgbb_api_key_here" ]; then
  echo "⚠️  IMGBB_API_KEY is not configured in apps/mobile/.env"
  echo "    Photo upload features will be disabled unless IMGBB_API_KEY is provided."
  BUILD_ARGS=""
else
  echo "🔑 Loaded IMGBB_API_KEY from .env"
  BUILD_ARGS="--dart-define=IMGBB_API_KEY=$IMGBB_API_KEY"
fi

echo "🚀 Building Release APK for Omnya Peptide..."
flutter build apk --release $BUILD_ARGS "$@"

echo "✅ Build complete! APK generated at:"
echo "   apps/mobile/build/app/outputs/flutter-apk/app-release.apk"
