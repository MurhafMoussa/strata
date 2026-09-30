import 'package:flutter/material.dart';

/// Default empty state widget displayed when a paginated list has no items.
///
/// Shows a centered inbox icon with a "No items found" message.
///
/// `@example`
/// ```dart
/// StrataEmptyState()
/// ```
class StrataEmptyState extends StatelessWidget {
  /// Creates a [StrataEmptyState].
  const StrataEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64),
            SizedBox(height: 16),
            Text('No items found'),
          ],
        ),
      ),
    );
  }
}
