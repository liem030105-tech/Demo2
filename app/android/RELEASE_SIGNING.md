## Release signing (Android / Google Play)

### 1) Create a keystore (one-time)

Run in PowerShell from the **`app/android`** folder (same folder as `key.properties`):

```powershell
Set-Location "path\to\your\repo\app\android"

keytool -genkeypair -v `
  -keystore "$PWD\upload-keystore.jks" `
  -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

### 2) Create `key.properties` (local-only)

Copy `[app/android/key.properties.example](app/android/key.properties.example)` to `app/android/key.properties` and fill in values.

Example:

```properties
storePassword=*****
keyPassword=*****
keyAlias=upload
storeFile=../upload-keystore.jks
```

`storeFile` is resolved from the **`app/android/app`** module directory, so when the `.jks` lives in **`app/android/`**, use **`../upload-keystore.jks`**.

Notes:
- `key.properties` and `*.jks` are gitignored.
- The Gradle config uses **debug signing** automatically if `key.properties` is missing (handy for local testing), but for Play Store you must provide a real release keystore.

### 3) Build AAB

From repo root:

```powershell
.\scripts\build_release_aab.ps1
```

