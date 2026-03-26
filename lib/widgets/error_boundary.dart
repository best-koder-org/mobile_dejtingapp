import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Custom error widget shown when a widget fails to build/render.
/// Set via [ErrorWidget.builder] in [setupGlobalErrorHandling].
class ErrorFallback extends StatelessWidget {
  final FlutterErrorDetails? details;

  const ErrorFallback({super.key, this.details});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Något gick fel',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ett oväntat fel inträffade.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sets up global error handling for the app:
/// - [FlutterError.onError] for framework errors (build, layout, painting)
/// - [ErrorWidget.builder] for custom error display in widget trees
/// - [PlatformDispatcher.instance.onError] for unhandled async errors
///
/// Call once in main() before runApp().
void setupGlobalErrorHandling() {
  // Framework errors — log in debug, silence the red screen in release
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    debugPrint('\u274c Flutter error: ${details.exceptionAsString()}');
  };

  // Replace the default red/yellow error widget with a user-friendly fallback
  ErrorWidget.builder = (details) => ErrorFallback(details: details);

  // Catch unhandled async errors (e.g. unawaited futures, isolate errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('\u274c Unhandled async error: $error');
    debugPrint(stack.toString());
    return true; // handled — prevent crash
  };
}
