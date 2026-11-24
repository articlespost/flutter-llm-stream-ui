import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration step = const Duration(milliseconds: 16),
  int maxSteps = 5000,
}) async {
  for (var count = 0; count < maxSteps && !condition(); count++) {
    await tester.pump(step);
  }
  expect(condition(), isTrue, reason: 'condition not reached');
}
