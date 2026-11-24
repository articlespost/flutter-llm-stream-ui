import 'package:flutter/material.dart';
import 'package:llm_stream_ui/src/core/di/app_container.dart';
import 'package:llm_stream_ui/src/core/di/app_scope.dart';
import 'package:llm_stream_ui/src/core/router/route_generator.dart';
import 'package:llm_stream_ui/src/core/theme/app_theme.dart';

class LlmStreamApp extends StatelessWidget {
  const LlmStreamApp({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      container: container,
      child: MaterialApp(
        title: 'LLM Stream UI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        initialRoute: AppRoutes.initial,
        onGenerateRoute: RouteGenerator.pageFor,
        onGenerateInitialRoutes: RouteGenerator.initialRoutes,
      ),
    );
  }
}
