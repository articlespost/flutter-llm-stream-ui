import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:llm_stream_ui/src/app.dart';
import 'package:llm_stream_ui/src/core/di/app_container.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final stressPrompt = ChatScreenStrings.suggestions.last;

  Future<void> openChat(WidgetTester tester) async {
    await tester.pumpWidget(LlmStreamApp(container: AppContainer()));
    await tester.pumpAndSettle();
  }

  Future<void> waitForResponse(WidgetTester tester) async {
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    while (find.byIcon(Icons.stop_rounded).evaluate().isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('streaming did not finish in time');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await tester.pump();
  }

  Future<void> measure(
    WidgetTester tester, {
    required String strategyLabel,
    required String reportKey,
  }) async {
    await openChat(tester);
    await tester.tap(find.text(strategyLabel));
    await tester.pumpAndSettle();

    await Future<void>.delayed(const Duration(seconds: 2));
    final timings = <FrameTiming>[];
    final TimingsCallback watcher = timings.addAll;
    binding.addTimingsCallback(watcher);

    await tester.tap(find.text(stressPrompt));
    await waitForResponse(tester);

    await Future<void>.delayed(const Duration(seconds: 2));
    binding.removeTimingsCallback(watcher);

    binding.reportData ??= <String, dynamic>{};
    binding.reportData![reportKey] = FrameTimingSummarizer(timings).summary;
  }

  testWidgets('aquecimento', (tester) async {
    await openChat(tester);
    await tester.tap(find.text(ChatScreenStrings.suggestions.first));
    await waitForResponse(tester);
  });

  testWidgets('streaming no modo ingênuo', (tester) async {
    await measure(
      tester,
      strategyLabel: ChatScreenStrings.naive,
      reportKey: 'naive_streaming',
    );
  });

  testWidgets('streaming no modo otimizado', (tester) async {
    await measure(
      tester,
      strategyLabel: ChatScreenStrings.optimized,
      reportKey: 'optimized_streaming',
    );
  });
}
