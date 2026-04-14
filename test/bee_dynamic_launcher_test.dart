import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LauncherCatalog parses map-shaped JSON', () {
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    { "id": "a", "displayName": "A", "launcherLabel": "Label A" },
    { "id": "b", "displayName": "B", "launcherLabel": "Label B" }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    expect(LauncherCatalog.instance.primaryVariantId, 'a');
    expect(LauncherCatalog.instance.allIds, ['a', 'b']);
    expect(LauncherCatalog.instance.displayNameFor('b'), 'B');
    expect(LauncherCatalog.instance.hasVariants, isTrue);
    expect(LauncherCatalog.instance.variantCount, 2);
    expect(LauncherCatalog.instance.allPreviewIconAssetPaths, [
      'assets/bee_dynamic_launcher/icons/ic_a.png',
      'assets/bee_dynamic_launcher/icons/ic_b.png',
    ]);
    expect(LauncherCatalog.instance.containsVariant('a'), isTrue);
    expect(LauncherCatalog.instance.containsVariant('z'), isFalse);
    expect(LauncherCatalog.instance.variantEntryFor('b')?.displayName, 'B');
    expect(LauncherCatalog.instance.launcherLabelFor('a'), 'Label A');
  });

  test('launcherIconPreviewAssetPath', () {
    expect(
      launcherIconPreviewAssetPath('foo_bar'),
      'assets/bee_dynamic_launcher/icons/ic_foo_bar.png',
    );
  });
}
