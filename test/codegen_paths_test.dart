import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _findBeeDynamicLauncherPackageRoot() {
  var dir = Directory.current;
  while (true) {
    final pub = File('${dir.path}/pubspec.yaml');
    if (pub.existsSync()) {
      final text = pub.readAsStringSync();
      if (RegExp(
        r'^name:\s+bee_dynamic_launcher\s*$',
        multiLine: true,
      ).hasMatch(text)) {
        return dir;
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  throw StateError(
    'Run tests from bee_dynamic_launcher package tree (pubspec not found).',
  );
}

void main() {
  test('CLI template bundle is present for iOS alternate icon scaffold', () {
    final root = _findBeeDynamicLauncherPackageRoot();
    final template = File(
      '${root.path}/templates/AppIconAlternate.appiconset/Contents.json',
    );
    expect(template.existsSync(), isTrue, reason: template.path);
  });
}
