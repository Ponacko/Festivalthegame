# Mobile release

## Supported targets and budgets

- Landscape Android 9+ on arm64 and iOS/iPadOS 15+ on arm64.
- Target: 60 fps (16.7 ms steady-state simulation/render-preparation time), 256 MiB static memory, and under 15 seconds for a cold maximum-Friends Festival generation on the headless profiled equivalent.
- Scaling uses Godot `canvas_items` with `expand`; modal screens use percentage anchors, the HUD reads the OS safe area, and the Camera is limited to generated grounds.
- The game requests no network, camera, microphone, photo, location, or vibration permission. All taxonomy, procedural data, art, and audio are bundled.

Run the automated equivalent profile with:

```sh
godot --headless --path festivalthegame res://tests/test_mobile_budget.tscn
```

Complete the device pass in `MOBILE_SMOKE_TEST.md` before publishing.

## Android build and signing

1. Install Godot 4.6.2 export templates, OpenJDK 17, Android SDK Platform/Build Tools, and configure the SDK path in Godot Editor Settings.
2. For local smoke testing: `godot --headless --path festivalthegame --export-debug Android ../build/android/FestivalTheGame.apk`.
3. Install with `adb install -r build/android/FestivalTheGame.apk`, enable airplane mode, and complete `MOBILE_SMOKE_TEST.md`.
4. For release, create a keystore outside the repository and provide its path, alias, and passwords through the local Godot editor/export environment. Never add keystores, provisioning material, passwords, or generated build output to Git.
5. Export the signed release APK/AAB from the Android preset and verify its signature before upload.

## iOS build and manual signing

1. On supported macOS, install Godot 4.6.2 export templates and the current Xcode toolchain.
2. Export the iOS preset to `build/ios/FestivalTheGame.zip`, unpack it, and open the generated Xcode project.
3. Select the developer team, replace `com.festivalthegame.game` only if the registered identifier differs, and configure the distribution provisioning profile manually.
4. Build to a physical arm64 iPhone and iPad, run the airplane-mode smoke test, then Archive and Validate in Xcode.

iOS signing cannot be completed on Linux; credentials and provisioning profiles are intentionally not committed.
