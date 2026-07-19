import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'activity_picker.dart';
import 'widgets/timiq_components.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({required this.onOpenHistory, super.key});

  final VoidCallback onOpenHistory;

  Future<void> _chooseActivity(BuildContext context) async {
    final activity = await showActivityPicker(context);
    if (activity == null || !context.mounted) return;
    try {
      await TimiqScope.of(context, listen: false)
          .startOrSwitch(activity.activity.id);
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  Future<void> _start(
    BuildContext context,
    ActivityDetails activity,
  ) async {
    try {
      await TimiqScope.of(context, listen: false)
          .startOrSwitch(activity.activity.id);
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  Future<void> _stop(BuildContext context) async {
    try {
      await TimiqScope.of(context, listen: false).stop();
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    final active = controller.activeDetails;
    final deck = controller.favoriteActivities.isNotEmpty
        ? controller.favoriteActivities
        : controller.activityDeck.take(6).toList(growable: false);
    final breakdown = controller.todayCategoryTotals;
    return TimiqPage(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: TimiqScreenHeader(
              title: 'Dnes',
              subtitle: formatDateWithWeekday(controller.now),
              trailing: TimiqIconButton(
                icon: Icons.add_rounded,
                tooltip: 'Vybrat aktivitu',
                onPressed: () => _chooseActivity(context),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: TimiqSpace.lg)),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: TimeRing(
                  active: active,
                  color: active?.color ?? context.timiq.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: TimiqSpace.md),
              child: active == null
                  ? FilledButton.icon(
                      onPressed: () => _chooseActivity(context),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('Vybrat aktivitu'),
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: TimiqColors.danger,
                            ),
                            onPressed: () => _stop(context),
                            icon: const Icon(Icons.stop_rounded),
                            label: const Text('Zastavit'),
                          ),
                        ),
                        const SizedBox(width: TimiqSpace.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _chooseActivity(context),
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: const Text('Změnit'),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: TimiqSpace.xl)),
          SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    controller.favoriteActivities.isNotEmpty
                        ? 'Oblíbené'
                        : 'Nedávné a dostupné',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => _chooseActivity(context),
                  child: const Text('Všechny'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: TimiqSpace.xs)),
          if (deck.isEmpty)
            SliverToBoxAdapter(
              child: TimiqEmptyState(
                icon: Icons.bolt_outlined,
                title: 'Přidejte první aktivitu',
                message:
                    'Aktivity vytvoříte v sekci Já. Potom je odsud spustíte '
                    'jediným klepnutím.',
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 126,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: deck.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: TimiqSpace.sm),
                  itemBuilder: (context, index) {
                    final item = deck[index];
                    return SizedBox(
                      width: 166,
                      child: TimiqCard(
                        onTap: () => _start(context, item),
                        borderColor: active?.activity.id == item.activity.id
                            ? item.color
                            : context.timiq.border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                ActivityGlyph(
                                  iconCodePoint: item.activity.iconCodePoint,
                                  color: item.color,
                                  size: 38,
                                ),
                                const Spacer(),
                                if (item.activity.isFavorite)
                                  Icon(
                                    Icons.star_rounded,
                                    size: 17,
                                    color: item.color,
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              item.activity.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formatDuration(
                                item.trackedToday,
                                compact: true,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: item.color),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: TimiqSpace.xl)),
          SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Dnešní přehled',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('Timeline'),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: TimiqSpace.xs)),
          SliverToBoxAdapter(
            child: TimiqCard(
              onTap: onOpenHistory,
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'ZAZNAMENÁNO',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 5),
                            _LiveTodayTotal(
                              controller: controller,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: context.timiq.muted,
                      ),
                    ],
                  ),
                  if (breakdown.isEmpty) ...<Widget>[
                    const SizedBox(height: TimiqSpace.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'První spuštěná aktivita se tady okamžitě projeví.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.timiq.muted),
                      ),
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: TimiqSpace.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TimiqRadius.pill),
                      child: SizedBox(
                        height: 9,
                        child: Row(
                          children: breakdown.map((item) {
                            final share = controller.todayTotal.inMilliseconds ==
                                    0
                                ? 0.0
                                : item.duration.inMilliseconds /
                                    controller.todayTotal.inMilliseconds;
                            return Expanded(
                              flex: (share * 1000)
                                  .round()
                                  .clamp(1, 1000)
                                  .toInt(),
                              child: ColoredBox(color: item.category.color),
                            );
                          }).toList(growable: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: TimiqSpace.sm),
                    Wrap(
                      spacing: TimiqSpace.md,
                      runSpacing: TimiqSpace.xs,
                      children: breakdown.take(4).map((item) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: item.category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.category.name} '
                              '${formatDuration(item.duration, compact: true)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveTodayTotal extends StatefulWidget {
  const _LiveTodayTotal({required this.controller});

  final TimiqController controller;

  @override
  State<_LiveTodayTotal> createState() => _LiveTodayTotalState();
}

class _LiveTodayTotalState extends State<_LiveTodayTotal> {
  late final Stream<int> _ticks = Stream<int>.periodic(
    const Duration(seconds: 30),
    (value) => value,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticks,
      builder: (context, _) => Text(
        formatDuration(widget.controller.todayTotal),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
