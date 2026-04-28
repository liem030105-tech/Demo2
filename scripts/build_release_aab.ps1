$ErrorActionPreference = "Stop"

$defineFile = Resolve-Path ".env/supabase.prod.json"

Push-Location "app"
try {
  flutter pub get
  flutter build appbundle --release --dart-define-from-file="$defineFile"
} finally {
  Pop-Location
}

