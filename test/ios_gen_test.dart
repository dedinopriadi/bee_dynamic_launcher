import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bee_dynamic_launcher/src/codegen/catalog.dart';
import 'package:bee_dynamic_launcher/src/codegen/ios_gen.dart';

void main() {
  setUp(() {
    exitCode = 0;
  });

  test(
      'generateAlternateIconsPlistXml includes CFBundleIconFiles basename per alternate',
      () {
    final catalog = LauncherCatalogData(
      primaryVariantId: 'orion_b',
      variants: [
        const LauncherVariantEntry(
          id: 'bee_short',
          displayName: 'Bee Short',
          launcherLabel: 'Bee Short',
        ),
        const LauncherVariantEntry(
          id: 'orion_b',
          displayName: 'Orion B',
          launcherLabel: 'Orion B',
        ),
      ],
    );
    final xml = generateAlternateIconsPlistXml(catalog);
    expect(xml, contains('<key>AppIconBeeShort</key>'));
    expect(xml, contains('<key>CFBundleIconFiles</key>'));
    expect(xml, contains('<string>AppIconBeeShort60x60</string>'));
    expect(xml, isNot(contains('<key>CFBundleIconName</key>')));
    expect(xml, isNot(contains('AppIconOrionB')));
  });

  test(
      'patchXcodeIncludeAllAppIconAssets writes include-all setting once per config',
      () async {
    final root =
        await Directory.systemTemp.createTemp('bee_dynamic_launcher_test_');
    addTearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    final pbxproj = File(
      '${root.path}/ios/Runner.xcodeproj/project.pbxproj',
    );
    await pbxproj.create(recursive: true);
    await pbxproj.writeAsString('''
Debug = {
  buildSettings = {
    ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
  };
};
Release = {
  buildSettings = {
    ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
  };
};
''');

    patchXcodeIncludeAllAppIconAssets(root);
    patchXcodeIncludeAllAppIconAssets(root);

    final updated = await pbxproj.readAsString();
    final includeCount = RegExp(
      r'^\s*ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;$',
      multiLine: true,
    ).allMatches(updated).length;
    expect(includeCount, 2);
  });

  test('checkXcodeIncludeAllAppIconAssets passes when all configs are valid',
      () async {
    final root =
        await Directory.systemTemp.createTemp('bee_dynamic_launcher_test_');
    addTearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    final pbxproj = File('${root.path}/ios/Runner.xcodeproj/project.pbxproj');
    await pbxproj.create(recursive: true);
    await pbxproj.writeAsString('''
Debug = {
  buildSettings = {
    ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
    ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
  };
};
Release = {
  buildSettings = {
    ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
    ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
  };
};
''');

    checkXcodeIncludeAllAppIconAssets(root);
    expect(exitCode, 0);
  });

  test(
      'checkXcodeIncludeAllAppIconAssets fails when include-all setting missing',
      () async {
    final root =
        await Directory.systemTemp.createTemp('bee_dynamic_launcher_test_');
    addTearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    final pbxproj = File('${root.path}/ios/Runner.xcodeproj/project.pbxproj');
    await pbxproj.create(recursive: true);
    await pbxproj.writeAsString('''
Debug = {
  buildSettings = {
    ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
  };
};
''');

    checkXcodeIncludeAllAppIconAssets(root);
    expect(exitCode, 1);
  });
}
