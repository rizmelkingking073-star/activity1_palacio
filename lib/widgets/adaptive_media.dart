import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/network_diagnostic_state.dart';
import '../theme/app_theme.dart';

/// An image that changes what it fetches based on the connection health the
/// diagnostic tool has broadcast.
///
/// * [MediaQuality.full]        — full-resolution asset.
/// * [MediaQuality.reduced]     — smaller asset, decoded at a lower width.
/// * [MediaQuality.placeholder] — nothing is fetched at all; a local, zero-cost
///                                placeholder is drawn instead.
///
/// Because it reads the tier through `context.watch`, the swap happens the
/// moment a diagnostic finishes, anywhere in the app.
class AdaptiveMedia extends StatelessWidget {
  final String fullResUrl;
  final String lowResUrl;
  final String caption;
  final IconData placeholderIcon;
  final double height;

  const AdaptiveMedia({
    super.key,
    required this.fullResUrl,
    required this.lowResUrl,
    required this.caption,
    this.placeholderIcon = Icons.image_rounded,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quality = context.watch<NetworkDiagnosticState>().mediaQuality;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: _buildMedia(context, quality, isDark),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caption, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        _qualityNote(quality),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _QualityChip(quality: quality),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context, MediaQuality quality, bool isDark) {
    switch (quality) {
      case MediaQuality.full:
        return Image.network(
          fullResUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _loading(isDark),
          errorBuilder: (_, __, ___) => _placeholder(context, isDark),
        );

      case MediaQuality.reduced:
        // Smaller source *and* a capped decode width, so both the transfer and
        // the memory cost drop on a mid-tier link.
        return Image.network(
          lowResUrl,
          fit: BoxFit.cover,
          cacheWidth: 480,
          filterQuality: FilterQuality.low,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _loading(isDark),
          errorBuilder: (_, __, ___) => _placeholder(context, isDark),
        );

      case MediaQuality.placeholder:
        return _placeholder(context, isDark);
    }
  }

  Widget _loading(bool isDark) => ColoredBox(
        color: isDark ? const Color(0xFF3A3C40) : const Color(0xFFE5E7EB),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  /// Drawn locally — no network request is made in this state.
  Widget _placeholder(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      color: isDark ? const Color(0xFF3A3C40) : const Color(0xFFE9ECEF),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(placeholderIcon,
              size: 34, color: AppColors.secondaryGreen.withValues(alpha: 0.8)),
          const SizedBox(height: AppSpacing.sm),
          Text('Image not loaded', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _qualityNote(MediaQuality quality) {
    switch (quality) {
      case MediaQuality.full:
        return 'Full resolution';
      case MediaQuality.reduced:
        return 'Reduced resolution to save bandwidth';
      case MediaQuality.placeholder:
        return 'Placeholder only — tap refresh once the connection improves';
    }
  }
}

class _QualityChip extends StatelessWidget {
  final MediaQuality quality;

  const _QualityChip({required this.quality});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (quality) {
      case MediaQuality.full:
        color = AppColors.primaryDeepGreen;
        label = 'Full';
        break;
      case MediaQuality.reduced:
        color = AppColors.secondaryGreen;
        label = 'Light';
        break;
      case MediaQuality.placeholder:
        color = AppColors.accentOrange;
        label = 'Text only';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}