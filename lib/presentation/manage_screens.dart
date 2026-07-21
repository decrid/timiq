import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'entity_editors.dart';
import 'widgets/timiq_components.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _showArchived = false;

  Future<void> _edit([TimiqCategory? category]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CategoryEditor(category: category),
      ),
    );
  }

  Future<void> _archive(TimiqCategory category) async {
    final archive = !category.isArchived;
    if (archive) {
      final confirmed = await showTimiqConfirm(
        context: context,
        title: 'Archivovat kategorii?',
        message:
            'Skryjí se i její aktivity. Historické záznamy a statistiky '
            'zůstanou zachované.',
        confirmLabel: 'Archivovat',
      );
      if (!confirmed || !mounted) return;
    }
    try {
      await TimiqScope.of(context, listen: false)
          .archiveCategory(category, archive);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    final items = controller.categories
        .where((item) => _showArchived || !item.isArchived)
        .toList(growable: false);
    return _ManagementScaffold(
      title: 'Kategorie',
      subtitle: 'Barvy, ikony a pořadí',
      onAdd: () => _edit(),
      trailing: _ArchiveToggle(
        value: _showArchived,
        onChanged: (value) => setState(() => _showArchived = value),
      ),
      child: items.isEmpty
          ? TimiqEmptyState(
              icon: Icons.category_outlined,
              title: _showArchived
                  ? 'Žádné archivované kategorie'
                  : 'Vytvořte první kategorii',
              message:
                  'Kategorie dávají aktivitám barvu a tvoří hlavní rozdělení '
                  've statistikách.',
              actionLabel: _showArchived ? null : 'Přidat kategorii',
              onAction: _showArchived ? null : () => _edit(),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: TimiqSpace.lg),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorderItem: (oldIndex, newIndex) async {
                if (_showArchived) return;
                final reordered = [...items];
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await controller.reorderCategoryIds(
                  reordered.map((item) => item.id).toList(growable: false),
                );
              },
              itemBuilder: (context, index) {
                final item = items[index];
                final activityCount = controller.activities
                    .where((activity) => activity.categoryId == item.id)
                    .length;
                return Padding(
                  key: ValueKey<String>(item.id),
                  padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
                  child: Opacity(
                    opacity: item.isArchived ? 0.58 : 1,
                    child: TimiqCard(
                      onTap: () => _edit(item),
                      child: Row(
                        children: <Widget>[
                          ActivityGlyph(
                            iconCodePoint: item.iconCodePoint,
                            color: item.color,
                          ),
                          const SizedBox(width: TimiqSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  item.isArchived
                                      ? 'Archivováno'
                                      : '$activityCount aktivit',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: context.timiq.muted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip:
                                item.isArchived ? 'Obnovit' : 'Archivovat',
                            onPressed: () => _archive(item),
                            icon: Icon(
                              item.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              color: context.timiq.muted,
                            ),
                          ),
                          if (!_showArchived)
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(TimiqSpace.xs),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: context.timiq.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ActivityManagementScreen extends StatefulWidget {
  const ActivityManagementScreen({super.key});

  @override
  State<ActivityManagementScreen> createState() =>
      _ActivityManagementScreenState();
}

class _ActivityManagementScreenState extends State<ActivityManagementScreen> {
  bool _showArchived = false;

  Future<void> _edit([TimiqActivity? activity]) async {
    final categories =
        TimiqScope.of(context, listen: false).activeCategories;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ActivityEditor(
          activity: activity,
          initialCategoryId:
              activity == null && categories.isNotEmpty
                  ? categories.first.id
                  : null,
        ),
      ),
    );
  }

  Future<void> _archive(TimiqActivity activity) async {
    final archive = !activity.isArchived;
    if (archive) {
      final confirmed = await showTimiqConfirm(
        context: context,
        title: 'Archivovat aktivitu?',
        message:
            'Aktivita zmizí z výběru, ale všechny její historické záznamy '
            'zůstanou zachované.',
        confirmLabel: 'Archivovat',
      );
      if (!confirmed || !mounted) return;
    }
    try {
      await TimiqScope.of(context, listen: false)
          .archiveActivity(activity, archive);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    final items = controller.activities
        .where(
          (item) =>
              _showArchived ||
              (!item.isArchived &&
                  controller.categoryById(item.categoryId)?.isArchived ==
                      false),
        )
        .toList(growable: false);
    return _ManagementScaffold(
      title: 'Aktivity',
      subtitle: 'Rychlé volby pro měření',
      onAdd: () => _edit(),
      trailing: _ArchiveToggle(
        value: _showArchived,
        onChanged: (value) => setState(() => _showArchived = value),
      ),
      child: items.isEmpty
          ? TimiqEmptyState(
              icon: Icons.bolt_outlined,
              title: _showArchived
                  ? 'Žádné archivované aktivity'
                  : 'Vytvořte první aktivitu',
              message: controller.activeCategories.isEmpty
                  ? 'Nejdříve vytvořte alespoň jednu kategorii.'
                  : 'Aktivitu potom spustíte jediným klepnutím.',
              actionLabel: _showArchived || controller.activeCategories.isEmpty
                  ? null
                  : 'Přidat aktivitu',
              onAction: _showArchived || controller.activeCategories.isEmpty
                  ? null
                  : () => _edit(),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: TimiqSpace.lg),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorderItem: (oldIndex, newIndex) async {
                if (_showArchived) return;
                final reordered = [...items];
                final moved = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, moved);
                await controller.reorderActivityIds(
                  reordered.map((item) => item.id).toList(growable: false),
                );
              },
              itemBuilder: (context, index) {
                final item = items[index];
                final category = controller.categoryById(item.categoryId);
                final color = Color(
                  item.customColorValue ??
                      category?.colorValue ??
                      context.timiq.primary.toARGB32(),
                );
                return Padding(
                  key: ValueKey<String>(item.id),
                  padding: const EdgeInsets.only(bottom: TimiqSpace.xs),
                  child: Opacity(
                    opacity: item.isArchived ? 0.58 : 1,
                    child: TimiqCard(
                      onTap: () => _edit(item),
                      child: Row(
                        children: <Widget>[
                          ActivityGlyph(
                            iconCodePoint: item.iconCodePoint,
                            color: color,
                          ),
                          const SizedBox(width: TimiqSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  item.isArchived
                                      ? 'Archivováno'
                                      : category?.name ??
                                          'Archivovaná kategorie',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: color),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: item.isFavorite
                                ? 'Odebrat z oblíbených'
                                : 'Přidat do oblíbených',
                            onPressed: item.isArchived
                                ? null
                                : () => controller.toggleFavorite(item),
                            icon: Icon(
                              item.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: item.isFavorite
                                  ? TimiqColors.warning
                                  : context.timiq.muted,
                            ),
                          ),
                          IconButton(
                            tooltip:
                                item.isArchived ? 'Obnovit' : 'Archivovat',
                            onPressed: () => _archive(item),
                            icon: Icon(
                              item.isArchived
                                  ? Icons.unarchive_outlined
                                  : Icons.archive_outlined,
                              color: context.timiq.muted,
                            ),
                          ),
                          if (!_showArchived)
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(TimiqSpace.xs),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: context.timiq.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class TagManagementScreen extends StatelessWidget {
  const TagManagementScreen({super.key});

  Future<void> _edit(BuildContext context, [TimiqTag? tag]) async {
    final input = TextEditingController(text: tag?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: EdgeInsets.only(
            left: TimiqSpace.lg,
            right: TimiqSpace.lg,
            top: TimiqSpace.lg,
            bottom: MediaQuery.viewInsetsOf(dialogContext).bottom +
                TimiqSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                tag == null ? 'Nový štítek' : 'Upravit štítek',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TimiqSpace.md),
              TimiqTextField(
                controller: input,
                hint: 'Například vývoj',
                prefixIcon: Icons.tag_rounded,
                autofocus: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: TimiqSpace.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Zrušit'),
                    ),
                  ),
                  const SizedBox(width: TimiqSpace.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, input.text),
                      child: const Text('Uložit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    input.dispose();
    if (result == null || !context.mounted) return;
    final controller = TimiqScope.of(context, listen: false);
    try {
      await controller.saveTag(
        TimiqTag(
          id: tag?.id ?? newId('tag'),
          name: result,
          createdAt: tag?.createdAt ?? controller.now,
        ),
      );
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  Future<void> _delete(BuildContext context, TimiqTag tag) async {
    final confirmed = await showTimiqConfirm(
      context: context,
      title: 'Odstranit štítek?',
      message:
          'Štítek #${tag.name} se odebere i z historických záznamů. Samotné '
          'časové záznamy zůstanou beze změny.',
      confirmLabel: 'Odstranit',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await TimiqScope.of(context, listen: false).deleteTag(tag.id);
    } catch (error) {
      if (context.mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    return _ManagementScaffold(
      title: 'Štítky',
      subtitle: 'Volitelný kontext záznamů',
      onAdd: () => _edit(context),
      child: controller.tags.isEmpty
          ? TimiqEmptyState(
              icon: Icons.tag_rounded,
              title: 'Zatím nemáte štítky',
              message:
                  'Štítky jsou volitelné. Pomohou rozlišit třeba vývoj, '
                  'support nebo konkrétní projekt.',
              actionLabel: 'Přidat štítek',
              onAction: () => _edit(context),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: TimiqSpace.lg),
              itemCount: controller.tags.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: TimiqSpace.xs),
              itemBuilder: (context, index) {
                final tag = controller.tags[index];
                return TimiqCard(
                  onTap: () => _edit(context, tag),
                  child: Row(
                    children: <Widget>[
                      ActivityGlyph.staticIcon(
                        icon: Icons.tag_rounded,
                        color: context.timiq.primaryGlow,
                      ),
                      const SizedBox(width: TimiqSpace.sm),
                      Expanded(
                        child: Text(
                          '#${tag.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Odstranit',
                        onPressed: () => _delete(context, tag),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: TimiqColors.danger,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ManagementScaffold extends StatelessWidget {
  const _ManagementScaffold({
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                  child: TimiqScreenHeader(
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: TimiqSpace.xs),
                  trailing!,
                ],
                const SizedBox(width: TimiqSpace.xs),
                TimiqIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Přidat',
                  onPressed: onAdd,
                ),
              ],
            ),
            const SizedBox(height: TimiqSpace.lg),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ArchiveToggle extends StatelessWidget {
  const _ArchiveToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return TimiqIconButton(
      icon: value ? Icons.inventory_2_rounded : Icons.inventory_2_outlined,
      tooltip: value ? 'Skrýt archiv' : 'Zobrazit archiv',
      color: value ? context.timiq.primaryGlow : null,
      onPressed: () => onChanged(!value),
    );
  }
}
