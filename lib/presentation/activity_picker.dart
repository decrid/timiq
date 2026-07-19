import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'widgets/timiq_components.dart';

Future<ActivityDetails?> showActivityPicker(BuildContext context) {
  final controller = TimiqScope.of(context, listen: false);
  return showTimiqSheet<ActivityDetails>(
    context: context,
    builder: (context) => _ActivityPickerBody(
      activities: controller.activityDeck,
    ),
  );
}

class _ActivityPickerBody extends StatefulWidget {
  const _ActivityPickerBody({required this.activities});

  final List<ActivityDetails> activities;

  @override
  State<_ActivityPickerBody> createState() => _ActivityPickerBodyState();
}

class _ActivityPickerBodyState extends State<_ActivityPickerBody> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.activities
        .where(
          (item) =>
              normalized.isEmpty ||
              item.activity.name.toLowerCase().contains(normalized) ||
              item.category.name.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    final favorites = filtered
        .where((item) => item.activity.isFavorite)
        .toList(growable: false);
    final recent = filtered
        .where(
          (item) =>
              item.lastUsedAt != null &&
              !favorites.any(
                (favorite) => favorite.activity.id == item.activity.id,
              ),
        )
        .take(5)
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: <Widget>[
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TimiqSpace.md),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Vyberte aktivitu',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TimiqIconButton(
                  icon: Icons.close,
                  tooltip: 'Zavřít',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: TimiqSpace.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TimiqSpace.md),
            child: TimiqTextField(
              controller: _search,
              hint: 'Hledat aktivitu nebo kategorii',
              prefixIcon: Icons.search,
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: TimiqSpace.md),
          Expanded(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(TimiqSpace.md),
                    child: TimiqEmptyState(
                      icon: Icons.search_off,
                      title: normalized.isEmpty
                          ? 'Zatím tu nejsou aktivity'
                          : 'Nic jsme nenašli',
                      message: normalized.isEmpty
                          ? 'Vytvořte první aktivitu v sekci Já.'
                          : 'Zkuste kratší název nebo jinou kategorii.',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TimiqSpace.md,
                      0,
                      TimiqSpace.md,
                      TimiqSpace.lg,
                    ),
                    children: <Widget>[
                      if (normalized.isEmpty && favorites.isNotEmpty) ...<Widget>[
                        const _SectionLabel('OBLÍBENÉ'),
                        ...favorites.map(_ActivityRow.new),
                        const SizedBox(height: TimiqSpace.md),
                      ],
                      if (normalized.isEmpty && recent.isNotEmpty) ...<Widget>[
                        const _SectionLabel('NEDÁVNÉ'),
                        ...recent.map(_ActivityRow.new),
                        const SizedBox(height: TimiqSpace.md),
                      ],
                      const _SectionLabel('VŠECHNY AKTIVITY'),
                      ...filtered.map(_ActivityRow.new),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, TimiqSpace.sm, 4, TimiqSpace.xs),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.details);

  final ActivityDetails details;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
      child: TimiqCard(
        onTap: () => Navigator.pop(context, details),
        child: Row(
          children: <Widget>[
            ActivityGlyph(
              iconCodePoint: details.activity.iconCodePoint,
              color: details.color,
            ),
            const SizedBox(width: TimiqSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          details.activity.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (details.activity.isFavorite) ...<Widget>[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: context.timiq.primaryGlow,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.timiq.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TimiqSpace.sm),
            Text(
              formatDuration(details.trackedToday, compact: true),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: details.trackedToday == Duration.zero
                        ? context.timiq.muted
                        : details.color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
