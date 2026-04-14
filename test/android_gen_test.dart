import 'dart:io';

import 'package:bee_dynamic_launcher/src/codegen/android.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    exitCode = 0;
  });

  Future<Directory> tempProjectWithManifest(String manifest) async {
    final root =
        await Directory.systemTemp.createTemp('bee_dynamic_launcher_android_');
    final file = File('${root.path}/android/app/src/main/AndroidManifest.xml');
    await file.create(recursive: true);
    await file.writeAsString(manifest);
    return root;
  }

  test(
      'checkAndroidLauncherEntryPoints passes with one enabled alias and no MainActivity launcher',
      () async {
    final root = await tempProjectWithManifest('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <activity android:name=".MainActivity" android:exported="true"></activity>
    <activity-alias android:name=".LauncherOrionB" android:enabled="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity-alias>
  </application>
</manifest>
''');
    addTearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    checkAndroidLauncherEntryPoints(root);
    expect(exitCode, 0);
  });

  test(
      'checkAndroidLauncherEntryPoints fails on duplicate MainActivity launcher and alias',
      () async {
    final root = await tempProjectWithManifest('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <activity android:name=".MainActivity" android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
    <activity-alias android:name=".LauncherOrionB" android:enabled="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity-alias>
  </application>
</manifest>
''');
    addTearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    checkAndroidLauncherEntryPoints(root);
    expect(exitCode, 1);
  });

  test('generateAdaptiveIconXml references variant-specific foreground', () {
    final xml = generateAdaptiveIconXml('bee_automation');
    expect(xml, contains('<adaptive-icon'));
    expect(xml, contains('@mipmap/ic_launcher_bee_automation_foreground'));
    expect(xml, contains('@android:color/white'));
  });
}
