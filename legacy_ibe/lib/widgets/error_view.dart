import "package:flutter/material.dart";

class ErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final bool isOffline;

  const ErrorView({
    super.key,
    this.message,
    required this.onRetry,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFdfa273);
    const card = Color(0xFF0A3C30);

    final title =
    isOffline ? "No Internet Connection" : "Could not load prices";

    final body = isOffline
        ? "Please check your internet connection and try again."
        : (message?.trim().isNotEmpty == true
        ? message!.trim()
        : "Something went wrong. Please try again.");

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: accent.withOpacity(0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                    border: Border.all(color: accent.withOpacity(0.28)),
                  ),
                  child: Icon(
                    isOffline
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    size: 32,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(isOffline ? "Try Again" : "Retry"),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}