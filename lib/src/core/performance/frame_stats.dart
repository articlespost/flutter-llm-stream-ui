import 'package:flutter/foundation.dart';

@immutable
class FrameStats {
  const FrameStats({
    required this.budgetMs,
    this.frameCount = 0,
    this.jankCount = 0,
    this.averageBuildMs = 0,
    this.averageRasterMs = 0,
    this.worstFrameMs = 0,
  });

  final double budgetMs;
  final int frameCount;
  final int jankCount;
  final double averageBuildMs;
  final double averageRasterMs;
  final double worstFrameMs;

  double get jankPercent => frameCount == 0 ? 0 : jankCount * 100 / frameCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrameStats &&
          budgetMs == other.budgetMs &&
          frameCount == other.frameCount &&
          jankCount == other.jankCount &&
          averageBuildMs == other.averageBuildMs &&
          averageRasterMs == other.averageRasterMs &&
          worstFrameMs == other.worstFrameMs;

  @override
  int get hashCode => Object.hash(
    budgetMs,
    frameCount,
    jankCount,
    averageBuildMs,
    averageRasterMs,
    worstFrameMs,
  );
}
