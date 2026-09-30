import 'package:flutter/material.dart';
import 'package:strata_core/strata_core.dart';

/// Default bottom retry bar widget displayed when a page-N fetch fails.
///
/// Shows the failure message alongside a "Retry" button that triggers [onRetryMore].
///
/// `@example`
/// ```dart
/// StrataBottomRetryBar(
///   failure: ServerFailure(message: 'Failed to load page 2', statusCode: 500),
///   onRetryMore: () => context.read<MyBloc>().add(const RetryMore()),
/// )
/// ```
class StrataBottomRetryBar extends StatelessWidget {
  /// Creates a [StrataBottomRetryBar].
  const StrataBottomRetryBar({
    super.key,
    required this.failure,
    required this.onRetryMore,
  });

  /// The failure that occurred during page fetch.
  final Failure? failure;

  /// Callback invoked when the user taps the retry button.
  final VoidCallback? onRetryMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('strata_pagination_retry_bar'),
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              failure?.message ?? 'Failed to load next page',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton.icon(
            key: const Key('strata_pagination_retry_button'),
            onPressed: onRetryMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
