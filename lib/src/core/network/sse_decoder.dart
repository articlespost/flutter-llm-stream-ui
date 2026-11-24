import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class SseEvent {
  const SseEvent({this.event, required this.data});

  final String? event;
  final String data;
}

Stream<SseEvent> decodeSse(Stream<List<int>> bytes) async* {
  String? event;
  final data = <String>[];
  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield SseEvent(event: event, data: data.join('\n'));
      event = null;
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        data.add(value);
    }
  }
  if (data.isNotEmpty) yield SseEvent(event: event, data: data.join('\n'));
}
