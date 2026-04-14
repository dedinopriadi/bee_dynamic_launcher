import 'dart:convert';

import 'package:flutter/services.dart';

/// Default path to the launcher catalog JSON when using [LauncherCatalog.loadFromBundle].
const String kDefaultLauncherCatalogAssetPath =
    'assets/bee_dynamic_launcher/catalog.json';

/// Relative path under `assets/` for a variant preview icon: `icons/ic_<id>.png`.
String launcherIconPreviewAssetPath(String variantId) =>
    'assets/bee_dynamic_launcher/icons/ic_$variantId.png';

class LauncherVariantEntry {
  /// Immutable launcher variant entry from the catalog.
  const LauncherVariantEntry({
    required this.id,
    required this.displayName,
    required this.launcherLabel,
  });

  final String id;
  final String displayName;
  final String launcherLabel;

  String get previewIconAssetPath => launcherIconPreviewAssetPath(id);
}

class LauncherCatalog {
  LauncherCatalog._();

  /// Shared singleton for reading launcher variant data from catalog JSON.
  static final LauncherCatalog instance = LauncherCatalog._();

  List<LauncherVariantEntry> _variants = const [];
  String _primaryVariantId = '';

  /// Read-only list of launcher variants currently loaded.
  List<LauncherVariantEntry> get variants => List.unmodifiable(_variants);

  /// Id of the primary/default launcher variant.
  String get primaryVariantId => _primaryVariantId;

  /// All variant ids in catalog order.
  List<String> get allIds => _variants.map((e) => e.id).toList();

  /// Whether at least one variant is loaded.
  bool get hasVariants => _variants.isNotEmpty;

  /// Number of variants loaded from catalog.
  int get variantCount => _variants.length;

  /// Preview icon paths for all loaded variants.
  List<String> get allPreviewIconAssetPaths =>
      _variants.map((e) => e.previewIconAssetPath).toList();

  bool containsVariant(String variantId) {
    for (final v in _variants) {
      if (v.id == variantId) {
        return true;
      }
    }
    return false;
  }

  LauncherVariantEntry? variantEntryFor(String variantId) {
    for (final v in _variants) {
      if (v.id == variantId) {
        return v;
      }
    }
    return null;
  }

  String launcherLabelFor(String variantId) {
    final e = variantEntryFor(variantId);
    return e?.launcherLabel ?? variantId;
  }

  /// Loads and parses catalog JSON from Flutter asset bundle.
  Future<void> loadFromBundle({
    String assetPath = kDefaultLauncherCatalogAssetPath,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    _applyJson(raw);
  }

  void applyJsonString(String raw) => _applyJson(raw);

  void _applyJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      _variants = decoded
          .map(
            (e) => LauncherVariantEntry(
              id: (e as Map<String, dynamic>)['id'] as String,
              displayName: e['displayName'] as String,
              launcherLabel: e['launcherLabel'] as String,
            ),
          )
          .toList();
      _primaryVariantId = _variants.isEmpty ? '' : _variants.first.id;
      return;
    }
    final map = decoded as Map<String, dynamic>;
    final list = map['variants'] as List<dynamic>? ?? [];
    _primaryVariantId = map['primaryVariantId'] as String? ??
        (list.isEmpty
            ? ''
            : (list.first as Map<String, dynamic>)['id'] as String);
    _variants = list
        .map(
          (e) => LauncherVariantEntry(
            id: (e as Map<String, dynamic>)['id'] as String,
            displayName: e['displayName'] as String,
            launcherLabel: e['launcherLabel'] as String,
          ),
        )
        .toList();
  }

  String displayNameFor(String variantId) {
    for (final v in _variants) {
      if (v.id == variantId) {
        return v.displayName;
      }
    }
    return variantId;
  }
}
