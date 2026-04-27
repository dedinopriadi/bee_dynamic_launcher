import 'dart:convert';

import 'package:flutter/services.dart';

/// Default path to the launcher catalog JSON when using [LauncherCatalog.loadFromBundle].
const String kDefaultLauncherCatalogAssetPath =
    'assets/bee_dynamic_launcher/catalog.json';

/// Relative path under `assets/` for a variant preview icon: `icons/ic_<id>.png`.
String launcherIconPreviewAssetPath(String variantId) =>
    'assets/bee_dynamic_launcher/icons/ic_$variantId.png';

/// Optional branding style metadata for each launcher variant.
///
/// Values are plain strings (for example hex color tokens) so host apps can map
/// them into any design system they use.
class LauncherVariantStyle {
  const LauncherVariantStyle({
    this.baseColor,
    this.secondaryColor,
    this.backgroundColor,
    this.surfaceColor,
  });

  final String? baseColor;
  final String? secondaryColor;
  final String? backgroundColor;
  final String? surfaceColor;

  bool get isEmpty =>
      baseColor == null &&
      secondaryColor == null &&
      backgroundColor == null &&
      surfaceColor == null;

  LauncherVariantStyle resolvedWith(LauncherVariantStyle? fallback) {
    return LauncherVariantStyle(
      baseColor: baseColor ?? fallback?.baseColor,
      secondaryColor: secondaryColor ?? fallback?.secondaryColor,
      backgroundColor: backgroundColor ?? fallback?.backgroundColor,
      surfaceColor: surfaceColor ?? fallback?.surfaceColor,
    );
  }

  LauncherVariantResolvedColors? toResolvedColors({
    LauncherVariantResolvedColors? fallback,
  }) {
    final resolved = LauncherVariantResolvedColors(
      baseColor: _parseHexColor(baseColor) ?? fallback?.baseColor,
      secondaryColor: _parseHexColor(secondaryColor) ?? fallback?.secondaryColor,
      backgroundColor:
          _parseHexColor(backgroundColor) ?? fallback?.backgroundColor,
      surfaceColor: _parseHexColor(surfaceColor) ?? fallback?.surfaceColor,
    );
    return resolved.isEmpty ? null : resolved;
  }

  static Color? _parseHexColor(String? input) {
    if (input == null) {
      return null;
    }
    final raw = input.trim().replaceFirst('#', '');
    if (raw.length != 6 && raw.length != 8) {
      return null;
    }
    final value = int.tryParse(raw, radix: 16);
    if (value == null) {
      return null;
    }
    if (raw.length == 6) {
      return Color(0xFF000000 | value);
    }
    return Color(value);
  }
}

/// Resolved color values derived from [LauncherVariantStyle].
class LauncherVariantResolvedColors {
  const LauncherVariantResolvedColors({
    this.baseColor,
    this.secondaryColor,
    this.backgroundColor,
    this.surfaceColor,
  });

  final Color? baseColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final Color? surfaceColor;

  bool get isEmpty =>
      baseColor == null &&
      secondaryColor == null &&
      backgroundColor == null &&
      surfaceColor == null;
}

class LauncherVariantEntry {
  /// Immutable launcher variant entry from the catalog.
  const LauncherVariantEntry({
    required this.id,
    required this.displayName,
    required this.launcherLabel,
    this.style,
  });

  final String id;
  final String displayName;
  final String launcherLabel;
  final LauncherVariantStyle? style;

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

  LauncherVariantStyle? variantStyleFor(
    String variantId, {
    LauncherVariantStyle? defaultStyle,
  }) {
    final style = variantEntryFor(variantId)?.style;
    if (style == null) {
      return defaultStyle;
    }
    final resolved = style.resolvedWith(defaultStyle);
    return resolved.isEmpty ? null : resolved;
  }

  LauncherVariantResolvedColors? variantResolvedColorsFor(
    String variantId, {
    LauncherVariantResolvedColors? defaultColors,
  }) {
    final style = variantStyleFor(variantId);
    if (style == null) {
      return defaultColors;
    }
    return style.toResolvedColors(fallback: defaultColors);
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
              style: _parseStyle(e['style']),
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
            style: _parseStyle(e['style']),
          ),
        )
        .toList();
  }

  LauncherVariantStyle? _parseStyle(dynamic raw) {
    if (raw == null || raw is! Map) {
      return null;
    }
    final baseColor = raw['baseColor'] as String?;
    final secondaryColor = raw['secondaryColor'] as String?;
    final backgroundColor = raw['backgroundColor'] as String?;
    final surfaceColor = raw['surfaceColor'] as String?;
    final style = LauncherVariantStyle(
      baseColor: baseColor,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
    );
    return style.isEmpty ? null : style;
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
