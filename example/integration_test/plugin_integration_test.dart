import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize exposes variants from native', (tester) async {
    await BeeDynamicLauncher.initialize(
      variantIds: const ['demo'],
      primaryVariantId: 'demo',
    );
    final variants = await BeeDynamicLauncher.getAvailableVariants();
    expect(variants, ['demo']);
  });
}
