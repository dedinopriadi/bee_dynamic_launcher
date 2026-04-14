import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;

import 'catalog.dart';
import 'cli_ui.dart';
import 'paths.dart';

const _androidMipmapSizes = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const _androidAdaptiveForegroundSizes = <String, int>{
  'mipmap-mdpi': 108,
  'mipmap-hdpi': 162,
  'mipmap-xhdpi': 216,
  'mipmap-xxhdpi': 324,
  'mipmap-xxxhdpi': 432,
};
const double _androidAdaptiveForegroundContentScale = 2 / 3;

Future<void> generateAndroidMipmaps({
  required Directory root,
  required LauncherCatalogData catalog,
}) async {
  final ids = catalog.ids;
  final total = ids.length;
  var hadError = false;
  for (var i = 0; i < total; i++) {
    final id = ids[i];
    progressVariant(i + 1, total, 'Android mipmaps', id);
    final src = File('${root.path}/$kIconsSubdir/ic_$id.png');
    final bytes = await src.readAsBytes();
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      clearLine();
      errLine('Could not decode PNG: ${src.path}');
      exitCode = 1;
      hadError = true;
      continue;
    }
    for (final e in _androidMipmapSizes.entries) {
      final folder = e.key;
      final px = e.value;
      final dir = Directory('${root.path}/android/app/src/main/res/$folder');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final out = File('${dir.path}/ic_launcher_$id.png');
      final resized = img.copyResize(
        decoded,
        width: px,
        height: px,
        interpolation: img.Interpolation.cubic,
      );
      await out.writeAsBytes(img.encodePng(resized));
    }
    for (final e in _androidAdaptiveForegroundSizes.entries) {
      final folder = e.key;
      final px = e.value;
      final dir = Directory('${root.path}/android/app/src/main/res/$folder');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final out = File('${dir.path}/ic_launcher_${id}_foreground.png');
      final contentPx = (px * _androidAdaptiveForegroundContentScale).round();
      final resized = img.copyResize(
        decoded,
        width: contentPx,
        height: contentPx,
        interpolation: img.Interpolation.cubic,
      );
      final canvas = img.Image(width: px, height: px, numChannels: 4);
      img.compositeImage(
        canvas,
        resized,
        dstX: ((px - contentPx) / 2).round(),
        dstY: ((px - contentPx) / 2).round(),
      );
      await out.writeAsBytes(img.encodePng(canvas));
    }
  }
  clearLine();
  if (hadError) {
    warnLine(
      'Android mipmaps incomplete — some PNGs failed to decode.',
    );
  } else {
    progressDone(
      'Android mipmaps/adaptive foregrounds · $total variants × ${_androidMipmapSizes.length} densities',
    );
  }
}

Future<void> ensureIosAlternateAppIconSets({
  required Directory root,
  required LauncherCatalogData catalog,
}) async {
  final pkgRoot = await packageRootDirectory();
  final templateFile = File(
    '${pkgRoot.path}/templates/AppIconAlternate.appiconset/Contents.json',
  );
  if (!templateFile.existsSync()) {
    errLine('Missing template: ${templateFile.path}');
    exitCode = 1;
    return;
  }
  final templateContents = templateFile.readAsStringSync();
  final assetsRoot = Directory('${root.path}/ios/Runner/Assets.xcassets');
  if (!assetsRoot.existsSync()) {
    errLine('Missing ${assetsRoot.path}');
    exitCode = 1;
    return;
  }
  for (final id in catalog.ids) {
    final setName = iosAlternateAppIconName(id, catalog.primaryVariantId);
    if (setName == 'AppIcon') {
      final primaryDir = Directory('${assetsRoot.path}/AppIcon.appiconset');
      if (!primaryDir.existsSync()) {
        errLine('Missing primary icon set (required): ${primaryDir.path}');
        exitCode = 1;
      }
      continue;
    }
    final appiconsetDir = Directory('${assetsRoot.path}/$setName.appiconset');
    if (appiconsetDir.existsSync()) {
      continue;
    }
    stepInfo('Scaffolding iOS $setName.appiconset (new alternate)');
    appiconsetDir.createSync(recursive: true);
    File('${appiconsetDir.path}/Contents.json').writeAsStringSync(
      templateContents,
    );
  }
}

int _pixelsFromContentsEntry(Map<String, dynamic> entry) {
  final sizeStr = entry['size'] as String;
  final scaleStr = entry['scale'] as String;
  final parts = sizeStr.split('x');
  if (parts.length != 2) {
    throw FormatException('Invalid size: $sizeStr');
  }
  final w = double.parse(parts[0]);
  final scale = double.parse(scaleStr.replaceAll(RegExp(r'[^0-9.]'), ''));
  final px = (w * scale).round();
  return px;
}

img.Image _flattenAlphaForIosIcon(img.Image source) {
  if (!source.hasAlpha) {
    return source;
  }
  final flattened = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(flattened, source);
  return flattened;
}

Future<void> generateIosAppIconSets({
  required Directory root,
  required LauncherCatalogData catalog,
}) async {
  final assetsRoot = Directory('${root.path}/ios/Runner/Assets.xcassets');
  if (!assetsRoot.existsSync()) {
    errLine('Missing ${assetsRoot.path}');
    exitCode = 1;
    return;
  }
  final ids = catalog.ids;
  final total = ids.length;
  var hadError = false;
  for (var i = 0; i < total; i++) {
    final id = ids[i];
    progressVariant(i + 1, total, 'iOS AppIcon PNGs', id);
    final setName = iosAlternateAppIconName(id, catalog.primaryVariantId);
    final appiconsetDir = Directory('${assetsRoot.path}/$setName.appiconset');
    if (!appiconsetDir.existsSync()) {
      clearLine();
      errLine(
        'Missing appiconset (run icon generation to scaffold): ${appiconsetDir.path}',
      );
      exitCode = 1;
      hadError = true;
      continue;
    }
    final contentsFile = File('${appiconsetDir.path}/Contents.json');
    if (!contentsFile.existsSync()) {
      clearLine();
      errLine('Missing ${contentsFile.path}');
      exitCode = 1;
      hadError = true;
      continue;
    }
    final contents =
        jsonDecode(contentsFile.readAsStringSync()) as Map<String, dynamic>;
    final images = contents['images'] as List<dynamic>? ?? [];
    final src = File('${root.path}/$kIconsSubdir/ic_$id.png');
    final bytes = await src.readAsBytes();
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      clearLine();
      errLine('Could not decode PNG: ${src.path}');
      exitCode = 1;
      hadError = true;
      continue;
    }
    final iosSource = _flattenAlphaForIosIcon(decoded);
    for (final raw in images) {
      final entry = raw as Map<String, dynamic>;
      final filename = entry['filename'] as String?;
      if (filename == null || filename.isEmpty) {
        continue;
      }
      final px = _pixelsFromContentsEntry(entry);
      final out = File('${appiconsetDir.path}/$filename');
      final resized = img.copyResize(
        iosSource,
        width: px,
        height: px,
        interpolation: img.Interpolation.cubic,
      );
      if (resized.hasAlpha) {
        for (final pixel in resized) {
          pixel.a = pixel.maxChannelValue;
        }
      }
      await out.writeAsBytes(img.encodePng(resized));
    }
  }
  clearLine();
  if (hadError) {
    warnLine('iOS AppIcon PNGs incomplete — see errors above.');
  } else {
    progressDone('iOS AppIcon · $total sets × all slots from Contents.json');
  }
}

Future<void> runIconGeneration(
    Directory root, LauncherCatalogData catalog) async {
  section('🍎', 'iOS · alternate app icon sets');
  await ensureIosAlternateAppIconSets(root: root, catalog: catalog);
  if (exitCode != 0) {
    return;
  }
  stepOk('Alternate sets ready (scaffolded if needed)');
  section('🤖', 'Android · mipmaps');
  await generateAndroidMipmaps(root: root, catalog: catalog);
  section('🖼️', 'iOS · AppIcon PNGs');
  await generateIosAppIconSets(root: root, catalog: catalog);
  final n = catalog.ids.length;
  stdout.writeln('');
  if (exitCode == 0) {
    stdout.writeln(
      '${green('  ✓')} ${bold('Icon pipeline complete')} ${dim('($n variant(s))')}',
    );
  } else {
    warnLine('Icon pipeline finished with errors — review messages above.');
  }
}
