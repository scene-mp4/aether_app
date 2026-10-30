// lib/widgets/firebase_error_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pollutracker_app/stores/app_data_store.dart';

/// Shows a dismiss-free error banner with a Retry button whenever
/// AppDataStore.loadError is set. Renders nothing when there is no error,
/// so it is safe to drop into any screen.
class FirebaseErrorBanner extends StatelessWidget {
  const FirebaseErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store   = context.watch<AppDataStore>();
    final message = store.loadError;
    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFECACA))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.cloud_off_outlined,
                color: Color(0xFFDC2626), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Could not load tracker data',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => store.retry(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Retry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}