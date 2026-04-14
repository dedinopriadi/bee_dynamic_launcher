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

  static String previewIconAssetPath(String variantId) =>
      launcherIconPreviewAssetPath(variantId);

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

  static Future<String?> getCurrentVariant() async {
    try {
      return await _channel.invokeMethod<String>('getCurrentVariant');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> applyVariant(String variantId) async {
    await _channel.invokeMethod<void>('applyVariant', variantId);
  }

}
