import 'package:flutter/widgets.dart';
import 'package:llm_stream_ui/src/app.dart';
import 'package:llm_stream_ui/src/core/di/app_container.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LlmStreamApp(container: AppContainer()));
}
