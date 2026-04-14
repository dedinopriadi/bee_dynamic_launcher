import 'dart:convert';
import 'dart:io';

import 'android.dart';
import 'catalog.dart';
import 'cli_ui.dart';
import 'icons.dart';
import 'ios_gen.dart';

Future<void> main(List<String> args) async {
  final root = Directory.current;
  final flags = args.toSet();
  if (flags.contains('-h') || flags.contains('--help')) {
    printHelpPretty();
    return;
  }
  final iconsOnly = flags.contains('--icons-only');
  final nativeOnly =
      flags.contains('--native-only') || flags.contains('--skip-icons');
  final scan = flags.contains('--scan');
  final wizard = flags.contains('--wizard');
  final strictScan = flags.contains('--strict');
  final checkIosPbxproj = flags.contains('--check-ios-pbxproj');
  final checkAndroidManifest = flags.contains('--check-android-manifest');

  if (scan) {
    runScan(root, strictScan);
    return;
  }

  if (checkIosPbxproj) {
    runIosPbxprojCheck(root);
    return;
  }

  if (checkAndroidManifest) {
    runAndroidManifestCheck(root);
    return;
  }

  if (wizard) {
    await runWizard(root);
    return;
  }

  if (iconsOnly && nativeOnly) {
    errLine('Use only one of --icons-only or --native-only.');
    exitCode = 1;
    return;
  }

  final jsonFile = File('${root.path}/$kCatalogRelativePath');
  if (!jsonFile.existsSync()) {
    errLine('Missing $kCatalogRelativePath');
    exitCode = 1;
    return;
  }

  banner();

  final catalog = parseLauncherCatalogJson(jsonFile.readAsStringSync());
  section('📋', 'Validating catalog & assets');
  validateCatalogAgainstAssets(
    catalog,
    root,
    failOnExtraPng: strictScan || nativeOnly || !iconsOnly,
  );

  if (exitCode != 0) {
    footerFailure('Validation failed — fix assets or catalog.');
    return;
  }
  stepOk('Catalog and assets are in sync');

  if (!iconsOnly) {
    section('🤖', 'Android · codegen');
    stepInfo('launcher_strings_generated.xml · AndroidManifest (aliases)');
    writeAndroidGeneratedFiles(root, catalog);
    stepOk('Android generated files applied');

    section('🍎', 'iOS · codegen');
    stepInfo('Info.plist (alternate icons)');
    writeIosGeneratedFiles(root, catalog);
    stepOk('iOS generated files applied');
  }

  if (!nativeOnly) {
    await runIconGeneration(root, catalog);
  }

  if (exitCode == 0) {
    if (iconsOnly) {
      footerSuccess('icons only');
    } else if (nativeOnly) {
      footerSuccess('native only');
    } else {
      footerSuccess('icons + native');
    }
  } else {
    footerFailure('Finished with errors — fix the issues above and re-run.');
  }
}

void runIosPbxprojCheck(Directory root) {
  banner();
  section('🍎', 'iOS · check-only project.pbxproj');
  stepInfo('Validating include-all AppIcon build setting');
  checkXcodeIncludeAllAppIconAssets(root);
  if (exitCode == 0) {
    stepOk('Runner iOS build settings are valid for alternate app icons');
    stdout.writeln('');
  } else {
    footerFailure('iOS project.pbxproj validation failed.');
  }
}

void runAndroidManifestCheck(Directory root) {
  banner();
  section('🤖', 'Android · check-only AndroidManifest.xml');
  stepInfo('Validating launcher entry points');
  checkAndroidLauncherEntryPoints(root);
  if (exitCode == 0) {
    stepOk('Runner Android launcher entry points are valid');
    stdout.writeln('');
  } else {
    footerFailure('AndroidManifest launcher validation failed.');
  }
}

void runScan(Directory root, bool strict) {
  banner();
  final jsonFile = File('${root.path}/$kCatalogRelativePath');
  if (!jsonFile.existsSync()) {
    errLine('Missing $kCatalogRelativePath');
    exitCode = 1;
    return;
  }
  final catalog = parseLauncherCatalogJson(jsonFile.readAsStringSync());
  final fromPng = scanLauncherPngIds(root).toSet();
  final fromJson = catalog.ids.toSet();
  section('🔍', 'Scan · JSON vs PNG');
  stdout.writeln(
      '  ${dim('Variants in JSON')} ${bold('(${fromJson.length})')}  ${cyan(catalog.ids.join(', '))}');
  final sortedPng = fromPng.toList()..sort();
  stdout.writeln(
    '  ${dim('PNG ic_*.png')} ${bold('(${fromPng.length})')}  ${cyan(sortedPng.join(', '))}',
  );
  final onlyPng = fromPng.difference(fromJson);
  final onlyJson = fromJson.difference(fromPng);
  if (onlyPng.isNotEmpty) {
    final msg = 'PNG without JSON: ${onlyPng.join(', ')}';
    if (strict) {
      errLine(msg);
      exitCode = 1;
    } else {
      warnLine(msg);
    }
  }
  if (onlyJson.isNotEmpty) {
    final msg = 'JSON without PNG: ${onlyJson.join(', ')}';
    if (strict) {
      errLine(msg);
      exitCode = 1;
    } else {
      warnLine(msg);
    }
  }
  if (onlyPng.isEmpty && onlyJson.isEmpty) {
    stepOk('JSON and PNG sets match');
  }
  stdout.writeln('');
}

Future<void> runWizard(Directory root) async {
  final jsonFile = File('${root.path}/$kCatalogRelativePath');
  if (!jsonFile.existsSync()) {
    errLine('Missing $kCatalogRelativePath');
    exitCode = 1;
    return;
  }
  banner();
  section('🧙', 'Wizard · add variants');
  stdout.writeln(dim('  (empty id to finish and save)'));
  stdout.writeln('');
  final catalog = parseLauncherCatalogJson(jsonFile.readAsStringSync());
  final existing = catalog.ids.toSet();
  while (true) {
    stdout.write('${cyan('  ▸')} Variant id: ');
    final id = stdin.readLineSync()?.trim() ?? '';
    if (id.isEmpty) {
      break;
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
      warnLine('Invalid id — use snake_case (a-z, 0-9, _).');
      continue;
    }
    if (existing.contains(id)) {
      warnLine('That id already exists.');
      continue;
    }
    stdout.write('${cyan('  ▸')} Display name: ');
    final displayName = stdin.readLineSync()?.trim() ?? id;
    stdout.write('${cyan('  ▸')} Launcher label [Enter = same as display]: ');
    var launcherLabel = stdin.readLineSync()?.trim() ?? '';
    if (launcherLabel.isEmpty) {
      launcherLabel = displayName;
    }
    catalog.variants.add(
      LauncherVariantEntry(
        id: id,
        displayName: displayName,
        launcherLabel: launcherLabel,
      ),
    );
    existing.add(id);
    stepOk(
      'Added "$id" — drop $kIconsSubdir/ic_$id.png then run codegen.',
    );
    stdout.writeln('');
  }
  final map = {
    'primaryVariantId': catalog.primaryVariantId,
    'variants': catalog.variants
        .map(
          (v) => {
            'id': v.id,
            'displayName': v.displayName,
            'launcherLabel': v.launcherLabel,
          },
        )
        .toList(),
  };
  jsonFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(map));
  stepOk('Saved ${jsonFile.path}');
  footerSuccess('wizard');
}
