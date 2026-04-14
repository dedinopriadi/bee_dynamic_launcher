import 'package:flutter_test/flutter_test.dart';
import 'package:bee_dynamic_launcher/src/codegen/catalog.dart';

void main() {
  group('pascalCaseForLauncher', () {
    test('empty', () {
      expect(pascalCaseForLauncher(''), '');
    });
    test('single segment', () {
      expect(pascalCaseForLauncher('gizbee'), 'Gizbee');
    });
    test('snake_case to PascalCase without underscores', () {
      expect(pascalCaseForLauncher('orion_b'), 'OrionB');
      expect(pascalCaseForLauncher('bee_short'), 'BeeShort');
      expect(pascalCaseForLauncher('bee_automation'), 'BeeAutomation');
    });
  });
}
