import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'statistics_screen.dart';
import 'today_screen.dart';
import 'widgets/timiq_components.dart';

class TimiqShell extends StatefulWidget {
  const TimiqShell({super.key});

  @override
  State<TimiqShell> createState() => _TimiqShellState();
}

class _TimiqShellState extends State<TimiqShell>
    with WidgetsBindingObserver {
  int _index = 0;

  late final List<Widget> _screens = <Widget>[
    TodayScreen(onOpenHistory: () => setState(() => _index = 1)),
    const HistoryScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TimiqScope.of(context, listen: false).refreshAfterResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          IndexedStack(index: _index, children: _screens),
          if (controller.isBusy)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 16,
              child: Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.timiq.elevated,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.timiq.border),
                ),
                child: const TimiqLoader(size: 18),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _TimiqNavigation(
        index: _index,
        onChanged: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _TimiqNavigation extends StatelessWidget {
  const _TimiqNavigation({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const items = <({IconData icon, String label})>[
    (icon: Icons.bolt_rounded, label: 'Dnes'),
    (icon: Icons.view_timeline_outlined, label: 'Historie'),
    (icon: Icons.donut_large_outlined, label: 'Statistiky'),
    (icon: Icons.settings_outlined, label: 'Nastavení'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        TimiqSpace.md,
        0,
        TimiqSpace.md,
        TimiqSpace.sm,
      ),
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.timiq.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(TimiqRadius.large),
          border: Border.all(color: context.timiq.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (itemIndex) {
            final item = items[itemIndex];
            final selected = itemIndex == index;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: item.label,
                child: Material(
                  color: selected
                      ? context.timiq.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(TimiqRadius.medium),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TimiqRadius.medium),
                    onTap: () => onChanged(itemIndex),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected
                              ? context.timiq.primaryGlow
                              : context.timiq.muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: selected
                                        ? context.timiq.primaryGlow
                                        : context.timiq.muted,
                                    letterSpacing: 0.2,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
