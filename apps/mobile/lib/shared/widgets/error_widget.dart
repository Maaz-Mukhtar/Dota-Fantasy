import 'package:flutter/material.dart';

/// Error widget for displaying error states
class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Creates an error widget for network errors
  factory AppErrorWidget.network({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: 'No internet connection',
      details: 'Please check your network and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off_outlined,
    );
  }

  /// Creates an error widget for server errors
  factory AppErrorWidget.server({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: 'Server error',
      details: 'Something went wrong. Please try again later.',
      onRetry: onRetry,
      icon: Icons.cloud_off_outlined,
    );
  }

  /// Creates an error widget for generic errors
  factory AppErrorWidget.generic({
    required String message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      message: message,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
