import 'package:flutter/widgets.dart';
import 'package:llm_stream_ui/src/core/di/app_container.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.container, required super.child});

  final AppContainer container;

  static AppContainer of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError('AppScope not found in the widget tree.');
    }
    return scope.container;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(container, oldWidget.container);
}
