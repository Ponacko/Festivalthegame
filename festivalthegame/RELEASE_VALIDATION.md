# Release validation — 2026-08-26

## Automated profile

- Maximum content: 10 Favorites, four Friends, full generated Lineup.
- Cold generation: 11.4 s (budget: 15 s).
- Busy simulation preparation: 2.751 ms average (budget: 16.7 ms).
- Static memory: 25.7 MiB (budget: 256 MiB).
- Release audit found no runtime HTTP client calls; taxonomy, art, theme, scenes, and all audio loops were included in the Android release pack.

## Android

- Godot 4.6.2 standard arm64 debug export completed and produced a 27 MiB APK.
- `apksigner` verified APK Signature Scheme v2 and v3 with one debug signer.
- `aapt dump permissions` reported the package identifier and no requested permissions, including no Internet permission.
- `adb install -r` succeeded on the connected Android 16 `Small_Phone` emulator with networking disconnected.
- Package `com.festivalthegame.game` launched as the top resumed activity and remained alive without GDScript, fatal Java, or native crash logs.
- The emulator cannot complete the visual pass: its SwiftShader Vulkan path fails `QueuePresentKHR`, while its OpenGL ES 3 translator exposes only 256 fragment uniform vectors and fails Godot 4.6.2's built-in 261-vector canvas shader. Repeat the visual/touch checklist on representative physical hardware before store submission.

The generated debug artifact is retained locally at `build/android/FestivalTheGame.apk` and is intentionally ignored by Git. SHA-256: `c097c38f78eae464216a306340534a6a61cbee29bf316438f4bdce3449858490`. Release signing remains a local credentialed step.

## iOS

- The iOS arm64 preset, bundle identifier, minimum iOS version, offline privacy configuration, and manual signing instructions are versioned.
- Export/build/signing requires macOS, Xcode, an Apple developer team, and a provisioning profile; these are unavailable in the Linux validation environment. Complete `MOBILE_SMOKE_TEST.md` on physical iPhone and iPad hardware before submission.
