# Google Play “Data safety” checklist (draft)

Use this as a checklist when filling **App content → Data safety** in Play Console. You must align declarations with what the shipped APK/AAB actually does.

## Data types (based on current app scope)

### Personal info
- **Email address**: collected for account creation/sign-in (Supabase Auth).

### Photos and videos / Files and docs
- **User-uploaded files/photos**: collected only if the user chooses to upload (Supabase Storage).

### App activity / Diagnostics (only if you ship analytics/crash SDK)
The current codebase does **not** include an analytics/crash SDK. If you add one:
- declare **Diagnostics** and/or **App activity** as appropriate
- update `[PRIVACY_POLICY.md](PRIVACY_POLICY.md)` and this checklist

## Typical answers (adjust to your real implementation)

- **Is all data encrypted in transit?** Yes (HTTPS/TLS).
- **Is data processed ephemerally?** No (stored in Supabase).
- **Is data shared with third parties?** Yes (Supabase as service provider). If you add analytics/crash, also Yes.
- **Is data required for app to function?**
  - Email: Yes (if sign-in is required).
  - Uploads: Only if the user uses that feature.
- **Can users request deletion?** Provide a support email and (optionally) an in-app delete account flow.

## Links you will need in Play Console

- **Privacy Policy URL**: host the content of `[PRIVACY_POLICY.md](PRIVACY_POLICY.md)` on a public URL (website / GitHub Pages) and paste it into Play Console.

