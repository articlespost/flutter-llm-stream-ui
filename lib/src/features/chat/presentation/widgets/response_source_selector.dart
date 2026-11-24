import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/features/chat/data/domain/entities/response_source.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.strings.dart';

class ResponseSourceSelector extends StatelessWidget {
  const ResponseSourceSelector({
    super.key,
    required this.source,
    required this.isEnabled,
    required this.isGeminiAvailable,
    required this.onChanged,
  });

  final ResponseSource source;
  final bool isEnabled;
  final bool isGeminiAvailable;
  final ValueChanged<ResponseSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ResponseSource>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: ResponseSource.simulated,
          icon: const Icon(Icons.science_outlined),
          label: Text(ChatScreenStrings.simulatedSource),
        ),
        ButtonSegment(
          value: ResponseSource.gemini,
          icon: const Icon(Icons.travel_explore_rounded),
          label: Text(ChatScreenStrings.geminiSource),
          enabled: isGeminiAvailable,
          tooltip: isGeminiAvailable
              ? null
              : ChatScreenStrings.geminiNotConfigured,
        ),
      ],
      selected: {source},
      onSelectionChanged: isEnabled
          ? (selection) => onChanged(selection.first)
          : null,
    );
  }
}
