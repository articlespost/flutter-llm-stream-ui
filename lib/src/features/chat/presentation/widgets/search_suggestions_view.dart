import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SearchSuggestionsView extends StatefulWidget {
  const SearchSuggestionsView({super.key, required this.renderedContent});

  final String renderedContent;

  @override
  State<SearchSuggestionsView> createState() => _SearchSuggestionsViewState();
}

class _SearchSuggestionsViewState extends State<SearchSuggestionsView> {
  static const double _initialHeight = 56;
  static const double _maxHeight = 240;

  final WebViewController _controller = WebViewController();
  double _height = _initialHeight;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(_controller.setBackgroundColor(Colors.transparent));
    unawaited(
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageFinished: (_) => unawaited(_measure()),
        ),
      ),
    );
    unawaited(_controller.loadHtmlString(_document(widget.renderedContent)));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null || uri.scheme == 'about' || uri.scheme == 'data') {
      return NavigationDecision.navigate;
    }
    if (uri.scheme == 'https') {
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
    }
    return NavigationDecision.prevent;
  }

  Future<void> _measure() async {
    final Object result;
    try {
      result = await _controller.runJavaScriptReturningResult(
        'document.documentElement.scrollHeight',
      );
    } on PlatformException {
      return;
    }
    final height = switch (result) {
      final num value => value.toDouble(),
      final String value => double.tryParse(value),
      _ => null,
    };
    if (!mounted || height == null || height <= 0) return;
    setState(() => _height = height.clamp(_initialHeight / 2, _maxHeight));
  }

  static String _document(String content) =>
      '<!DOCTYPE html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width, initial-scale=1">'
      '<style>html,body{margin:0;padding:0;background:transparent;}</style>'
      '</head><body>$content</body></html>';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: WebViewWidget(
        controller: _controller,
        gestureRecognizers: {
          const Factory<HorizontalDragGestureRecognizer>(
            HorizontalDragGestureRecognizer.new,
          ),
        },
      ),
    );
  }
}
