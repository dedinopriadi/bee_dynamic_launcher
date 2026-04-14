import 'dart:io';

import 'catalog.dart';

final RegExp _appIconNameSettingPattern = RegExp(
  r'^\s*ASSETCATALOG_COMPILER_APPICON_NAME = [^;]+;$',
  multiLine: true,
);
final RegExp _includeAllAppIconsSettingPattern = RegExp(
  r'^\s*ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;$',
  multiLine: true,
);

int _countAppIconNameSettings(String text) =>
    _appIconNameSettingPattern.allMatches(text).length;

int _countIncludeAllAppIconsSettings(String text) =>
    _includeAllAppIconsSettingPattern.allMatches(text).length;

String generateAlternateIconsPlistXml(LauncherCatalogData catalog) {
  final buf = StringBuffer();
  for (final v in catalog.variants) {
    if (v.id == catalog.primaryVariantId) {
      continue;
    }
    final name = iosAlternateAppIconName(v.id, catalog.primaryVariantId);
    buf.writeln('\t\t\t<key>$name</key>');
    buf.writeln('\t\t\t<dict>');
    buf.writeln('\t\t\t\t<key>CFBundleIconFiles</key>');
    buf.writeln('\t\t\t\t<array>');
    buf.writeln('\t\t\t\t\t<string>${name}60x60</string>');
    buf.writeln('\t\t\t\t</array>');
    buf.writeln('\t\t\t\t<key>UIPrerenderedIcon</key>');
    buf.writeln('\t\t\t\t<false/>');
    buf.writeln('\t\t\t</dict>');
  }
  return buf.toString().trimRight();
}

void patchInfoPlist(Directory root, LauncherCatalogData catalog) {
  final path = '${root.path}/ios/Runner/Info.plist';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exitCode = 1;
    return;
  }
  var text = file.readAsStringSync();
  const begin = '<!-- LAUNCHER_CFBundleAlternateIcons_BEGIN -->';
  const end = '<!-- LAUNCHER_CFBundleAlternateIcons_END -->';
  if (!text.contains(begin) || !text.contains(end)) {
    stderr.writeln('Info.plist must contain $begin and $end markers.');
    exitCode = 1;
    return;
  }
  final generated = generateAlternateIconsPlistXml(catalog);
  final pattern = RegExp(
    '$begin\\s*[\\s\\S]*?\\s*$end',
    multiLine: true,
  );
  text = text.replaceFirst(
    pattern,
    '$begin\n$generated\n\t\t$end',
  );
  file.writeAsStringSync(text);
}

void checkXcodeIncludeAllAppIconAssets(Directory root) {
  final path = '${root.path}/ios/Runner.xcodeproj/project.pbxproj';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exitCode = 1;
    return;
  }
  final text = file.readAsStringSync();
  final appIconLineCount = _countAppIconNameSettings(text);
  final includeAllCount = _countIncludeAllAppIconsSettings(text);
  if (appIconLineCount == 0) {
    stderr.writeln(
      'Could not find ASSETCATALOG_COMPILER_APPICON_NAME in $path. '
      'Set ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES manually for all Runner build configurations.',
    );
    exitCode = 1;
    return;
  }
  if (includeAllCount < appIconLineCount) {
    stderr.writeln(
      'Missing ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES in $path '
      '(found $includeAllCount of $appIconLineCount expected).',
    );
    exitCode = 1;
    return;
  }
}

void patchXcodeIncludeAllAppIconAssets(Directory root) {
  final path = '${root.path}/ios/Runner.xcodeproj/project.pbxproj';
  final file = File(path);
  if (!file.existsSync()) {
    return;
  }
  final original = file.readAsStringSync();
  final appIconLineCount = _countAppIconNameSettings(original);
  if (appIconLineCount == 0) {
    stderr.writeln(
      'Could not find ASSETCATALOG_COMPILER_APPICON_NAME in $path. '
      'Set ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES manually for all Runner build configurations.',
    );
    exitCode = 1;
    return;
  }
  final pattern = RegExp(
    r'^(\s*)ASSETCATALOG_COMPILER_APPICON_NAME = ([^;]+);\n(?:\1ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;\n)?',
    multiLine: true,
  );
  final updated = original.replaceAllMapped(
    pattern,
    (match) {
      final indent = match.group(1)!;
      final appIconValue = match.group(2)!;
      final line =
          '${indent}ASSETCATALOG_COMPILER_APPICON_NAME = $appIconValue;';
      final includeLine =
          '${indent}ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;';
      return '$line\n$includeLine\n';
    },
  );
  if (updated == original) {
    final includeAllCount = _countIncludeAllAppIconsSettings(original);
    if (includeAllCount < appIconLineCount) {
      stderr.writeln(
        'Missing ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES in $path. '
        'Ensure each Runner build configuration includes it.',
      );
      exitCode = 1;
    }
    return;
  }
  file.writeAsStringSync(updated);
  final verified = file.readAsStringSync();
  final includeAllCount = _countIncludeAllAppIconsSettings(verified);
  if (includeAllCount < appIconLineCount) {
    stderr.writeln(
      'Failed to enforce ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES in $path. '
      'Set it manually for all Runner build configurations.',
    );
    exitCode = 1;
  }
}

void writeIosGeneratedFiles(Directory root, LauncherCatalogData catalog) {
  patchInfoPlist(root, catalog);
  patchXcodeIncludeAllAppIconAssets(root);
}
