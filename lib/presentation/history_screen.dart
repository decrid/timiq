import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/analytics.dart';
import '../domain/models.dart';
import 'time_entry_editor.dart';
import 'widgets/timiq_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDay = startOfDay(DateTime.now());
  Future<List<EntryDetails>>? _entriesFuture;
  int _loadedRevision = -1;

  void _load(TimiqController controller) {
    _entriesFuture = controller.entriesForDay(_selectedDay);
    _loadedRevision = controller.revision;
  }

  void _moveDay(int offset) {
    setState(() {
      _selectedDay = addCalendarDays(_selectedDay, offset);
      _loadedRevision = -1;
    });
  }

  Future<void> _openEditor({
    EntryDetails? existing,
    DateTime? start,
    DateTime? end,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TimeEntryEditor(
          existing: existing,
          prefilledStart: start,
          prefilledEnd: end,
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _loadedRevision = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    if (_entriesFuture == null || _loadedRevision != controller.revision) {
      _load(controller);
    }
    return TimiqPage(
      child: Column(
        children: <Widget>[
          TimiqScreenHeader(
            title: 'Historie',
            subtitle: 'Časová osa a nezaznamenané mezery',
            trailing: TimiqIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Přidat záznam',
              onPressed: () {
                final now = controller.now;
                final start = _selectedDay == startOfDay(now)
                    ? now.subtract(const Duration(hours: 1))
                    : _selectedDay.add(const Duration(hours: 9));
                _openEditor(
                  start: start,
                  end: start.add(const Duration(hours: 1)),
                );
              },
            ),
          ),
          const SizedBox(height: TimiqSpace.lg),
          TimiqCard(
            padding: const EdgeInsets.symmetric(
              horizontal: TimiqSpace.xs,
              vertical: TimiqSpace.xs,
            ),
            child: Row(
              children: <Widget>[
                TimiqIconButton(
                  icon: Icons.chevron_left,
                  tooltip: 'Předchozí den',
                  onPressed: () => _moveDay(-1),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TimiqRadius.small),
                    onTap: () => setState(() {
                      _selectedDay = startOfDay(DateTime.now());
                      _loadedRevision = -1;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        _selectedDay == startOfDay(DateTime.now())
                            ? 'Dnes · ${formatDate(_selectedDay)}'
                            : formatDateWithWeekday(_selectedDay),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                TimiqIconButton(
                  icon: Icons.chevron_right,
                  tooltip: 'Další den',
                  onPressed: _selectedDay
                          .isBefore(startOfDay(DateTime.now()))
                      ? () => _moveDay(1)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: TimiqSpace.md),
          Expanded(
            child: FutureBuilder<List<EntryDetails>>(
              future: _entriesFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TimiqEmptyState(
                    icon: Icons.shield_outlined,
                    title: 'Historii se nepodařilo načíst',
                    message:
                        'Data jsme nezměnili. Zkuste obrazovku otevřít znovu.',
                    actionLabel: 'Zkusit znovu',
                    onAction: () =>
                        setState(() => _loadedRevision = -1),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      color: context.timiq.primaryGlow,
                      size: 32,
                    ),
                  );
                }
                final details = snapshot.data!;
                if (details.isEmpty) {
                  return TimiqEmptyState(
                    icon: Icons.view_timeline_outlined,
                    title: 'Tento den je zatím prázdný',
                    message:
                        'Přidejte záznam ručně nebo začněte měřit na obrazovce '
                        'Dnes.',
                    actionLabel: 'Přidat záznam',
                    onAction: () {
                      final start =
                          _selectedDay.add(const Duration(hours: 9));
                      _openEditor(
                        start: start,
                        end: start.add(const Duration(hours: 1)),
                      );
                    },
                  );
                }
                final range =
                    DateRange(_selectedDay, endOfDay(_selectedDay));
                final items = const TimelineBuilder()
                    .build(details, range, controller.now);
                final total = details.fold(
                  Duration.zero,
                  (sum, item) =>
                      sum +
                      clippedDuration(
                        item.entry.startTime,
                        item.entry.endTime,
                        range,
                        controller.now,
                      ),
                );
                return ListView(
                  padding: const EdgeInsets.only(bottom: TimiqSpace.lg),
                  children: <Widget>[
                    TimiqCard(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.timelapse_rounded,
                            color: context.timiq.primaryGlow,
                          ),
                          const SizedBox(width: TimiqSpace.sm),
                          Expanded(
                            child: Text(
                              'Zaznamenáno',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            formatDuration(total),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TimiqSpace.md),
                    ...items.map(
                      (item) => item is TimelineEntryItem
                          ? _EntryTile(
                              item: item,
                              timeFormat: controller.settings.timeFormat,
                              onTap: () =>
                                  _openEditor(existing: item.details),
                            )
                          : _GapTile(
                              item: item as TimelineGapItem,
                              timeFormat: controller.settings.timeFormat,
                              onTap: () => _openEditor(
                                start: item.start,
                                end: item.end,
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.item,
    required this.timeFormat,
    required this.onTap,
  });

  final TimelineEntryItem item;
  final TimiqTimeFormat timeFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = item.details;
    return Padding(
      padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatClock(item.start, format: timeFormat),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  details.entry.endTime == null
                      ? 'běží'
                      : formatClock(item.end, format: timeFormat),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.timiq.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: TimiqSpace.sm),
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: details.color,
              borderRadius: BorderRadius.circular(TimiqRadius.pill),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: details.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: TimiqSpace.sm),
          Expanded(
            child: TimiqCard(
              onTap: onTap,
              child: Row(
                children: <Widget>[
                  ActivityGlyph(
                    iconCodePoint: details.activity.iconCodePoint,
                    color: details.color,
                    size: 40,
                  ),
                  const SizedBox(width: TimiqSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          details.activity.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          details.category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: details.color),
                        ),
                        if (details.entry.note.isNotEmpty ||
                            details.tags.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            <String>[
                              if (details.entry.note.isNotEmpty)
                                details.entry.note,
                              ...details.tags.map((tag) => '#${tag.name}'),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: TimiqSpace.xs),
                  Text(
                    details.entry.endTime == null
                        ? 'BĚŽÍ'
                        : formatDuration(item.end.difference(item.start),
                            compact: true),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: details.color,
                        ),
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  const _GapTile({
    required this.item,
    required this.timeFormat,
    required this.onTap,
  });

  final TimelineGapItem item;
  final TimiqTimeFormat timeFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(70, 0, 0, TimiqSpace.xs),
      child: Material(
        color: context.timiq.elevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(TimiqRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(TimiqRadius.medium),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TimiqSpace.md,
              vertical: TimiqSpace.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TimiqRadius.medium),
              border: Border.all(
                color: context.timiq.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.add_circle_outline,
                  color: context.timiq.muted,
                  size: 20,
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Text(
                    '${formatClock(item.start, format: timeFormat)}–'
                    '${formatClock(item.end, format: timeFormat)} '
                    'nezaznamenáno',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.timiq.muted),
                  ),
                ),
                Text(
                  formatDuration(item.end.difference(item.start), compact: true),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
