#!/usr/bin/env bash
# Visual QA entry point
# Boot headless Android emulator, install Flutter app, run walkthrough, produce report.
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-/app/output}"
FLUTTER_APP_DIR="${FLUTTER_APP_DIR:-/app/flutter-app}"
VISUAL_QA_DIR="${VISUAL_QA_DIR:-/app/visual-qa}"
APP_PACKAGE="com.dejting.app"
APP_ACTIVITY="${APP_PACKAGE}/.MainActivity"
APK_PATH="${FLUTTER_APP_DIR}/build/app/outputs/flutter-apk/app-debug.apk"

mkdir -p "${OUTPUT_DIR}"

echo "==> Starting headless Android emulator..."
emulator -avd test_device \
    -no-window \
    -no-audio \
    -gpu swiftshader_indirect \
    -no-snapshot \
    -wipe-data &
EMULATOR_PID=$!

echo "==> Waiting for emulator to be ready..."
adb wait-for-device
# Poll for boot completion
until adb shell getprop sys.boot_completed 2>/dev/null | grep -q "^1$"; do
    echo "   ...still booting"
    sleep 5
done
echo "==> Emulator is ready."

# Keep screen awake during tests
adb shell settings put system screen_off_timeout 600000

echo "==> Building Flutter APK (debug)..."
cd "${FLUTTER_APP_DIR}"
flutter pub get
flutter build apk --debug

echo "==> Installing APK..."
adb install -r "${APK_PATH}"

echo "==> Launching app..."
adb shell am start -n "${APP_ACTIVITY}"
sleep 5

echo "==> Running visual QA navigator..."
cd "${VISUAL_QA_DIR}"
python3 navigator.py --output "${OUTPUT_DIR}"

echo "==> Running visual QA comparison..."
python3 compare.py \
    --current "${OUTPUT_DIR}" \
    --baselines "${VISUAL_QA_DIR}/baselines/" \
    --report "${OUTPUT_DIR}/report.md"

echo "==> Visual QA complete. Report: ${OUTPUT_DIR}/report.md"

# Gracefully shut down emulator
adb emu kill 2>/dev/null || true
if kill -0 "${EMULATOR_PID}" 2>/dev/null; then
    kill "${EMULATOR_PID}" || true
fi
