import 'package:bee_dynamic_launcher/bee_dynamic_launcher.dart';
import 'package:flutter/material.dart';

class LauncherVariantsSection extends StatelessWidget {
  const LauncherVariantsSection({
    super.key,
    required this.entries,
    required this.currentVariantId,
    required this.busyVariantId,
    required this.onApply,
  });

  final List<LauncherVariantEntry> entries;
  final String? currentVariantId;
  final String? busyVariantId;
  final Future<void> Function(LauncherVariantEntry entry) onApply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final borderColor = scheme.secondary.withValues(alpha: 0.28);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _VariantOptionCard(
                entry: entry,
                selected: entry.id == currentVariantId,
                busy: entry.id == busyVariantId,
                locked: busyVariantId != null,
                onTap: () => onApply(entry),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VariantOptionCard extends StatelessWidget {
  const _VariantOptionCard({
    required this.entry,
    required this.selected,
    required this.busy,
    required this.locked,
    required this.onTap,
  });

  final LauncherVariantEntry entry;
  final bool selected;
  final bool busy;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderColor = selected
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant.withValues(alpha: 0.35);
    final isLight = scheme.brightness == Brightness.light;
    final backgroundColor = isLight
        ? const Color(0xFFFCFCFD)
        : scheme.surfaceContainer;

    final clickable = !selected && !locked && !busy;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: clickable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  entry.previewIconAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.image_not_supported_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: busy
                    ? SizedBox(
                        key: const ValueKey('busy'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('selected'),
                            color: scheme.primary,
                            size: 20,
                          )
                        : Icon(
                            Icons.chevron_right_rounded,
                            key: const ValueKey('next'),
                            color: scheme.onSurfaceVariant,
                            size: 20,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
