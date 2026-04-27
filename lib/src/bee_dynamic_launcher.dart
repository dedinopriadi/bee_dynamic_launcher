import 'package:flutter/services.dart';

import 'channel.dart';
import 'launcher_catalog.dart';

/// Controls the home-screen launcher icon (and on Android, the launcher label) via a
/// platform [MethodChannel].
///
/// Call [initialize] after loading your catalog so native code knows valid variant ids.
/// Persisting the user’s choice is the host app’s responsibility.
///
/// Preview images for in-app UI use the same paths as [launcherIconPreviewAssetPath]
/// and [LauncherCatalog.allPreviewIconAssetPaths].
class BeeDynamicLauncher {
  BeeDynamicLauncher._();

  static const MethodChannel _channel = MethodChannel(
    beeDynamicLauncherMethodChannelName,
  );

  /// Returns the preview icon asset path for a variant id.
  ///
  /// This path is intended for in-app UI (for example in `Image.asset`) and
  /// does not indicate whether the OS launcher icon has already changed.
  static String previewIconAssetPath(String variantId) =>
      launcherIconPreviewAssetPath(variantId);

  /// Returns optional branding style metadata for [variantId].
  ///
  /// If the catalog does not define style for this variant, [defaultStyle] is
  /// returned.
  static LauncherVariantStyle? styleForVariant(
    String variantId, {
    LauncherVariantStyle? defaultStyle,
  }) {
    return LauncherCatalog.instance.variantStyleFor(
      variantId,
      defaultStyle: defaultStyle,
    );
  }

  /// Returns resolved [Color] values for [variantId].
  ///
  /// This converts optional hex strings from catalog style into ready-to-use
  /// Flutter colors and applies [defaultColors] as fallback.
  static LauncherVariantResolvedColors? styleColorsForVariant(
    String variantId, {
    LauncherVariantResolvedColors? defaultColors,
  }) {
    return LauncherCatalog.instance.variantResolvedColorsFor(
      variantId,
      defaultColors: defaultColors,
    );
  }

  /// Resolves style metadata for the currently active variant.
  ///
  /// If native side cannot report the active variant, the catalog primary id is
  /// used as fallback.
  static Future<LauncherVariantStyle?> currentStyle({
    LauncherVariantStyle? defaultStyle,
  }) async {
    final current = await getCurrentVariant();
    final fallbackId = LauncherCatalog.instance.primaryVariantId;
    final targetVariantId = current ?? fallbackId;
    if (targetVariantId.isEmpty) {
      return defaultStyle;
    }
    return styleForVariant(targetVariantId, defaultStyle: defaultStyle);
  }

  /// Resolves color values for the currently active variant.
  static Future<LauncherVariantResolvedColors?> currentStyleColors({
    LauncherVariantResolvedColors? defaultColors,
  }) async {
    final current = await getCurrentVariant();
    final fallbackId = LauncherCatalog.instance.primaryVariantId;
    final targetVariantId = current ?? fallbackId;
    if (targetVariantId.isEmpty) {
      return defaultColors;
    }
    return styleColorsForVariant(targetVariantId, defaultColors: defaultColors);
  }

  /// Registers launcher [variantIds] and [primaryVariantId] on native side.
  ///
  /// Must be called before invoking [getAvailableVariants], [getCurrentVariant],
  /// or [applyVariant].
  static Future<void> initialize({
    required List<String> variantIds,
    required String primaryVariantId,
  }) async {
    if (variantIds.isEmpty) {
      throw ArgumentError.value(variantIds, 'variantIds', 'must not be empty');
    }
    if (!variantIds.contains(primaryVariantId)) {
      throw ArgumentError.value(
        primaryVariantId,
        'primaryVariantId',
        'must be one of variantIds',
      );
    }
    await _channel.invokeMethod<void>('initialize', <String, dynamic>{
      'ids': variantIds,
      'primaryVariantId': primaryVariantId,
    });
  }

  /// Convenience: load [LauncherCatalog.instance] from the bundle, then [initialize].
  static Future<void> initializeFromCatalog({
    String catalogAssetPath = kDefaultLauncherCatalogAssetPath,
  }) async {
    await LauncherCatalog.instance.loadFromBundle(assetPath: catalogAssetPath);
    final cat = LauncherCatalog.instance;
    await initialize(
      variantIds: cat.allIds,
      primaryVariantId: cat.primaryVariantId,
    );
  }

  /// Returns variant ids recognized by native code.
  ///
  /// Falls back to [LauncherCatalog.instance] ids if the native call fails.
  static Future<List<String>> getAvailableVariants() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getAvailableVariants',
      );
      final list = result?.cast<String>();
      if (list != null && list.isNotEmpty) {
        return list;
      }
    } on PlatformException {
      return LauncherCatalog.instance.allIds;
    } on MissingPluginException {
      return LauncherCatalog.instance.allIds;
    }
    return LauncherCatalog.instance.allIds;
  }

  /// Returns current active launcher variant id reported by the OS.
  ///
  /// Returns `null` when native side cannot provide a value.
  static Future<String?> getCurrentVariant() async {
    try {
      return await _channel.invokeMethod<String>('getCurrentVariant');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Applies [variantId] as the active launcher icon.
  ///
  /// On Android this may restart/refresh launcher process behavior depending on
  /// the device launcher implementation. On iOS, system confirmation behavior is
  /// controlled by the platform.
  static Future<void> applyVariant(String variantId) async {
    await _channel.invokeMethod<void>('applyVariant', variantId);
  }

  /// Applies [variantId] then returns resolved style metadata for that variant.
  ///
  /// This is a convenience API for white-label flows where launcher variant and
  /// app styling are switched together from one action.
  static Future<LauncherVariantStyle?> applyVariantAndGetStyle(
    String variantId, {
    LauncherVariantStyle? defaultStyle,
  }) async {
    await applyVariant(variantId);
    return styleForVariant(variantId, defaultStyle: defaultStyle);
  }

  /// Applies [variantId] then returns resolved color values for that variant.
  static Future<LauncherVariantResolvedColors?> applyVariantAndGetStyleColors(
    String variantId, {
    LauncherVariantResolvedColors? defaultColors,
  }) async {
    await applyVariant(variantId);
    return styleColorsForVariant(variantId, defaultColors: defaultColors);
  }
}
