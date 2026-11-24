import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_stream_ui/src/core/markdown/incremental_markdown_document.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_block_parser.dart';
import 'package:llm_stream_ui/src/core/markdown/markdown_node.dart';
import 'package:llm_stream_ui/src/features/chat/data/datasource/llm_stream_data_source.dart';
import 'package:llm_stream_ui/src/features/chat/data/models/completion_request_model.dart';

import '../../helpers/markdown_debug.dart';

void main() {
  const prompts = [
    'Explique streams em Dart',
    'Como é o Flow no Kotlin?',
    'Mostre um cliente SSE em Python',
    'Resposta longa (teste de estresse)',
  ];

  Future<String> fullResponse(String prompt) =>
      const LlmStreamDataSource(chunkInterval: Duration.zero)
          .streamCompletion(CompletionRequestModel(prompt: prompt))
          .join();

  List<MarkdownBlock> streamIncrementally(String source, math.Random random) {
    final document = IncrementalMarkdownDocument();
    var index = 0;
    while (index < source.length) {
      final end = math.min(index + 1 + random.nextInt(12), source.length);
      document.append(source.substring(index, end));
      index = end;
    }
    document.complete();
    return document.snapshot.frozenBlocks;
  }

  for (final prompt in prompts) {
    test('incremental equivale ao parse completo: "$prompt"', () async {
      final source = await fullResponse(prompt);
      final expected = describeBlocks(MarkdownBlockParser.parse(source));

      for (var seed = 0; seed < 25; seed++) {
        final actual = describeBlocks(
          streamIncrementally(source, math.Random(seed)),
        );
        expect(actual, expected, reason: 'seed $seed');
      }
    });
  }

  test('blocos congelados nunca mudam depois de congelados', () async {
    final source = await fullResponse('Resposta longa (teste de estresse)');
    final document = IncrementalMarkdownDocument();
    final seen = <MarkdownBlock>[];
    final random = math.Random(7);
    var index = 0;

    while (index < source.length) {
      final end = math.min(index + 1 + random.nextInt(9), source.length);
      document.append(source.substring(index, end));
      index = end;
      final frozen = document.snapshot.frozenBlocks;
      expect(frozen.length, greaterThanOrEqualTo(seen.length));
      for (var position = 0; position < seen.length; position++) {
        expect(identical(frozen[position], seen[position]), isTrue);
      }
      seen
        ..clear()
        ..addAll(frozen);
    }
  });

  test('o trecho reprocessado fica pequeno em uma resposta longa', () async {
    final source = await fullResponse('Resposta longa (teste de estresse)');
    final document = IncrementalMarkdownDocument();
    var largestTail = 0;
    for (var index = 0; index < source.length; index += 6) {
      document.append(
        source.substring(index, math.min(index + 6, source.length)),
      );
      final snapshot = document.snapshot;
      largestTail = math.max(largestTail, snapshot.tailBlocks.length);
    }

    expect(document.snapshot.frozenBlocks.length, greaterThan(40));
    expect(largestTail, lessThanOrEqualTo(3));
  });

  test('bloco de código aberto continua no trecho até fechar', () {
    final document = IncrementalMarkdownDocument()
      ..append('Intro\n\n```dart\nfinal a = 1;\n\nfinal b = 2;\n');

    expect(describeBlocks(document.snapshot.frozenBlocks), 'P(Intro)');
    expect(
      describeBlocks(document.snapshot.tailBlocks),
      'C(dart,false,final a = 1;\n\nfinal b = 2;\n)',
    );

    document.append('```\n');

    expect(document.snapshot.tailBlocks, isEmpty);
    expect(
      describeBlock(document.snapshot.frozenBlocks.last),
      'C(dart,true,final a = 1;\n\nfinal b = 2;)',
    );
  });
}
