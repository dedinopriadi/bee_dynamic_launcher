## 1.1.0

- Add optional per-variant branding style metadata in `catalog.json` (`baseColor`, `secondaryColor`, `backgroundColor`, `surfaceColor`) with safe fallback behavior.
- Add style helper APIs:
  - `styleForVariant`, `currentStyle`
  - `applyVariantAndGetStyle` (one-call apply + resolve style)
- Add ready-to-use Flutter color helpers:
  - `LauncherVariantResolvedColors`
  - `styleColorsForVariant`, `currentStyleColors`
  - `applyVariantAndGetStyleColors` (one-call apply + resolve colors)
- Update example app to demonstrate active variant styling and color usage with the new API.

## 1.0.1

- Android: resolve activity-alias `ComponentName` using the merged manifest namespace (Gradle `namespace`) while keeping the install-time package as `context.packageName`. Fixes `applicationIdSuffix` / product-flavor installs where aliases are registered as `namespace.Launcher…` but the app id is `namespace.staging` (or similar).

## 1.0.0

- First stable release: `BeeDynamicLauncher` MethodChannel API for Android and iOS.
- `LauncherCatalog` with JSON loading, preview path getters (`allPreviewIconAssetPaths`, `variantEntryFor`, `launcherLabelFor`, and related helpers).
- `BeeDynamicLauncher.previewIconAssetPath` for in-app preview assets.
- CLI: `dart run bee_dynamic_launcher` — validate assets, patch Android/iOS markers, resize icons; flags `--icons-only`, `--native-only`, `--scan`, `--wizard`, etc.
