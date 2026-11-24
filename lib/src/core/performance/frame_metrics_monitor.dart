import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:llm_stream_ui/src/core/performance/frame_stats.dart';

class FrameMetricsMonitor extends ValueNotifier<FrameStats> {
  FrameMetricsMonitor({required double refreshRate})
    : _budgetMs = 1000 / (refreshRate > 0 ? refreshRate : 60),
      super(FrameStats(budgetMs: 1000 / (refreshRate > 0 ? refreshRate : 60)));

  final double _budgetMs;
  int _frameCount = 0;
  int _jankCount = 0;
  double _totalBuildMs = 0;
  double _totalRasterMs = 0;
  double _worstFrameMs = 0;
  bool _isListening = false;

  void start() {
    if (_isListening) return;
    _isListening = true;
    SchedulerBinding.instance.addTimingsCallback(record);
  }

  void reset() {
    _frameCount = 0;
    _jankCount = 0;
    _totalBuildMs = 0;
    _totalRasterMs = 0;
    _worstFrameMs = 0;
    value = FrameStats(budgetMs: _budgetMs);
  }

  void record(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    for (final timing in timings) {
      final buildMs = _millisecondsOf(timing.buildDuration);
      final rasterMs = _millisecondsOf(timing.rasterDuration);
      final slowestPhaseMs = math.max(buildMs, rasterMs);
      _frameCount++;
      _totalBuildMs += buildMs;
      _totalRasterMs += rasterMs;
      _worstFrameMs = math.max(_worstFrameMs, slowestPhaseMs);
      if (slowestPhaseMs > _budgetMs) _jankCount++;
    }
    value = FrameStats(
      budgetMs: _budgetMs,
      frameCount: _frameCount,
      jankCount: _jankCount,
      averageBuildMs: _totalBuildMs / _frameCount,
      averageRasterMs: _totalRasterMs / _frameCount,
      worstFrameMs: _worstFrameMs,
    );
  }

  static double _millisecondsOf(Duration duration) =>
      duration.inMicroseconds / Duration.microsecondsPerMillisecond;

  @override
  void dispose() {
    if (_isListening) {
      SchedulerBinding.instance.removeTimingsCallback(record);
    }
    super.dispose();
  }
}
