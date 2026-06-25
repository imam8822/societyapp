import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/api/api_client.dart';

class NetworkErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const NetworkErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = apiError(error);
    final isNetwork = errorMessage.toLowerCase().contains('network') ||
                      errorMessage.toLowerCase().contains('internet') ||
                      errorMessage.toLowerCase().contains('server');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 64,
                color: isNetwork ? context.colors.warning : context.colors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNetwork ? 'Connection Lost' : 'Oops, something went wrong',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 15,
                color: context.colors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
