import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/performance/frame_stats.dart';

class PerformanceHud extends StatelessWidget {
  const PerformanceHud({super.key, required this.stats, required this.labels});

  final ValueListenable<FrameStats> stats;
  final PerformanceHudLabels labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Consolas'],
      color: scheme.onSurfaceVariant,
    );

    return RepaintBoundary(
      child: ValueListenableBuilder<FrameStats>(
        valueListenable: stats,
        builder: (context, value, _) {
          final hasJank = value.jankCount > 0;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${labels.frames} ${value.frameCount}',
                        style: textStyle,
                      ),
                      Text(
                        '${labels.jank} ${value.jankCount} (${value.jankPercent.toStringAsFixed(1)}%)',
                        style: textStyle?.copyWith(
                          color: hasJank ? scheme.error : scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${labels.build} ${_ms(value.averageBuildMs)}',
                        style: textStyle,
                      ),
                      Text(
                        '${labels.raster} ${_ms(value.averageRasterMs)}',
                        style: textStyle,
                      ),
                      Text(
                        '${labels.worst} ${_ms(value.worstFrameMs)}',
                        style: textStyle,
                      ),
                      Text(
                        '${labels.budget} ${_ms(value.budgetMs)}',
                        style: textStyle,
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 4),
                    Text(
                      labels.debugWarning,
                      style: textStyle?.copyWith(color: scheme.tertiary),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _ms(double value) => '${value.toStringAsFixed(1)} ms';
}

@immutable
class PerformanceHudLabels {
  const PerformanceHudLabels({
    required this.frames,
    required this.jank,
    required this.build,
    required this.raster,
    required this.worst,
    required this.budget,
    required this.debugWarning,
  });

  final String frames;
  final String jank;
  final String build;
  final String raster;
  final String worst;
  final String budget;
  final String debugWarning;
}
