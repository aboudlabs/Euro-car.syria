// Status chips, banners, empty states and loading blocks.

import 'package:flutter/material.dart';

import '../core/labels.dart';
import '../theme/palette.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Color color = p.toneColor(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

enum NoticeKind { info, success, warning, error }

/// A message strip with an icon, used for errors, confirmations and hints.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
    this.onRetry,
    this.onDismiss,
    this.retryLabel = 'إعادة المحاولة',
  });

  final String message;
  final NoticeKind kind;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Color color;
    final IconData icon;
    switch (kind) {
      case NoticeKind.success:
        color = p.ok;
        icon = Icons.check_circle_outline_rounded;
      case NoticeKind.warning:
        color = p.warn;
        icon = Icons.warning_amber_rounded;
      case NoticeKind.error:
        color = p.err;
        icon = Icons.error_outline_rounded;
      case NoticeKind.info:
        color = p.primary;
        icon = Icons.info_outline_rounded;
    }
    final VoidCallback? retry = onRetry;
    final VoidCallback? dismiss = onDismiss;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 6, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    message,
                    style: TextStyle(color: p.text, fontSize: 14, height: 1.5),
                  ),
                ),
              ),
              if (retry != null)
                TextButton(
                  onPressed: retry,
                  child: Text(retryLabel, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ),
              if (dismiss != null)
                IconButton(
                  onPressed: dismiss,
                  tooltip: 'إغلاق',
                  icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when a list has nothing to display. The action (if any) tells the user what to do next.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final String? text = message;
    final String? label = actionLabel;
    final VoidCallback? action = onAction;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 44, color: p.muted),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (text != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 14, height: 1.5),
            ),
          ],
          if (label != null && action != null) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton(onPressed: action, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

/// A centred spinner with a short explanation.
class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 14),
          Text(message, style: TextStyle(color: p.muted, fontSize: 14)),
        ],
      ),
    );
  }
}
