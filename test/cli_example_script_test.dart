import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

String _msg(ProcessResult r) => 'stdout:\n${r.stdout}\nstderr:\n${r.stderr}';

void main() {
  late Directory exampleDir;

  setUpAll(() {
    final pkgRoot = Directory.current;
    exampleDir = Directory(p.join(pkgRoot.path, 'example'));
    expect(
      exampleDir.existsSync(),
      isTrue,
      reason: 'Run tests from bee_dynamic_launcher package root',
    );
  });

  Future<ProcessResult> runCli(List<String> args) {
    return Process.run(
      'dart',
      ['run', 'bee_dynamic_launcher', ...args],
      workingDirectory: exampleDir.path,
      runInShell: true,
    );
  }

  test('--help prints usage and exits 0', () async {
    final r = await runCli(['--help']);
    expect(r.exitCode, 0, reason: _msg(r));
    expect(r.stdout.toString(), contains('--scan'));
  });

  test('-h prints usage and exits 0', () async {
    final r = await runCli(['-h']);
    expect(r.exitCode, 0, reason: _msg(r));
    expect(r.stdout.toString(), contains('bee_dynamic_launcher'));
  });

  test('--scan compares catalog variants to icons/ic_*.png', () async {
    final r = await runCli(['--scan']);
    expect(r.exitCode, 0, reason: _msg(r));
  });

  test('--scan --strict exits 0 when catalog and PNG ids match exactly',
      () async {
    final r = await runCli(['--scan', '--strict']);
    expect(r.exitCode, 0, reason: _msg(r));
  });

  test('--check-ios-pbxproj validates iOS build settings without file writes',
      () async {
    final pbxproj = File(
      p.join(exampleDir.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'),
    );
    final before = await pbxproj.readAsString();
    final r = await runCli(['--check-ios-pbxproj']);
    final after = await pbxproj.readAsString();
    expect(r.exitCode, 0, reason: _msg(r));
    expect(after, before,
        reason: 'check-only mode must not modify project.pbxproj');
  });

  test('--check-android-manifest validates launcher config without file writes',
      () async {
    final manifest = File(
      p.join(exampleDir.path, 'android', 'app', 'src', 'main',
          'AndroidManifest.xml'),
    );
    final before = await manifest.readAsString();
    final r = await runCli(['--check-android-manifest']);
    final after = await manifest.readAsString();
    expect(r.exitCode, 0, reason: _msg(r));
    expect(after, before,
        reason: 'check-only mode must not modify AndroidManifest.xml');
  });

  test('--native-only applies Android+iOS codegen without icon resize',
      () async {
    final r = await runCli(['--native-only']);
    expect(r.exitCode, 0, reason: _msg(r));
  });

  test('--icons-only runs mipmap + iOS AppIcon PNG pipeline', () async {
    final r = await runCli(['--icons-only']);
    expect(r.exitCode, 0, reason: _msg(r));
  }, timeout: Timeout(const Duration(minutes: 3)));

  test('default run validates, syncs native, and resizes icons', () async {
    final r = await runCli([]);
    expect(r.exitCode, 0, reason: _msg(r));
  }, timeout: Timeout(const Duration(minutes: 3)));

  test('--icons-only with --native-only exits 1', () async {
    final r = await runCli(['--icons-only', '--native-only']);
    expect(r.exitCode, 1, reason: _msg(r));
  });
}
