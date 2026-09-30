import 'package:flutter/material.dart';

/// Default offline badge widget displayed when viewing cached or offline data.
///
/// Shows an orange banner with a wifi-off icon and "Viewing offline cached data" text.
///
/// `@example`
/// ```dart
/// StrataOfflineBadge()
/// ```
class StrataOfflineBadge extends StatelessWidget {
  /// Creates a [StrataOfflineBadge].
  const StrataOfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('strata_pagination_offline_badge'),
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Text(
            'Viewing offline cached data',
            style: TextStyle(
              color: Colors.orange.shade900,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
