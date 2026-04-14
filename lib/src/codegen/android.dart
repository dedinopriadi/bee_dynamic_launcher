import 'dart:io';

import 'catalog.dart';

final RegExp _mainActivityBlockPattern = RegExp(
  r'<activity\b[^>]*android:name="\.MainActivity"[\s\S]*?</activity>',
  multiLine: true,
);
final RegExp _launcherIntentPattern = RegExp(
  r'<intent-filter>[\s\S]*?<action android:name="android.intent.action.MAIN"\s*/>[\s\S]*?<category android:name="android.intent.category.LAUNCHER"\s*/>[\s\S]*?</intent-filter>',
  multiLine: true,
);
final RegExp _enabledLauncherAliasPattern = RegExp(
  r'<activity-alias\b[\s\S]*?android:enabled="true"[\s\S]*?<intent-filter>[\s\S]*?<action android:name="android.intent.action.MAIN"\s*/>[\s\S]*?<category android:name="android.intent.category.LAUNCHER"\s*/>[\s\S]*?</intent-filter>[\s\S]*?</activity-alias>',
  multiLine: true,
);

void checkAndroidLauncherEntryPoints(Directory root) {
  final path = '${root.path}/android/app/src/main/AndroidManifest.xml';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exitCode = 1;
    return;
  }
  final text = file.readAsStringSync();
  final mainActivityBlockMatch = _mainActivityBlockPattern.firstMatch(text);
  final mainActivityHasLauncher = mainActivityBlockMatch != null &&
      _launcherIntentPattern.hasMatch(mainActivityBlockMatch.group(0)!);
  final enabledLauncherAliases =
      _enabledLauncherAliasPattern.allMatches(text).length;

  if (enabledLauncherAliases == 0) {
    stderr.writeln(
      'No enabled launcher activity-alias found in $path. '
      'Ensure exactly one generated alias is android:enabled="true".',
    );
    exitCode = 1;
    return;
  }
  if (enabledLauncherAliases > 1) {
    stderr.writeln(
      'Multiple enabled launcher activity-alias entries found in $path ($enabledLauncherAliases). '
      'Only one alias should be enabled at a time.',
    );
    exitCode = 1;
    return;
  }
  if (mainActivityHasLauncher) {
    stderr.writeln(
      'Duplicate launcher entry detected in $path. '
      'MainActivity has MAIN/LAUNCHER while a launcher activity-alias is enabled. '
      'Remove launcher intent-filter from MainActivity.',
    );
    exitCode = 1;
  }
}

String generateLauncherStringsXml(LauncherCatalogData catalog) {
  final buf = StringBuffer();
  buf.writeln('<?xml version="1.0" encoding="utf-8"?>');
  buf.writeln('<resources>');
  for (final v in catalog.variants) {
    final key = 'launcher_${v.id}'.replaceAll('-', '_');
    final escaped = v.launcherLabel
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
    buf.writeln('    <string name="$key">$escaped</string>');
  }
  buf.writeln('</resources>');
  return buf.toString();
}

String _activityAliasXml(String id, LauncherCatalogData catalog) {
  final classSuffix = pascalCaseForLauncher(id);
  final enabled = id == catalog.primaryVariantId ? 'true' : 'false';
  return '''
        <activity-alias
            android:name=".Launcher$classSuffix"
            android:targetActivity=".MainActivity"
            android:enabled="$enabled"
            android:exported="true"
            android:icon="@mipmap/ic_launcher_$id"
            android:label="@string/launcher_$id">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity-alias>''';
}

String generateActivityAliasesBlock(LauncherCatalogData catalog) {
  return catalog.ids.map((id) => _activityAliasXml(id, catalog)).join('\n\n');
}

String generateAdaptiveIconXml(String id) {
  return '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@android:color/white"/>
    <foreground android:drawable="@mipmap/ic_launcher_${id}_foreground"/>
</adaptive-icon>
''';
}

void writeAdaptiveIconXmlFiles(Directory root, LauncherCatalogData catalog) {
  final anydpiV26 = Directory(
    '${root.path}/android/app/src/main/res/mipmap-anydpi-v26',
  );
  if (!anydpiV26.existsSync()) {
    anydpiV26.createSync(recursive: true);
  }
  for (final id in catalog.ids) {
    final file = File('${anydpiV26.path}/ic_launcher_$id.xml');
    file.writeAsStringSync(generateAdaptiveIconXml(id));
  }
}

void patchAndroidManifest(Directory root, LauncherCatalogData catalog) {
  final path = '${root.path}/android/app/src/main/AndroidManifest.xml';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Missing $path');
    exitCode = 1;
    return;
  }
  var text = file.readAsStringSync();
  final primary = catalog.primaryVariantId;
  text = text.replaceFirstMapped(
    RegExp(r'android:label="@string/launcher_[^"]+"'),
    (_) => 'android:label="@string/launcher_$primary"',
  );
  text = text.replaceFirstMapped(
    RegExp(r'android:icon="@mipmap/ic_launcher_[^"]+"'),
    (_) => 'android:icon="@mipmap/ic_launcher_$primary"',
  );
  const begin = '<!-- LAUNCHER_ACTIVITY_ALIASES_BEGIN -->';
  const end = '<!-- LAUNCHER_ACTIVITY_ALIASES_END -->';
  if (!text.contains(begin) || !text.contains(end)) {
    stderr.writeln(
      'AndroidManifest.xml must contain $begin and $end markers.',
    );
    exitCode = 1;
    return;
  }
  final generated = generateActivityAliasesBlock(catalog);
  final pattern = RegExp(
    '$begin\\s*[\\s\\S]*?\\s*$end',
    multiLine: true,
  );
  text = text.replaceFirst(pattern, '$begin\n$generated\n        $end');
  file.writeAsStringSync(text);
}

void writeAndroidGeneratedFiles(Directory root, LauncherCatalogData catalog) {
  final stringsPath =
      '${root.path}/android/app/src/main/res/values/launcher_strings_generated.xml';
  File(stringsPath).writeAsStringSync(
    generateLauncherStringsXml(catalog),
  );
  patchAndroidManifest(root, catalog);
  writeAdaptiveIconXmlFiles(root, catalog);
}
