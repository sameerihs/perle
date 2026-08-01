import 'package:flutter/material.dart';

import '../../../models/wallpaper_photo.dart';
import '../../../services/external_links.dart';

class PexelsAttribution extends StatelessWidget {
  const PexelsAttribution({super.key, this.rateLimit});

  final RateLimitSnapshot? rateLimit;

  @override
  Widget build(BuildContext context) {
    final remaining = rateLimit?.remaining;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton(
            onPressed: () => _openLink(context, Uri.parse(pexelsHomeUrl)),
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.open_in_new, size: 16),
                ),
                SizedBox(width: 8),
                Expanded(child: Text('Photos provided by Pexels')),
              ],
            ),
          ),
          if (remaining != null && remaining >= 0)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Tooltip(
                  message: _quotaTooltip(),
                  child: Text(
                    '$remaining requests left',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _quotaTooltip() {
    final reset = rateLimit?.resetsAt?.toLocal();
    if (reset == null) {
      return 'Pexels API requests remaining';
    }
    return 'Pexels API quota resets ${reset.toIso8601String()}';
  }

  Future<void> _openLink(BuildContext context, Uri uri) async {
    final opened = await openPexelsLink(uri);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open Pexels.')));
    }
  }
}
