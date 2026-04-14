import 'package:bee_dynamic_launcher_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows title and loads catalog UI', (WidgetTester tester) async {
    await tester.pumpWidget(const BeeLauncherExampleApp());
    expect(find.textContaining('Bee Dynamic'), findsWidgets);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
