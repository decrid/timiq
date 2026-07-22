import 'package:flutter/material.dart';

import '../../core/design/timiq_theme.dart';
import '../../core/utils/time_utils.dart';
import 'timiq_components.dart';

Future<T?> showTimiqChoice<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required String Function(T value) labelBuilder,
  T? selected,
  Widget Function(BuildContext context, T value)? leadingBuilder,
}) {
  return showTimiqSheet<T>(
    context: context,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TimiqSpace.lg),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
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
          const SizedBox(height: TimiqSpace.sm),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                TimiqSpace.md,
                0,
                TimiqSpace.md,
                TimiqSpace.lg,
              ),
              itemCount: values.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TimiqSpace.xs),
              itemBuilder: (context, index) {
                final value = values[index];
                final isSelected = value == selected;
                return TimiqCard(
                  onTap: () => Navigator.pop(context, value),
                  borderColor: isSelected
                      ? context.timiq.primary
                      : context.timiq.border,
                  color: isSelected
                      ? context.timiq.primary.withValues(alpha: 0.1)
                      : null,
                  child: Row(
                    children: <Widget>[
                      if (leadingBuilder != null) ...<Widget>[
                        leadingBuilder(context, value),
                        const SizedBox(width: TimiqSpace.sm),
                      ],
                      Expanded(
                        child: Text(
                          labelBuilder(value),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: context.timiq.primaryGlow,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<T?> showTimiqChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> values,
  required String Function(T value) labelBuilder,
  T? selected,
  Widget Function(BuildContext context, T value)? leadingBuilder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: TimiqSpace.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(TimiqSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  TimiqIconButton(
                    icon: Icons.close,
                    tooltip: 'Zavřít',
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: TimiqSpace.md),
              ...values.map(
                (value) {
                  final isSelected = value == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
                    child: TimiqCard(
                      onTap: () => Navigator.pop(dialogContext, value),
                      borderColor: isSelected
                          ? context.timiq.primary
                          : context.timiq.border,
                      color: isSelected
                          ? context.timiq.primary.withValues(alpha: 0.1)
                          : null,
                      child: Row(
                        children: <Widget>[
                          if (leadingBuilder != null) ...<Widget>[
                            leadingBuilder(context, value),
                            const SizedBox(width: TimiqSpace.sm),
                          ],
                          Expanded(
                            child: Text(
                              labelBuilder(value),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: context.timiq.primaryGlow,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<DateTime?> showTimiqDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) => _TimiqCalendarDialog(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

class _TimiqCalendarDialog extends StatefulWidget {
  const _TimiqCalendarDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_TimiqCalendarDialog> createState() => _TimiqCalendarDialogState();
}

class _TimiqCalendarDialogState extends State<_TimiqCalendarDialog> {
  late DateTime _selected = startOfDay(widget.initialDate);
  late DateTime _month = DateTime(_selected.year, _selected.month);

  void _moveMonth(int offset) {
    final target = DateTime(_month.year, _month.month + offset);
    if (target.isBefore(
          DateTime(widget.firstDate.year, widget.firstDate.month),
        ) ||
        target.isAfter(
          DateTime(widget.lastDate.year, widget.lastDate.month),
        )) {
      return;
    }
    setState(() => _month = target);
  }

  @override
  Widget build(BuildContext context) {
    final monthStartOffset = _month.weekday - DateTime.monday;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((monthStartOffset + daysInMonth + 6) ~/ 7) * 7;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: TimiqSpace.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(TimiqSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  TimiqIconButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Předchozí měsíc',
                    onPressed: () => _moveMonth(-1),
                  ),
                  Expanded(
                    child: Text(
                      formatDate(_month),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TimiqIconButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Další měsíc',
                    onPressed: () => _moveMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: TimiqSpace.md),
              const Row(
                children: <Widget>[
                  _Weekday('PO'),
                  _Weekday('ÚT'),
                  _Weekday('ST'),
                  _Weekday('ČT'),
                  _Weekday('PÁ'),
                  _Weekday('SO'),
                  _Weekday('NE'),
                ],
              ),
              const SizedBox(height: TimiqSpace.xs),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: cells,
                itemBuilder: (context, index) {
                  final day = index - monthStartOffset + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final date = DateTime(_month.year, _month.month, day);
                  final enabled = !date.isBefore(startOfDay(widget.firstDate)) &&
                      !date.isAfter(startOfDay(widget.lastDate));
                  final selected = date == _selected;
                  final today = date == startOfDay(DateTime.now());
                  return Material(
                    color: selected
                        ? context.timiq.primary
                        : today
                            ? context.timiq.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(TimiqRadius.small),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TimiqRadius.small),
                      onTap: enabled
                          ? () => setState(() => _selected = date)
                          : null,
                      child: Center(
                        child: Text(
                          '$day',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: enabled
                                        ? selected
                                            ? Colors.white
                                            : context.timiq.text
                                        : context.timiq.muted
                                            .withValues(alpha: 0.35),
                                    fontWeight: selected || today
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: TimiqSpace.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Zrušit'),
                    ),
                  ),
                  const SizedBox(width: TimiqSpace.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Vybrat'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

Future<TimeOfDay?> showTimiqTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  required bool use24HourFormat,
}) {
  return showTimiqSheet<TimeOfDay>(
    context: context,
    builder: (context) => _TimiqClockPicker(
      initialTime: initialTime,
      use24HourFormat: use24HourFormat,
    ),
  );
}

class _TimiqClockPicker extends StatefulWidget {
  const _TimiqClockPicker({
    required this.initialTime,
    required this.use24HourFormat,
  });

  final TimeOfDay initialTime;
  final bool use24HourFormat;

  @override
  State<_TimiqClockPicker> createState() => _TimiqClockPickerState();
}

class _TimiqClockPickerState extends State<_TimiqClockPicker> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;
  late bool _isPm = widget.initialTime.hour >= 12;
  late int _displayHour = widget.initialTime.hourOfPeriod == 0
      ? 12
      : widget.initialTime.hourOfPeriod;
  late final FixedExtentScrollController _hours =
      FixedExtentScrollController(
    initialItem: widget.use24HourFormat ? _hour : _displayHour - 1,
  );
  late final FixedExtentScrollController _minutes =
      FixedExtentScrollController(initialItem: _minute);
  late final FixedExtentScrollController _period =
      FixedExtentScrollController(initialItem: _isPm ? 1 : 0);

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _period.dispose();
    super.dispose();
  }

  void _setDisplayHour(int value) {
    _displayHour = value;
    _hour = _toTwentyFourHour(_displayHour, _isPm);
  }

  void _setPeriod(bool isPm) {
    _isPm = isPm;
    _hour = _toTwentyFourHour(_displayHour, _isPm);
  }

  int _toTwentyFourHour(int hour, bool isPm) {
    if (isPm) return hour == 12 ? 12 : hour + 12;
    return hour == 12 ? 0 : hour;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TimiqSpace.lg,
        0,
        TimiqSpace.lg,
        TimiqSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SheetHandle(),
          Text('Vyberte čas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: TimiqSpace.lg),
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.timiq.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TimiqRadius.medium),
                    border: Border.all(
                      color: context.timiq.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _hours,
                        itemExtent: 54,
                        diameterRatio: 1.4,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: widget.use24HourFormat
                            ? (value) => _hour = value
                            : (value) => _setDisplayHour(value + 1),
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: widget.use24HourFormat ? 24 : 12,
                          builder: (context, index) => Center(
                            child: Text(
                              widget.use24HourFormat
                                  ? twoDigits(index)
                                  : '${index + 1}',
                              style:
                                  Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(':', style: Theme.of(context).textTheme.headlineMedium),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        controller: _minutes,
                        itemExtent: 54,
                        diameterRatio: 1.4,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (value) => _minute = value,
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 60,
                          builder: (context, index) => Center(
                            child: Text(
                              twoDigits(index),
                              style:
                                  Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!widget.use24HourFormat) ...<Widget>[
                      const SizedBox(width: TimiqSpace.xs),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _period,
                          itemExtent: 54,
                          diameterRatio: 1.4,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (value) =>
                              _setPeriod(value == 1),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 2,
                            builder: (context, index) => Center(
                              child: Text(
                                index == 0 ? 'AM' : 'PM',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: TimiqSpace.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zrušit'),
                ),
              ),
              const SizedBox(width: TimiqSpace.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    TimeOfDay(hour: _hour, minute: _minute),
                  ),
                  child: const Text('Vybrat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
