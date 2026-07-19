import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'widgets/timiq_components.dart';
import 'widgets/timiq_pickers.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod _period = StatisticsPeriod.week;
  DateTime _anchor = DateTime.now();
  DateRange? _custom;
  String? _requestKey;
  Future<StatisticsSnapshot>? _snapshotFuture;

  Future<StatisticsSnapshot> _snapshot(TimiqController controller) {
    final key = <Object?>[
      controller.revision,
      _period,
      _anchor.year,
      _anchor.month,
      _anchor.day,
      _custom?.start.millisecondsSinceEpoch,
      _custom?.end.millisecondsSinceEpoch,
      controller.settings.firstDayOfWeek,
    ].join(':');
    if (_snapshotFuture == null || key != _requestKey) {
      _requestKey = key;
      _snapshotFuture =
          controller.statistics(_period, _anchor, custom: _custom);
    }
    return _snapshotFuture!;
  }

  String _periodLabel(StatisticsPeriod value) {
    switch (value) {
      case StatisticsPeriod.day:
        return 'Den';
      case StatisticsPeriod.week:
        return 'Týden';
      case StatisticsPeriod.month:
        return 'Měsíc';
      case StatisticsPeriod.year:
        return 'Rok';
      case StatisticsPeriod.custom:
        return 'Vlastní';
    }
  }

  void _move(int direction) {
    setState(() {
      switch (_period) {
        case StatisticsPeriod.day:
          _anchor = addCalendarDays(_anchor, direction);
          break;
        case StatisticsPeriod.week:
          _anchor = addCalendarDays(_anchor, 7 * direction);
          break;
        case StatisticsPeriod.month:
          _anchor = DateTime(_anchor.year, _anchor.month + direction);
          break;
        case StatisticsPeriod.year:
          _anchor =
              DateTime(_anchor.year + direction, _anchor.month, _anchor.day);
          break;
        case StatisticsPeriod.custom:
          final range = _custom;
          if (range != null) {
            final shift = calendarDayCount(range) * direction;
            _custom = shiftCalendarRange(range, shift);
          }
          break;
      }
      _requestKey = null;
    });
  }

  Future<void> _selectCustomRange() async {
    final now = DateTime.now();
    final initialStart =
        _custom?.start ?? addCalendarDays(startOfDay(now), -6);
    final start = await showTimiqDatePicker(
      context: context,
      initialDate: initialStart,
      lastDate: now,
    );
    if (start == null || !mounted) return;
    final end = await showTimiqDatePicker(
      context: context,
      initialDate: _custom == null ? now : addCalendarDays(_custom!.end, -1),
      firstDate: start,
      lastDate: now,
    );
    if (end == null || !mounted) return;
    setState(() {
      _custom = DateRange(startOfDay(start), endOfDay(end));
      _period = StatisticsPeriod.custom;
      _anchor = start;
      _requestKey = null;
    });
  }

  void _showCategory(
    BuildContext context,
    CategoryTotal category,
    StatisticsSnapshot snapshot,
  ) {
    showTimiqSheet<void>(
      context: context,
      builder: (context) => _CategoryDetail(
        category: category,
        snapshot: snapshot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    return TimiqPage(
      child: Column(
        children: <Widget>[
          TimiqScreenHeader(
            title: 'Statistiky',
            subtitle: 'Jak se mění váš skutečný čas',
            trailing: TimiqIconButton(
              icon: Icons.date_range_outlined,
              tooltip: 'Vlastní období',
              onPressed: _selectCustomRange,
            ),
          ),
          const SizedBox(height: TimiqSpace.lg),
          TimiqSegmented<StatisticsPeriod>(
            values: StatisticsPeriod.values,
            selected: _period,
            labelBuilder: _periodLabel,
            onChanged: (value) {
              if (value == StatisticsPeriod.custom && _custom == null) {
                _selectCustomRange();
                return;
              }
              setState(() {
                _period = value;
                _requestKey = null;
              });
            },
          ),
          const SizedBox(height: TimiqSpace.sm),
          FutureBuilder<StatisticsSnapshot>(
            future: _snapshot(controller),
            builder: (context, snapshot) {
              final value = snapshot.data;
              return Expanded(
                child: Column(
                  children: <Widget>[
                    TimiqCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TimiqSpace.xs,
                        vertical: TimiqSpace.xs,
                      ),
                      child: Row(
                        children: <Widget>[
                          TimiqIconButton(
                            icon: Icons.chevron_left,
                            tooltip: 'Předchozí období',
                            onPressed: () => _move(-1),
                          ),
                          Expanded(
                            child: Text(
                              value == null
                                  ? 'Načítám období…'
                                  : formatRange(value.range),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TimiqIconButton(
                            icon: Icons.chevron_right,
                            tooltip: 'Další období',
                            onPressed: value != null &&
                                    !value.range.end
                                        .isAfter(startOfDay(DateTime.now()))
                                ? () => _move(1)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TimiqSpace.md),
                    Expanded(
                      child: _StatisticsBody(
                        snapshot: snapshot,
                        onCategory: (category) =>
                            _showCategory(context, category, snapshot.data!),
                        onRetry: () => setState(() => _requestKey = null),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({
    required this.snapshot,
    required this.onCategory,
    required this.onRetry,
  });

  final AsyncSnapshot<StatisticsSnapshot> snapshot;
  final ValueChanged<CategoryTotal> onCategory;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return TimiqEmptyState(
        icon: Icons.shield_outlined,
        title: 'Statistiky se nepodařilo spočítat',
        message: 'Vaše záznamy jsme nezměnili. Zkuste výpočet zopakovat.',
        actionLabel: 'Zkusit znovu',
        onAction: onRetry,
      );
    }
    final data = snapshot.data;
    if (data == null) {
      return Center(
        child: Icon(
          Icons.donut_large_outlined,
          color: context.timiq.primaryGlow,
          size: 36,
        ),
      );
    }
    if (data.total == Duration.zero) {
      return TimiqEmptyState(
        icon: Icons.donut_large_outlined,
        title: 'V tomto období nejsou data',
        message:
            'Jakmile změříte nebo ručně doplníte čas, objeví se rozložení '
            'kategorií, aktivity i trendy.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: TimiqSpace.lg),
      children: <Widget>[
        TimiqCard(
          padding: const EdgeInsets.all(TimiqSpace.lg),
          child: Column(
            children: <Widget>[
              TimeWheel(
                items: data.categories,
                total: data.total,
                onSelected: onCategory,
              ),
              const SizedBox(height: TimiqSpace.lg),
              ...data.categories.take(6).map(
                    (item) => _CategoryLine(
                      item: item,
                      total: data.total,
                      onTap: () => onCategory(item),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: TimiqSpace.lg),
        Text('Trend v čase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: TimiqSpace.xs),
        TimiqCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'ZAZNAMENANÝ ČAS',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: TimiqSpace.md),
              SizedBox(
                height: 104,
                child: _TrendBars(
                  values: data.dailyTotals.values.toList(growable: false),
                  color: context.timiq.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TimiqSpace.lg),
        Text(
          'Největší aktivity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: TimiqSpace.xs),
        ...data.activities.take(8).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
                child: TimiqCard(
                  child: Row(
                    children: <Widget>[
                      ActivityGlyph(
                        iconCodePoint: item.activity.iconCodePoint,
                        color: item.color,
                      ),
                      const SizedBox(width: TimiqSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.activity.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              item.category.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: item.color),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatDuration(item.duration, compact: true),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: TimiqSpace.lg),
        Text(
          'Oproti minulému období',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: TimiqSpace.xs),
        if (data.trends.every(
          (trend) =>
              trend.previous == Duration.zero &&
              trend.current == Duration.zero,
        ))
          TimiqCard(
            child: Text(
              'Pro srovnání zatím není dostatek dat.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.timiq.muted),
            ),
          )
        else
          ...data.trends.take(6).map((trend) => _TrendLine(trend: trend)),
      ],
    );
  }
}

class _CategoryLine extends StatelessWidget {
  const _CategoryLine({
    required this.item,
    required this.total,
    required this.onTap,
  });

  final CategoryTotal item;
  final Duration total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = total.inMilliseconds == 0
        ? 0.0
        : item.duration.inMilliseconds / total.inMilliseconds;
    return InkWell(
      borderRadius: BorderRadius.circular(TimiqRadius.small),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TimiqSpace.xs),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: TimiqSpace.xs),
                Expanded(
                  child: Text(
                    item.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${(share * 100).round()} % · '
                  '${formatDuration(item.duration, compact: true)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            ProportionBar(value: share, color: item.category.color),
          ],
        ),
      ),
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.trend});

  final TrendValue trend;

  @override
  Widget build(BuildContext context) {
    final delta = trend.current - trend.previous;
    final rising = delta.inSeconds >= 0;
    final color = rising ? TimiqColors.success : TimiqColors.danger;
    final percentage = trend.percentChange;
    final label = trend.previous == Duration.zero
        ? 'nově ${formatDuration(trend.current, compact: true)}'
        : '${rising ? '↑' : '↓'} '
            '${formatDuration(delta.abs(), compact: true)}'
            '${percentage == null ? '' : ' · ${percentage.abs().round()} %'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
      child: TimiqCard(
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 32,
              decoration: BoxDecoration(
                color: trend.category.color,
                borderRadius: BorderRadius.circular(TimiqRadius.pill),
              ),
            ),
            const SizedBox(width: TimiqSpace.sm),
            Expanded(
              child: Text(
                trend.category.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.category,
    required this.snapshot,
  });

  final CategoryTotal category;
  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final totalShare = snapshot.total.inMilliseconds == 0
        ? 0.0
        : category.duration.inMilliseconds / snapshot.total.inMilliseconds;
    final series = snapshot.dailyCategoryTotals.values
        .map(
          (totals) => totals[category.category.id] ?? Duration.zero,
        )
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: <Widget>[
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TimiqSpace.lg),
            child: Row(
              children: <Widget>[
                ActivityGlyph(
                  iconCodePoint: category.category.iconCodePoint,
                  color: category.category.color,
                  size: 50,
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category.category.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        '${formatDuration(category.duration)} · '
                        '${(totalShare * 100).round()} % celku',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: category.category.color),
                      ),
                    ],
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
          const SizedBox(height: TimiqSpace.lg),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TimiqSpace.lg,
                0,
                TimiqSpace.lg,
                TimiqSpace.lg,
              ),
              children: <Widget>[
                TimiqCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'TREND KATEGORIE',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: TimiqSpace.sm),
                      SizedBox(
                        height: 110,
                        child: _TrendBars(
                          values: series,
                          color: category.category.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TimiqSpace.lg),
                Text(
                  'Aktivity v kategorii',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TimiqSpace.xs),
                ...category.activities.map((activity) {
                  final share = category.duration.inMilliseconds == 0
                      ? 0.0
                      : activity.duration.inMilliseconds /
                          category.duration.inMilliseconds;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
                    child: TimiqCard(
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ActivityGlyph(
                                iconCodePoint:
                                    activity.activity.iconCodePoint,
                                color: activity.color,
                                size: 40,
                              ),
                              const SizedBox(width: TimiqSpace.sm),
                              Expanded(
                                child: Text(
                                  activity.activity.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Text(
                                formatDuration(
                                  activity.duration,
                                  compact: true,
                                ),
                                style:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: TimiqSpace.sm),
                          ProportionBar(
                            value: share,
                            color: activity.color,
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(share * 100).round()} % kategorie',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  const _TrendBars({required this.values, required this.color});

  final List<Duration> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compactValues = _compact(values);
    final maximum = compactValues.fold<int>(
      0,
      (maxValue, item) => math.max(maxValue, item.inSeconds),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: compactValues.map((value) {
        final fraction =
            maximum == 0 ? 0.03 : value.inSeconds / maximum;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Tooltip(
              message: formatDuration(value, compact: true),
              child: AnimatedFractionallySizedBox(
                duration: TimiqMotion.standard,
                heightFactor: fraction.clamp(0.03, 1.0).toDouble(),
                alignment: Alignment.bottomCenter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.78),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  List<Duration> _compact(List<Duration> source) {
    if (source.length <= 31) return source;
    final bucketSize = (source.length / 31).ceil();
    final result = <Duration>[];
    for (var index = 0; index < source.length; index += bucketSize) {
      var total = Duration.zero;
      final end = math.min(index + bucketSize, source.length);
      for (var item = index; item < end; item++) {
        total += source[item];
      }
      result.add(total);
    }
    return result;
  }
}
