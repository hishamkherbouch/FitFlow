# Testing Strategy (Windows-to-iOS)

## 1. Daily Development
- **Target:** Android Emulator (Pixel 6/7 profile).
- **Tool:** Flutter Run (F5 in Cursor).

## 2. Visual Layout
- **iOS Preview:** Use the `device_preview` package to see the "iPhone" UI frame on Windows.
- **Goal:** Ensure "The Notch" and status bars don't overlap UI.

## 3. Remote Validation
- **Method:** Periodically run `flutter build ipa --no-codesign` on Codemagic to check for Apple-specific errors.
- **Verification:** Run `flutter doctor -v` to ensure the local Windows environment is healthy.
