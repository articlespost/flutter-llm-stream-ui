import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/performance/frame_metrics_monitor.dart';

void main() {
  FrameTiming frame({
    required int buildMs,
    required int rasterMs,
    int vsyncToBuildMs = 0,
  }) {
    const start = 1000000;
    final buildStart = start + vsyncToBuildMs * 1000;
    final buildFinish = buildStart + buildMs * 1000;
    final rasterFinish = buildFinish + rasterMs * 1000;
    return FrameTiming(
      vsyncStart: start,
      buildStart: buildStart,
      buildFinish: buildFinish,
      rasterStart: buildFinish,
      rasterFinish: rasterFinish,
      rasterFinishWallTime: rasterFinish,
    );
  }

  test('jank é build ou raster acima do orçamento, não o tempo total', () {
    final monitor = FrameMetricsMonitor(refreshRate: 60);
    addTearDown(monitor.dispose);

    monitor.record([
      frame(buildMs: 10, rasterMs: 10, vsyncToBuildMs: 5),
      frame(buildMs: 20, rasterMs: 4),
      frame(buildMs: 3, rasterMs: 18),
    ]);

    final stats = monitor.value;
    expect(stats.frameCount, 3);
    expect(stats.jankCount, 2);
    expect(stats.averageBuildMs, closeTo(11, 0.001));
    expect(stats.averageRasterMs, closeTo(10.667, 0.001));
    expect(stats.worstFrameMs, 20);
    expect(stats.budgetMs, closeTo(16.667, 0.001));
  });

  test('orçamento acompanha a taxa de atualização da tela', () {
    final monitor = FrameMetricsMonitor(refreshRate: 120);
    addTearDown(monitor.dispose);

    monitor.record([frame(buildMs: 9, rasterMs: 2)]);

    expect(monitor.value.budgetMs, closeTo(8.333, 0.001));
    expect(monitor.value.jankCount, 1);
  });

  test('reset zera as estatísticas mantendo o orçamento', () {
    final monitor = FrameMetricsMonitor(refreshRate: 60);
    addTearDown(monitor.dispose);

    monitor
      ..record([frame(buildMs: 30, rasterMs: 1)])
      ..reset();

    expect(monitor.value.frameCount, 0);
    expect(monitor.value.jankCount, 0);
    expect(monitor.value.budgetMs, closeTo(16.667, 0.001));
  });
}
