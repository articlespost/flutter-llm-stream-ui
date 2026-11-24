import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/features/chat/presentation/screens/chat_screen.dart';

abstract final class AppRoutes {
  static const String chat = ChatScreen.routeName;
  static const String initial = chat;
}

abstract final class RouteGenerator {
  static Route<void> pageFor(RouteSettings settings) => switch (settings.name) {
    AppRoutes.chat => _build(settings, const ChatScreen()),
    _ => _build(
      const RouteSettings(name: AppRoutes.initial),
      const ChatScreen(),
    ),
  };

  static List<Route<void>> initialRoutes(String initialRouteName) => [
    pageFor(RouteSettings(name: initialRouteName)),
  ];

  static Route<void> _build(RouteSettings settings, Widget page) =>
      MaterialPageRoute<void>(settings: settings, builder: (_) => page);
}
