$ErrorActionPreference = "Stop"

$defineFile = Resolve-Path ".env/supabase.dev.json"

Push-Location "app"
try {
  flutter pub get
  flutter run --dart-define-from-file="$defineFile"
} finally {
  Pop-Location
}

