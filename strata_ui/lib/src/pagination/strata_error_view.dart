import 'package:flutter/material.dart';

/// Default error view widget displayed when the initial fetch fails.
///
/// Shows the failure message centered on screen with an optional "Retry" button.
///
/// `@example`
/// ```dart
/// StrataErrorView(
///   message: 'Connection failed',
///   onRetry: () => context.read<MyBloc>().add(const Retry()),
/// )
/// ```
class StrataErrorView extends StatelessWidget {
  /// Creates a [StrataErrorView].
  const StrataErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  /// The error message to display.
  final String message;

  /// Callback invoked when the user taps the retry button.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (onRetry != null)
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
