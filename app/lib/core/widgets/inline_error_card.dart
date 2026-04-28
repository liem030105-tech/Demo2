import 'package:flutter/material.dart';

class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({
    required this.message,
    required this.onRetry,
    this.title = 'Có lỗi xảy ra',
    super.key,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

