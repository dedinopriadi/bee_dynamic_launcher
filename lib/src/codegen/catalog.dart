import 'dart:convert';
import 'dart:io';

import 'cli_ui.dart';

const String kCatalogRelativePath = 'assets/bee_dynamic_launcher/catalog.json';

const String kIconsSubdir = 'assets/bee_dynamic_launcher/icons';

class LauncherVariantEntry {
  const LauncherVariantEntry({
    required this.id,
    required this.displayName,
    required this.launcherLabel,
  });

  final String id;
  final String displayName;
  final String launcherLabel;
}

class LauncherCatalogData {
  LauncherCatalogData({
    required this.primaryVariantId,
    required List<LauncherVariantEntry> variants,
  }) : variants = List<LauncherVariantEntry>.from(variants);

  String primaryVariantId;
  final List<LauncherVariantEntry> variants;

  List<String> get ids => variants.map((e) => e.id).toList();
}

String pascalCaseForLauncher(String id) {
  if (id.isEmpty) {
    return id;
  }
  final buf = StringBuffer();
  for (final segment in id.split('_')) {
    if (segment.isEmpty) {
      continue;
    }
    final first = segment[0];
    final rest = segment.length > 1 ? segment.substring(1) : '';
    buf.write(first.toUpperCase());
    buf.write(rest.toLowerCase());
  }
  return buf.toString();
}

String iosAlternateAppIconName(String id, String primaryId) {
  if (id == primaryId) {
    return 'AppIcon';
  }
  return 'AppIcon${pascalCaseForLauncher(id)}';
}

LauncherCatalogData parseLauncherCatalogJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is List) {
    final variants = decoded
        .map(
          (e) => LauncherVariantEntry(
            id: (e as Map<String, dynamic>)['id'] as String,
            displayName: e['displayName'] as String,
            launcherLabel: e['launcherLabel'] as String,
          ),
        )
        .toList();
    final primary = variants.isEmpty ? '' : variants.first.id;
    return LauncherCatalogData(primaryVariantId: primary, variants: variants);
  }
  final map = decoded as Map<String, dynamic>;
  final list = map['variants'] as List<dynamic>? ?? [];
  final variants = list
      .map(
        (e) => LauncherVariantEntry(
          id: (e as Map<String, dynamic>)['id'] as String,
          displayName: e['displayName'] as String,
          launcherLabel: e['launcherLabel'] as String,
        ),
      )
      .toList();
  final primary = map['primaryVariantId'] as String? ??
      (variants.isEmpty ? '' : variants.first.id);
  return LauncherCatalogData(primaryVariantId: primary, variants: variants);
}

void validateCatalogAgainstAssets(
  LauncherCatalogData catalog,
  Directory root, {
  required bool failOnExtraPng,
}) {
  final iconsDir = Directory('${root.path}/$kIconsSubdir');
  final expected = catalog.ids.toSet();
  final found = <String>{};
  if (iconsDir.existsSync()) {
    for (final entity in iconsDir.listSync()) {
      if (entity is! File) {
        continue;
      }
      final name = entity.uri.pathSegments.last;
      final m = RegExp(r'^ic_([a-z0-9_]+)\.png$').firstMatch(name);
      if (m != null) {
        found.add(m.group(1)!);
      }
    }
  }
  for (final id in expected) {
    final f = File('${root.path}/$kIconsSubdir/ic_$id.png');
    if (!f.existsSync()) {
      errLine('Missing asset: ${f.path}');
      exitCode = 1;
    }
  }
  for (final id in found.difference(expected)) {
    final msg = 'PNG ic_$id.png has no matching entry in $kCatalogRelativePath';
    if (failOnExtraPng) {
      errLine(msg);
      exitCode = 1;
    } else {
      warnLine(msg);
    }
  }
}

List<String> scanLauncherPngIds(Directory root) {
  final iconsDir = Directory('${root.path}/$kIconsSubdir');
  final ids = <String>[];
  if (!iconsDir.existsSync()) {
    return ids;
  }
  for (final entity in iconsDir.listSync()) {
    if (entity is! File) {
      continue;
    }
    final name = entity.uri.pathSegments.last;
    final m = RegExp(r'^ic_([a-z0-9_]+)\.png$').firstMatch(name);
    if (m != null) {
      ids.add(m.group(1)!);
    }
  }
  ids.sort();
  return ids;
}
