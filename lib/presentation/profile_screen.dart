import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../domain/models.dart';
import 'manage_screens.dart';
import 'widgets/timiq_components.dart';
import 'widgets/timiq_pickers.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _appearance(BuildContext context) async {
    final controller = TimiqScope.of(context, listen: false);
    final mode = await showTimiqChoice<TimiqThemeMode>(
      context: context,
      title: 'Vzhled TimIQ',
      values: TimiqThemeMode.values,
      selected: controller.settings.themeMode,
      labelBuilder: (value) {
        switch (value) {
          case TimiqThemeMode.dark:
            return 'Tmavý';
          case TimiqThemeMode.light:
            return 'Světlý';
          case TimiqThemeMode.system:
            return 'Podle systému';
        }
      },
      leadingBuilder: (context, value) => ActivityGlyph(
        iconCodePoint: switch (value) {
          TimiqThemeMode.dark => Icons.dark_mode_outlined.codePoint,
          TimiqThemeMode.light => Icons.light_mode_outlined.codePoint,
          TimiqThemeMode.system => Icons.settings_brightness_outlined.codePoint,
        },
        color: context.timiq.primaryGlow,
        size: 40,
      ),
    );
    if (mode != null) {
      try {
        await controller.updateSettings(
          controller.settings.copyWith(themeMode: mode),
        );
      } catch (error) {
        if (context.mounted) {
          showTimiqMessage(context, timiqErrorMessage(error), isError: true);
        }
      }
    }
  }

  Future<void> _firstDay(BuildContext context) async {
    final controller = TimiqScope.of(context, listen: false);
    final value = await showTimiqChoice<FirstDayOfWeek>(
      context: context,
      title: 'První den týdne',
      values: FirstDayOfWeek.values,
      selected: controller.settings.firstDayOfWeek,
      labelBuilder: (value) =>
          value == FirstDayOfWeek.monday ? 'Pondělí' : 'Neděle',
    );
    if (value != null) {
      try {
        await controller.updateSettings(
          controller.settings.copyWith(firstDayOfWeek: value),
        );
      } catch (error) {
        if (context.mounted) {
          showTimiqMessage(context, timiqErrorMessage(error), isError: true);
        }
      }
    }
  }

  Future<void> _timeFormat(BuildContext context) async {
    final controller = TimiqScope.of(context, listen: false);
    final value = await showTimiqChoice<TimiqTimeFormat>(
      context: context,
      title: 'Formát času',
      values: TimiqTimeFormat.values,
      selected: controller.settings.timeFormat,
      labelBuilder: (value) => value == TimiqTimeFormat.twentyFourHour
          ? '24hodinový · 18:30'
          : '12hodinový · 6:30 PM',
    );
    if (value != null) {
      try {
        await controller.updateSettings(
          controller.settings.copyWith(timeFormat: value),
        );
      } catch (error) {
        if (context.mounted) {
          showTimiqMessage(context, timiqErrorMessage(error), isError: true);
        }
      }
    }
  }

  Future<void> _export(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    return TimiqPage(
      child: ListView(
        children: <Widget>[
          const TimiqScreenHeader(
            title: 'Já',
            subtitle: 'Vaše data, vaše nastavení',
          ),
          const SizedBox(height: TimiqSpace.lg),
          TimiqCard(
            color: context.timiq.primary.withValues(alpha: 0.1),
            borderColor: context.timiq.primary.withValues(alpha: 0.34),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[
                        TimiqColors.primary,
                        TimiqColors.primaryGlow,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(TimiqRadius.medium),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: TimiqSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'TimIQ 1.0',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${controller.activeCategories.length} kategorií · '
                        '${controller.activeActivities.length} aktivit',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.timiq.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TimiqSpace.xl),
          const _SectionTitle('ORGANIZACE'),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Kategorie',
            subtitle: 'Barvy, ikony, pořadí a archiv',
            onTap: () => _open(context, const CategoryManagementScreen()),
          ),
          _SettingsTile(
            icon: Icons.bolt_outlined,
            title: 'Aktivity',
            subtitle: 'Oblíbené, kategorie a archiv',
            onTap: () => _open(context, const ActivityManagementScreen()),
          ),
          _SettingsTile(
            icon: Icons.tag_rounded,
            title: 'Štítky',
            subtitle: 'Volitelný kontext časových záznamů',
            onTap: () => _open(context, const TagManagementScreen()),
          ),
          const SizedBox(height: TimiqSpace.lg),
          const _SectionTitle('PREFERENCE'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Vzhled',
            subtitle: switch (controller.settings.themeMode) {
              TimiqThemeMode.dark => 'Tmavý',
              TimiqThemeMode.light => 'Světlý',
              TimiqThemeMode.system => 'Podle systému',
            },
            onTap: () => _appearance(context),
          ),
          _SettingsTile(
            icon: Icons.calendar_view_week_outlined,
            title: 'První den týdne',
            subtitle: controller.settings.firstDayOfWeek ==
                    FirstDayOfWeek.monday
                ? 'Pondělí'
                : 'Neděle',
            onTap: () => _firstDay(context),
          ),
          _SettingsTile(
            icon: Icons.schedule_outlined,
            title: 'Formát času',
            subtitle: controller.settings.timeFormat ==
                    TimiqTimeFormat.twentyFourHour
                ? '24hodinový'
                : '12hodinový',
            onTap: () => _timeFormat(context),
          ),
          const SizedBox(height: TimiqSpace.lg),
          const _SectionTitle('DATA A ZÁLOHA'),
          _SettingsTile(
            icon: Icons.table_view_outlined,
            title: 'Export záznamů do CSV',
            subtitle: 'Přenosný přehled všech časových záznamů',
            onTap: () => _export(context, controller.exportCsv),
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Kompletní JSON záloha',
            subtitle: 'Kategorie, aktivity, záznamy, štítky a nastavení',
            onTap: () => _export(context, controller.exportJsonBackup),
          ),
          const SizedBox(height: TimiqSpace.lg),
          const _SectionTitle('O APLIKACI'),
          const TimiqCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'TimIQ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: TimiqSpace.xs),
                Text(
                  'Osobní offline chronograf. Data jsou uložena lokálně '
                  'v zařízení, bez účtu, cloudu, reklam a sledování polohy.',
                ),
                SizedBox(height: TimiqSpace.sm),
                Text('Verze 1.0.0 (1)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TimiqSpace.xs,
        0,
        TimiqSpace.xs,
        TimiqSpace.xs,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
      child: TimiqCard(
        onTap: onTap,
        child: Row(
          children: <Widget>[
            ActivityGlyph(
              iconCodePoint: icon.codePoint,
              color: context.timiq.primaryGlow,
            ),
            const SizedBox(width: TimiqSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.timiq.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.timiq.muted),
          ],
        ),
      ),
    );
  }
}
