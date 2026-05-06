#!/usr/bin/env bash
set -euo pipefail

APP_ID="com.jeeridev.recipecleanapp"
APP_PATH="com/jeeridev/recipecleanapp"
DEVICE_ID="${1:-}"

echo "==> Vérification espace disque"
df -h . "$HOME" || true

echo "==> Arrêt des daemons Gradle/Java liés au build"
pkill -9 -f GradleDaemon 2>/dev/null || true
pkill -9 -f gradle 2>/dev/null || true

echo "==> Nettoyage caches locaux du projet"
rm -rf build .dart_tool
rm -rf android/.gradle android/build android/app/build android/.kotlin 2>/dev/null || true

echo "==> Nettoyage caches Flutter/Gradle globaux volumineux"
rm -rf "$HOME/.gradle/daemon" "$HOME/.gradle/caches" 2>/dev/null || true
rm -rf "$HOME/.pub-cache/_temp" 2>/dev/null || true
rm -rf /tmp/gradle-* /tmp/flutter_tools.* 2>/dev/null || true

echo "==> Régénération Android si nécessaire"
if [ ! -d android ]; then
  flutter create --platforms=android .
fi

echo "==> Correction applicationId/namespace Android"
if [ -f android/app/build.gradle.kts ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path('android/app/build.gradle.kts')
s = p.read_text()
s = s.replace('namespace = "com.example.recipe_clean_app"', 'namespace = "com.jeeridev.recipecleanapp"')
s = s.replace('applicationId = "com.example.recipe_clean_app"', 'applicationId = "com.jeeridev.recipecleanapp"')
s = s.replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
p.write_text(s)
PY
elif [ -f android/app/build.gradle ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path('android/app/build.gradle')
s = p.read_text()
s = s.replace('namespace "com.example.recipe_clean_app"', 'namespace "com.jeeridev.recipecleanapp"')
s = s.replace('applicationId "com.example.recipe_clean_app"', 'applicationId "com.jeeridev.recipecleanapp"')
s = s.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 23')
p.write_text(s)
PY
fi

echo "==> Correction MainActivity.kt"
mkdir -p "android/app/src/main/kotlin/$APP_PATH"
find android/app/src/main/kotlin -name MainActivity.kt -not -path "*/$APP_PATH/MainActivity.kt" -delete 2>/dev/null || true
cat > "android/app/src/main/kotlin/$APP_PATH/MainActivity.kt" <<'KOTLIN'
package com.jeeridev.recipecleanapp

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
KOTLIN

echo "==> Correction AndroidManifest.xml"
if [ -f android/app/src/main/AndroidManifest.xml ]; then
  python3 - <<'PY'
from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text()
s = s.replace('android:name="com.jeeridev.recipecleanapp.MainActivity"', 'android:name=".MainActivity"')
s = s.replace('android:name="com.example.recipe_clean_app.MainActivity"', 'android:name=".MainActivity"')
p.write_text(s)
PY
fi

echo "==> Récupération dépendances"
flutter pub get

echo "==> App Android configurée. Relance Firebase si google-services.json manque."
if [ ! -f android/app/google-services.json ]; then
  echo "ATTENTION: android/app/google-services.json manquant. Lance:"
  echo "flutterfire configure --project=login-d11f5 --platforms=android"
fi

echo "==> Lancement"
if [ -n "$DEVICE_ID" ]; then
  flutter run -d "$DEVICE_ID"
else
  flutter run
fi
