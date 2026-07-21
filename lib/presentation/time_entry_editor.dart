import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'widgets/timiq_components.dart';
import 'widgets/timiq_pickers.dart';

class TimeEntryEditor extends StatefulWidget {
  const TimeEntryEditor({
    super.key,
    this.existing,
    this.prefilledStart,
    this.prefilledEnd,
  });

  final EntryDetails? existing;
  final DateTime? prefilledStart;
  final DateTime? prefilledEnd;

  @override
  State<TimeEntryEditor> createState() => _TimeEntryEditorState();
}

class _TimeEntryEditorState extends State<TimeEntryEditor> {
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _start;
  late TimeOfDay _end;
  String? _activityId;
  late final TextEditingController _note;
  late final Set<String> _tagIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    var sourceStart = widget.existing?.entry.startTime ??
        widget.prefilledStart ??
        now.subtract(const Duration(hours: 1));
    var sourceEnd = widget.existing?.entry.endTime ??
        (widget.existing != null
            ? now
            : widget.prefilledEnd ?? now);
    if (sourceEnd.isAfter(now)) {
      sourceEnd = now;
    }
    if (!sourceEnd.isAfter(sourceStart.add(const Duration(minutes: 1)))) {
      sourceStart = sourceEnd.subtract(const Duration(minutes: 1));
    }
    _startDate = startOfDay(sourceStart);
    _endDate = startOfDay(sourceEnd);
    _start = TimeOfDay.fromDateTime(sourceStart);
    _end = TimeOfDay.fromDateTime(sourceEnd);
    _activityId = widget.existing?.activity.id;
    _note = TextEditingController(text: widget.existing?.entry.note ?? '');
    _tagIds = <String>{...?widget.existing?.entry.tagIds};
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  DateTime get _startDateTime => _combine(_startDate, _start);

  DateTime get _endDateTime => _combine(_endDate, _end);

  Future<void> _pickDate({required bool start}) async {
    final value = await showTimiqDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = startOfDay(value);
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = startOfDay(value);
      }
    });
  }

  Future<void> _pickTime(bool start) async {
    final controller = TimiqScope.of(context, listen: false);
    final value = await showTimiqTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      use24HourFormat:
          controller.settings.timeFormat == TimiqTimeFormat.twentyFourHour,
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _pickActivity() async {
    final controller = TimiqScope.of(context, listen: false);
    final selected = await showTimiqChoice<TimiqActivity>(
      context: context,
      title: 'Vyberte aktivitu',
      values: controller.activeActivities,
      selected: _activityId == null
          ? null
          : controller.activityById(_activityId!),
      labelBuilder: (value) => value.name,
      leadingBuilder: (context, value) {
        final category = controller.categoryById(value.categoryId);
        return ActivityGlyph(
          iconCodePoint: value.iconCodePoint,
          color: Color(value.customColorValue ??
              category?.colorValue ??
              context.timiq.primary.toARGB32()),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _activityId = selected.id);
    }
  }

  Future<void> _save() async {
    final activityId = _activityId;
    if (activityId == null) {
      showTimiqMessage(context, 'Vyberte aktivitu.', isError: true);
      return;
    }
    final controller = TimiqScope.of(context, listen: false);
    final start = _startDateTime;
    final end = _endDateTime;
    if (!end.isAfter(start)) {
      showTimiqMessage(
        context,
        'Konec záznamu musí být později než začátek.',
        isError: true,
      );
      return;
    }
    if (end.isAfter(controller.now)) {
      showTimiqMessage(
        context,
        'Konec záznamu nesmí být v budoucnosti.',
        isError: true,
      );
      return;
    }
    final conflicts = await controller.findConflicts(
      start,
      end,
      excludingId: widget.existing?.entry.id,
    );
    if (!mounted) return;
    if (conflicts.isNotEmpty) {
      await _showOverlap(conflicts);
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existing?.entry;
    final timestamp = controller.now;
    final entry = TimeEntry(
      id: existing?.id ?? newId('entry'),
      activityId: activityId,
      startTime: start,
      endTime: end,
      note: _note.text.trim(),
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
      tagIds: _tagIds.toList(growable: false),
    );
    try {
      await controller.saveEntry(entry);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showOverlap(List<OverlapConflict> conflicts) async {
    final conflictLabel = conflicts.length == 1
        ? 'jiným záznamem'
        : '${conflicts.length} jinými záznamy';
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(TimiqSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.layers_outlined,
                    color: TimiqColors.warning,
                  ),
                  const SizedBox(width: TimiqSpace.sm),
                  Expanded(
                    child: Text(
                      'Čas se překrývá',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TimiqSpace.sm),
              Text(
                'Zadaný úsek koliduje s $conflictLabel. '
                    'Historii jsme nezměnili. Vraťte se a upravte čas, '
                    'nebo operaci zrušte.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: context.timiq.muted),
              ),
              const SizedBox(height: TimiqSpace.lg),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Zpět upravit čas',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: TimiqSpace.xs),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Zrušit celý záznam',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showTimiqConfirm(
      context: context,
      title: 'Odstranit záznam?',
      message:
          'Tato historická položka bude trvale odstraněna. Ostatních záznamů '
          'se akce nedotkne.',
      confirmLabel: 'Odstranit',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await TimiqScope.of(context, listen: false)
          .deleteEntry(existing.entry.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    final selectedActivity = _activityId == null
        ? null
        : controller.activityById(_activityId!);
    final selectedCategory = selectedActivity == null
        ? null
        : controller.categoryById(selectedActivity.categoryId);
    return Scaffold(
      body: TimiqPage(
        padding: const EdgeInsets.fromLTRB(
          TimiqSpace.md,
          TimiqSpace.sm,
          TimiqSpace.md,
          TimiqSpace.lg,
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                TimiqIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Zpět',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Nový záznam'
                        : 'Upravit záznam',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                if (widget.existing != null)
                  TimiqIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: TimiqColors.danger,
                    tooltip: 'Odstranit',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: TimiqSpace.lg),
            Expanded(
              child: ListView(
                children: <Widget>[
                  Text('AKTIVITA', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: TimiqSpace.xs),
                  TimiqCard(
                    onTap: _pickActivity,
                    child: Row(
                      children: <Widget>[
                        selectedActivity == null
                            ? ActivityGlyph.staticIcon(
                                icon: Icons.bolt_outlined,
                                color: context.timiq.primary,
                              )
                            : ActivityGlyph(
                                iconCodePoint: selectedActivity.iconCodePoint,
                                color: Color(
                                  selectedActivity.customColorValue ??
                                      selectedCategory?.colorValue ??
                                      context.timiq.primary.toARGB32(),
                                ),
                              ),
                        const SizedBox(width: TimiqSpace.sm),
                        Expanded(
                          child: Text(
                            selectedActivity?.name ?? 'Vyberte aktivitu',
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: selectedActivity == null
                                          ? context.timiq.muted
                                          : context.timiq.text,
                                    ),
                          ),
                        ),
                        Icon(Icons.expand_more, color: context.timiq.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: TimiqSpace.lg),
                  Text('DATUM A ČAS',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: TimiqSpace.xs),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _DateTimeColumn(
                          label: 'OD',
                          date: _startDate,
                          time: _start,
                          timeFormat: controller.settings.timeFormat,
                          onDateTap: () => _pickDate(start: true),
                          onTimeTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: TimiqSpace.sm),
                      Expanded(
                        child: _DateTimeColumn(
                          label: 'DO',
                          date: _endDate,
                          time: _end,
                          timeFormat: controller.settings.timeFormat,
                          onDateTap: () => _pickDate(start: false),
                          onTimeTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TimiqSpace.lg),
                  Text('POZNÁMKA',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: TimiqSpace.xs),
                  TimiqTextField(
                    controller: _note,
                    hint: 'Volitelná poznámka k záznamu',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: TimiqSpace.lg),
                  Text('ŠTÍTKY',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: TimiqSpace.xs),
                  if (controller.tags.isEmpty)
                    Text(
                      'Štítky lze vytvořit v sekci Já.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.timiq.muted),
                    )
                  else
                    Wrap(
                      spacing: TimiqSpace.xs,
                      runSpacing: TimiqSpace.xs,
                      children: controller.tags.map((tag) {
                        final selected = _tagIds.contains(tag.id);
                        return Material(
                          color: selected
                              ? context.timiq.primary.withValues(alpha: 0.16)
                              : context.timiq.elevated,
                          borderRadius:
                              BorderRadius.circular(TimiqRadius.pill),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(TimiqRadius.pill),
                            onTap: () => setState(() {
                              if (selected) {
                                _tagIds.remove(tag.id);
                              } else {
                                _tagIds.add(tag.id);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(TimiqRadius.pill),
                                border: Border.all(
                                  color: selected
                                      ? context.timiq.primary
                                      : context.timiq.border,
                                ),
                              ),
                              child: Text(
                                '#${tag.name}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: selected
                                          ? context.timiq.primaryGlow
                                          : context.timiq.muted,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                ],
              ),
            ),
            const SizedBox(height: TimiqSpace.md),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_rounded),
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  _saving ? 'Ukládám…' : 'Uložit záznam',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeColumn extends StatelessWidget {
  const _DateTimeColumn({
    required this.label,
    required this.date,
    required this.time,
    required this.timeFormat,
    required this.onDateTap,
    required this.onTimeTap,
  });

  final String label;
  final DateTime date;
  final TimeOfDay time;
  final TimiqTimeFormat timeFormat;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TimiqCard(
          onTap: onDateTap,
          padding: const EdgeInsets.all(TimiqSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('$label · DATUM',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                '${date.day}. ${date.month}. ${date.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: TimiqSpace.xs),
        TimiqCard(
          onTap: onTimeTap,
          padding: const EdgeInsets.all(TimiqSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('$label · ČAS',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                formatClock(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                  format: timeFormat,
                ),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
