import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/services.dart';
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

  test('LauncherCatalog keeps compatibility with legacy list JSON', () {
    const raw = '''
[
  { "id": "legacy_a", "displayName": "Legacy A", "launcherLabel": "Legacy App" },
  { "id": "legacy_b", "displayName": "Legacy B", "launcherLabel": "Legacy App B" }
]''';
    LauncherCatalog.instance.applyJsonString(raw);
    expect(LauncherCatalog.instance.primaryVariantId, 'legacy_a');
    expect(LauncherCatalog.instance.allIds, ['legacy_a', 'legacy_b']);
    expect(
      LauncherCatalog.instance.variantStyleFor('legacy_a'),
      isNull,
    );
  });

  test('LauncherCatalog parses optional variant style metadata', () {
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": {
        "baseColor": "#111111",
        "secondaryColor": "#222222",
        "backgroundColor": "#F5F5F5",
        "surfaceColor": "#FFFFFF"
      }
    },
    { "id": "b", "displayName": "B", "launcherLabel": "Label B" }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    final styleA = LauncherCatalog.instance.variantEntryFor('a')?.style;
    expect(styleA, isNotNull);
    expect(styleA?.baseColor, '#111111');
    expect(styleA?.secondaryColor, '#222222');
    expect(styleA?.backgroundColor, '#F5F5F5');
    expect(styleA?.surfaceColor, '#FFFFFF');
    expect(LauncherCatalog.instance.variantEntryFor('b')?.style, isNull);
  });

  test('variantStyleFor resolves fallback values when style is partial', () {
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": { "baseColor": "#111111" }
    },
    { "id": "b", "displayName": "B", "launcherLabel": "Label B" }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantStyle(
      baseColor: '#AAAAAA',
      secondaryColor: '#BBBBBB',
      backgroundColor: '#CCCCCC',
      surfaceColor: '#DDDDDD',
    );

    final resolvedA = LauncherCatalog.instance.variantStyleFor(
      'a',
      defaultStyle: defaults,
    );
    expect(resolvedA, isNotNull);
    expect(resolvedA?.baseColor, '#111111');
    expect(resolvedA?.secondaryColor, '#BBBBBB');
    expect(resolvedA?.backgroundColor, '#CCCCCC');
    expect(resolvedA?.surfaceColor, '#DDDDDD');

    final resolvedB = LauncherCatalog.instance.variantStyleFor(
      'b',
      defaultStyle: defaults,
    );
    expect(resolvedB, isNotNull);
    expect(resolvedB?.baseColor, '#AAAAAA');
    expect(resolvedB?.secondaryColor, '#BBBBBB');
    expect(resolvedB?.backgroundColor, '#CCCCCC');
    expect(resolvedB?.surfaceColor, '#DDDDDD');
  });

  test('BeeDynamicLauncher style helper resolves from catalog', () {
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": { "baseColor": "#111111" }
    }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantStyle(
      baseColor: '#AAAAAA',
      secondaryColor: '#BBBBBB',
    );
    final resolved = BeeDynamicLauncher.styleForVariant(
      'a',
      defaultStyle: defaults,
    );
    expect(resolved?.baseColor, '#111111');
    expect(resolved?.secondaryColor, '#BBBBBB');
  });

  test('styleColorsForVariant resolves parsed colors and fallback', () {
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": { "baseColor": "#111111" }
    }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantResolvedColors(
      baseColor: Color(0xFFAAAAAA),
      secondaryColor: Color(0xFFBBBBBB),
      backgroundColor: Color(0xFFCCCCCC),
      surfaceColor: Color(0xFFDDDDDD),
    );
    final resolved = BeeDynamicLauncher.styleColorsForVariant(
      'a',
      defaultColors: defaults,
    );
    expect(resolved?.baseColor, const Color(0xFF111111));
    expect(resolved?.secondaryColor, const Color(0xFFBBBBBB));
    expect(resolved?.backgroundColor, const Color(0xFFCCCCCC));
    expect(resolved?.surfaceColor, const Color(0xFFDDDDDD));
  });

  test('applyVariantAndGetStyle returns resolved style for applied variant', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": { "baseColor": "#111111" }
    }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantStyle(
      baseColor: '#AAAAAA',
      secondaryColor: '#BBBBBB',
    );
    const channel = MethodChannel(beeDynamicLauncherMethodChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'applyVariant') {
            return null;
          }
          throw MissingPluginException();
        });

    final resolved = await BeeDynamicLauncher.applyVariantAndGetStyle(
      'a',
      defaultStyle: defaults,
    );
    expect(resolved?.baseColor, '#111111');
    expect(resolved?.secondaryColor, '#BBBBBB');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('applyVariantAndGetStyleColors returns resolved colors', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    {
      "id": "a",
      "displayName": "A",
      "launcherLabel": "Label A",
      "style": { "baseColor": "#111111" }
    }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantResolvedColors(
      baseColor: Color(0xFFAAAAAA),
      secondaryColor: Color(0xFFBBBBBB),
    );
    const channel = MethodChannel(beeDynamicLauncherMethodChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'applyVariant') {
            return null;
          }
          throw MissingPluginException();
        });
    final resolved = await BeeDynamicLauncher.applyVariantAndGetStyleColors(
      'a',
      defaultColors: defaults,
    );
    expect(resolved?.baseColor, const Color(0xFF111111));
    expect(resolved?.secondaryColor, const Color(0xFFBBBBBB));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('applyVariantAndGetStyle falls back to default when style missing', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const raw = '''
{
  "primaryVariantId": "b",
  "variants": [
    { "id": "b", "displayName": "B", "launcherLabel": "Label B" }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const defaults = LauncherVariantStyle(
      baseColor: '#AAAAAA',
      secondaryColor: '#BBBBBB',
      backgroundColor: '#CCCCCC',
      surfaceColor: '#DDDDDD',
    );
    const channel = MethodChannel(beeDynamicLauncherMethodChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'applyVariant') {
            return null;
          }
          throw MissingPluginException();
        });

    final resolved = await BeeDynamicLauncher.applyVariantAndGetStyle(
      'b',
      defaultStyle: defaults,
    );
    expect(resolved?.baseColor, '#AAAAAA');
    expect(resolved?.secondaryColor, '#BBBBBB');
    expect(resolved?.backgroundColor, '#CCCCCC');
    expect(resolved?.surfaceColor, '#DDDDDD');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('applyVariantAndGetStyle propagates applyVariant failure', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const raw = '''
{
  "primaryVariantId": "a",
  "variants": [
    { "id": "a", "displayName": "A", "launcherLabel": "Label A" }
  ]
}''';
    LauncherCatalog.instance.applyJsonString(raw);
    const channel = MethodChannel(beeDynamicLauncherMethodChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'applyVariant') {
            throw PlatformException(code: 'APPLY_FAILED', message: 'boom');
          }
          throw MissingPluginException();
        });

    expect(
      () => BeeDynamicLauncher.applyVariantAndGetStyle('a'),
      throwsA(isA<PlatformException>()),
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('launcherIconPreviewAssetPath', () {
    expect(
      launcherIconPreviewAssetPath('foo_bar'),
      'assets/bee_dynamic_launcher/icons/ic_foo_bar.png',
    );
  });
}
