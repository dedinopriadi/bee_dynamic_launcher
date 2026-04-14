import 'dart:io';
import 'dart:isolate';

Future<Directory> packageRootDirectory() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:bee_dynamic_launcher/bee_dynamic_launcher.dart'),
  );
  if (uri == null) {
    throw StateError('Could not resolve bee_dynamic_launcher package URI');
  }
  final file = File.fromUri(uri);
  return file.parent.parent;
}
