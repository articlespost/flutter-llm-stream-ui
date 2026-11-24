import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/state/chat_state.dart';

class StrategySelector extends StatelessWidget {
  const StrategySelector({
    super.key,
    required this.strategy,
    required this.isEnabled,
    required this.onChanged,
  });

  final RenderingStrategy strategy;
  final bool isEnabled;
  final ValueChanged<RenderingStrategy> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RenderingStrategy>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: RenderingStrategy.naive,
          icon: const Icon(Icons.speed_rounded),
          label: Text(ChatScreenStrings.naive),
        ),
        ButtonSegment(
          value: RenderingStrategy.optimized,
          icon: const Icon(Icons.bolt_rounded),
          label: Text(ChatScreenStrings.optimized),
        ),
      ],
      selected: {strategy},
      onSelectionChanged: isEnabled
          ? (selection) => onChanged(selection.first)
          : null,
    );
  }
}
