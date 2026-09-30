import 'package:flutter/material.dart';

/// Default bottom loader widget displayed while loading the next page.
///
/// Shows a centered [CircularProgressIndicator.adaptive] with padding.
///
/// `@example`
/// ```dart
/// StrataBottomLoader()
/// ```
class StrataBottomLoader extends StatelessWidget {
  /// Creates a [StrataBottomLoader].
  const StrataBottomLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('strata_pagination_bottom_loader'),
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: const CircularProgressIndicator.adaptive(),
    );
  }
}
