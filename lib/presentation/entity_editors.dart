import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/icon_catalog.dart';
import '../core/design/timiq_theme.dart';
import '../core/utils/time_utils.dart';
import '../domain/models.dart';
import 'widgets/timiq_components.dart';
import 'widgets/timiq_pickers.dart';

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({super.key, this.category});

  final TimiqCategory? category;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.category?.name ?? '');
  late int _color = widget.category?.colorValue ??
      TimiqColors.categoryPalette.first.toARGB32();
  late int _icon = widget.category?.iconCodePoint ??
      timiqIconCatalog.first.icon.codePoint;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showTimiqMessage(context, 'Zadejte název kategorie.', isError: true);
      return;
    }
    setState(() => _saving = true);
    final controller = TimiqScope.of(context, listen: false);
    final existing = widget.category;
    final timestamp = controller.now;
    final category = TimiqCategory(
      id: existing?.id ?? newId('category'),
      name: name,
      colorValue: _color,
      iconCodePoint: _icon,
      sortOrder: existing?.sortOrder ?? controller.categories.length,
      isArchived: existing?.isArchived ?? false,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
    );
    try {
      await controller.saveCategory(category);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditorScaffold(
      title: widget.category == null ? 'Nová kategorie' : 'Upravit kategorii',
      saveLabel: _saving ? 'Ukládám…' : 'Uložit kategorii',
      onSave: _saving ? null : _save,
      child: ListView(
        children: <Widget>[
          Text('NÁZEV', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          TimiqTextField(
            controller: _name,
            hint: 'Například Práce',
            prefixIcon: Icons.label_outline,
            autofocus: widget.category == null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: TimiqSpace.lg),
          Text('BARVA', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          _ColorGrid(
            selected: _color,
            onSelected: (value) => setState(() => _color = value),
          ),
          const SizedBox(height: TimiqSpace.lg),
          Text('IKONA', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          _IconGrid(
            selected: _icon,
            color: Color(_color),
            onSelected: (value) => setState(() => _icon = value),
          ),
          const SizedBox(height: TimiqSpace.lg),
          TimiqCard(
            child: Row(
              children: <Widget>[
                ActivityGlyph(
                  iconCodePoint: _icon,
                  color: Color(_color),
                  size: 52,
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _name.text.trim().isEmpty
                            ? 'Náhled kategorie'
                            : _name.text.trim(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Barva se propíše do statistik a timeline.',
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
        ],
      ),
    );
  }
}

class ActivityEditor extends StatefulWidget {
  const ActivityEditor({
    super.key,
    this.activity,
    this.initialCategoryId,
  });

  final TimiqActivity? activity;
  final String? initialCategoryId;

  @override
  State<ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<ActivityEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.activity?.name ?? '');
  late String? _categoryId =
      widget.activity?.categoryId ?? widget.initialCategoryId;
  late int _icon = widget.activity?.iconCodePoint ??
      timiqIconCatalog.first.icon.codePoint;
  late int? _customColor = widget.activity?.customColorValue;
  late bool _favorite = widget.activity?.isFavorite ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final controller = TimiqScope.of(context, listen: false);
    final selected = await showTimiqChoice<TimiqCategory>(
      context: context,
      title: 'Vyberte kategorii',
      values: controller.activeCategories,
      selected:
          _categoryId == null ? null : controller.categoryById(_categoryId!),
      labelBuilder: (value) => value.name,
      leadingBuilder: (context, value) => ActivityGlyph(
        iconCodePoint: value.iconCodePoint,
        color: value.color,
        size: 40,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _categoryId = selected.id);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showTimiqMessage(context, 'Zadejte název aktivity.', isError: true);
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) {
      showTimiqMessage(context, 'Vyberte kategorii.', isError: true);
      return;
    }
    setState(() => _saving = true);
    final controller = TimiqScope.of(context, listen: false);
    final existing = widget.activity;
    final timestamp = controller.now;
    final activity = TimiqActivity(
      id: existing?.id ?? newId('activity'),
      categoryId: categoryId,
      name: name,
      iconCodePoint: _icon,
      customColorValue: _customColor,
      isFavorite: _favorite,
      sortOrder: existing?.sortOrder ?? controller.activities.length,
      isArchived: existing?.isArchived ?? false,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp,
    );
    try {
      await controller.saveActivity(activity);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(context, timiqErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = TimiqScope.of(context);
    final category =
        _categoryId == null ? null : controller.categoryById(_categoryId!);
    final inheritedColor = category?.color ?? context.timiq.primary;
    final displayColor =
        _customColor == null ? inheritedColor : Color(_customColor!);
    return _EditorScaffold(
      title: widget.activity == null ? 'Nová aktivita' : 'Upravit aktivitu',
      saveLabel: _saving ? 'Ukládám…' : 'Uložit aktivitu',
      onSave: _saving ? null : _save,
      child: ListView(
        children: <Widget>[
          Text('NÁZEV', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          TimiqTextField(
            controller: _name,
            hint: 'Například SAP / ABAP',
            prefixIcon: Icons.bolt_outlined,
            autofocus: widget.activity == null,
          ),
          const SizedBox(height: TimiqSpace.lg),
          Text('KATEGORIE', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          TimiqCard(
            onTap: _pickCategory,
            child: Row(
              children: <Widget>[
                category == null
                    ? ActivityGlyph.staticIcon(
                        icon: Icons.category_outlined,
                        color: inheritedColor,
                      )
                    : ActivityGlyph(
                        iconCodePoint: category.iconCodePoint,
                        color: inheritedColor,
                      ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Text(
                    category?.name ?? 'Vyberte kategorii',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: category == null
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
          Text('IKONA', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          _IconGrid(
            selected: _icon,
            color: displayColor,
            onSelected: (value) => setState(() => _icon = value),
          ),
          const SizedBox(height: TimiqSpace.lg),
          Text('VLASTNÍ BARVA',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: TimiqSpace.xs),
          TimiqCard(
            onTap: () => setState(() {
              _customColor = _customColor == null
                  ? TimiqColors.categoryPalette[2].toARGB32()
                  : null;
            }),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Přepsat barvu kategorie',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _customColor == null
                            ? 'Aktivita dědí barvu ${category?.name ?? 'kategorie'}.'
                            : 'Aktivita používá vlastní akcent.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: context.timiq.muted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _customColor != null,
                  onChanged: (value) => setState(() {
                    _customColor = value
                        ? TimiqColors.categoryPalette[2].toARGB32()
                        : null;
                  }),
                ),
              ],
            ),
          ),
          if (_customColor != null) ...<Widget>[
            const SizedBox(height: TimiqSpace.xs),
            _ColorGrid(
              selected: _customColor!,
              onSelected: (value) => setState(() => _customColor = value),
            ),
          ],
          const SizedBox(height: TimiqSpace.md),
          TimiqCard(
            onTap: () => setState(() => _favorite = !_favorite),
            child: Row(
              children: <Widget>[
                Icon(
                  _favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color:
                      _favorite ? TimiqColors.warning : context.timiq.muted,
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: Text(
                    'Oblíbená aktivita',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: _favorite,
                  onChanged: (value) => setState(() => _favorite = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.title,
    required this.child,
    required this.saveLabel,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final String saveLabel;
  final VoidCallback? onSave;

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
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TimiqSpace.lg),
            Expanded(child: child),
            const SizedBox(height: TimiqSpace.md),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check_rounded),
              label: SizedBox(
                width: double.infinity,
                child: Text(saveLabel, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TimiqSpace.sm,
      runSpacing: TimiqSpace.sm,
      children: TimiqColors.categoryPalette.map((color) {
        final selectedColor = color.toARGB32() == selected;
        return Semantics(
          button: true,
          selected: selectedColor,
          label: 'Barva ${color.toARGB32().toRadixString(16)}',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onSelected(color.toARGB32()),
            child: AnimatedContainer(
              duration: TimiqMotion.quick,
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedColor ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: selectedColor
                    ? <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                      ]
                    : null,
              ),
              child: selectedColor
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final int selected;
  final Color color;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: TimiqSpace.xs,
        crossAxisSpacing: TimiqSpace.xs,
      ),
      itemCount: timiqIconCatalog.length,
      itemBuilder: (context, index) {
        final option = timiqIconCatalog[index];
        final isSelected = option.icon.codePoint == selected;
        return Tooltip(
          message: option.label,
          child: Material(
            color: isSelected
                ? color.withValues(alpha: 0.18)
                : context.timiq.elevated,
            borderRadius: BorderRadius.circular(TimiqRadius.small),
            child: InkWell(
              borderRadius: BorderRadius.circular(TimiqRadius.small),
              onTap: () => onSelected(option.icon.codePoint),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? color : context.timiq.border,
                  ),
                  borderRadius: BorderRadius.circular(TimiqRadius.small),
                ),
                child: Icon(
                  option.icon,
                  color: isSelected ? color : context.timiq.muted,
                  size: 21,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
