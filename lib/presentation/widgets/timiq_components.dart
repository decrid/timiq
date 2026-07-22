import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/icon_catalog.dart';
import '../../core/design/timiq_theme.dart';
import '../../core/utils/time_utils.dart';
import '../../domain/models.dart';

class TimiqPage extends StatelessWidget {
  const TimiqPage({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      TimiqSpace.md,
      TimiqSpace.sm,
      TimiqSpace.md,
      112,
    ),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return ColoredBox(
      color: context.timiq.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding.copyWith(bottom: padding.bottom + bottomInset),
          child: child,
        ),
      ),
    );
  }
}

class TimiqScreenHeader extends StatelessWidget {
  const TimiqScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: TimiqSpace.xs),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.timiq.muted),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class TimiqCard extends StatelessWidget {
  const TimiqCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(TimiqSpace.md),
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.timiq;
    return Material(
      color: color ?? palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TimiqRadius.medium),
        side: BorderSide(color: borderColor ?? palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TimiqRadius.medium),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class TimiqIconButton extends StatelessWidget {
  const TimiqIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: context.timiq.elevated,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 46,
            child: Icon(icon, size: 21, color: color),
          ),
        ),
      ),
    );
  }
}

class TimiqTextField extends StatelessWidget {
  const TimiqTextField({
    required this.controller,
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.maxLines = 1,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final int maxLines;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
      ),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(TimiqRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontSize: 10,
            ),
      ),
    );
  }
}

class ActivityGlyph extends StatelessWidget {
  const ActivityGlyph({
    required this.iconCodePoint,
    required this.color,
    super.key,
    this.size = 44,
  }) : icon = null;

  const ActivityGlyph.staticIcon({
    required this.icon,
    required this.color,
    super.key,
    this.size = 44,
  }) : iconCodePoint = null;

  final int? iconCodePoint;
  final IconData? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon ?? timiqIconFromCodePoint(iconCodePoint!),
        color: color,
        size: size * 0.48,
      ),
    );
  }
}

class TimiqEmptyState extends StatelessWidget {
  const TimiqEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return TimiqCard(
      padding: const EdgeInsets.all(TimiqSpace.lg),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.timiq.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.timiq.primaryGlow),
          ),
          const SizedBox(height: TimiqSpace.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TimiqSpace.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.timiq.muted),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: TimiqSpace.md),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

Future<T?> showTimiqSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.timiq.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TimiqRadius.large),
          ),
          border: Border(top: BorderSide(color: context.timiq.border)),
        ),
        child: builder(context),
      ),
    ),
  );
}

Future<bool> showTimiqConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Potvrdit',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(TimiqSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: TimiqSpace.sm),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.timiq.muted),
            ),
            const SizedBox(height: TimiqSpace.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Zrušit'),
                  ),
                ),
                const SizedBox(width: TimiqSpace.sm),
                Expanded(
                  child: FilledButton(
                    style: destructive
                        ? FilledButton.styleFrom(
                            backgroundColor: TimiqColors.danger,
                          )
                        : null,
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

void showTimiqMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? TimiqColors.danger : TimiqColors.success,
            ),
            const SizedBox(width: TimiqSpace.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

String timiqErrorMessage(Object error) {
  if (error is TimiqValidationException) return error.message;
  return 'Operaci se nepodařilo dokončit. Vaše data zůstala beze změny.';
}

class TimiqSegmented<T> extends StatelessWidget {
  const TimiqSegmented({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.timiq.elevated,
        borderRadius: BorderRadius.circular(TimiqRadius.medium),
        border: Border.all(color: context.timiq.border),
      ),
      child: Row(
        children: values
            .map(
              (value) => Expanded(
                child: AnimatedContainer(
                  duration: TimiqMotion.quick,
                  decoration: BoxDecoration(
                    color: value == selected
                        ? context.timiq.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(TimiqRadius.small),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TimiqRadius.small),
                    onTap: () => onChanged(value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        labelBuilder(value),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: value == selected
                                  ? Colors.white
                                  : context.timiq.muted,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class TimeRing extends StatefulWidget {
  const TimeRing({
    required this.active,
    super.key,
    this.color = TimiqColors.primary,
  });

  final EntryDetails? active;
  final Color color;

  @override
  State<TimeRing> createState() => _TimeRingState();
}

class _TimeRingState extends State<TimeRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active != null) _animation.repeat();
  }

  @override
  void didUpdateWidget(TimeRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != null && !_animation.isAnimating) {
      _animation.repeat();
    } else if (widget.active == null && _animation.isAnimating) {
      _animation.stop();
      _animation.value = 0;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _TimeRingPainter(
            color: widget.color,
            animation: _animation,
            active: active != null,
            trackColor: context.timiq.border,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: active == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.touch_app_outlined,
                          size: 30,
                          color: context.timiq.primaryGlow,
                        ),
                        const SizedBox(height: TimiqSpace.sm),
                        Text(
                          'Co právě děláš?',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vyber aktivitu jedním klepnutím',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: context.timiq.muted),
                        ),
                      ],
                    )
                  : _LiveTimeLabel(details: active),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveTimeLabel extends StatefulWidget {
  const _LiveTimeLabel({required this.details});

  final EntryDetails details;

  @override
  State<_LiveTimeLabel> createState() => _LiveTimeLabelState();
}

class _LiveTimeLabelState extends State<_LiveTimeLabel> {
  late final Stream<DateTime> _ticks = Stream<DateTime>.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _ticks,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatTimer(widget.details.entry.durationAt(now)),
                maxLines: 1,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ),
            const SizedBox(height: TimiqSpace.md),
            Text(
              widget.details.activity.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TimiqSpace.xs),
            CategoryBadge(
              label: widget.details.category.name,
              color: widget.details.color,
            ),
          ],
        );
      },
    );
  }
}

class _TimeRingPainter extends CustomPainter {
  _TimeRingPainter({
    required this.color,
    required this.animation,
    required this.active,
    required this.trackColor,
  }) : super(repaint: animation);

  final Color color;
  final Animation<double> animation;
  final bool active;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 18;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = trackColor.withValues(alpha: active ? 0.52 : 0.7);
    canvas.drawCircle(center, radius, track);
    if (!active) {
      final quiet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = color.withValues(alpha: 0.24);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 0.38, false, quiet);
      return;
    }
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 19
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final start = -math.pi / 2 + animation.value * math.pi * 2;
    canvas.drawArc(rect, start, math.pi * 1.55, false, glow);
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: <Color>[
          color.withValues(alpha: 0.2),
          color,
          TimiqColors.primaryGlow,
          color.withValues(alpha: 0.2),
        ],
        transform: GradientRotation(start),
      ).createShader(rect);
    canvas.drawArc(rect, start, math.pi * 1.75, false, activePaint);
  }

  @override
  bool shouldRepaint(_TimeRingPainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

class TimeWheel extends StatelessWidget {
  const TimeWheel({
    required this.items,
    required this.total,
    super.key,
    this.onSelected,
    this.size = 230,
  });

  final List<CategoryTotal> items;
  final Duration total;
  final ValueChanged<CategoryTotal>? onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: GestureDetector(
        onTapUp: onSelected == null
            ? null
            : (details) {
                final center = Offset(size / 2, size / 2);
                final vector = details.localPosition - center;
                final radius = vector.distance;
                if (radius < size * 0.29 || radius > size * 0.5) return;
                var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
                if (angle < 0) angle += math.pi * 2;
                final fraction = angle / (math.pi * 2);
                var cursor = 0.0;
                for (final item in items) {
                  final share = total.inMilliseconds == 0
                      ? 0.0
                      : item.duration.inMilliseconds / total.inMilliseconds;
                  if (fraction >= cursor && fraction < cursor + share) {
                    onSelected!(item);
                    return;
                  }
                  cursor += share;
                }
              },
        child: CustomPaint(
          painter: _TimeWheelPainter(
            items: items,
            total: total,
            trackColor: context.timiq.border,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  formatDuration(total, compact: true),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'CELKEM',
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

class _TimeWheelPainter extends CustomPainter {
  const _TimeWheelPainter({
    required this.items,
    required this.total,
    required this.trackColor,
  });

  final List<CategoryTotal> items;
  final Duration total;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 23
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (total.inMilliseconds <= 0) return;
    var start = -math.pi / 2;
    const gap = 0.025;
    for (final item in items) {
      final share = item.duration.inMilliseconds / total.inMilliseconds;
      final sweep = math.max(0.0, share * math.pi * 2 - gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 23
        ..strokeCap = StrokeCap.round
        ..color = item.category.color;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);
      start += share * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(_TimeWheelPainter oldDelegate) =>
      oldDelegate.items != items ||
      oldDelegate.total != total ||
      oldDelegate.trackColor != trackColor;
}

class ProportionBar extends StatelessWidget {
  const ProportionBar({
    required this.value,
    required this.color,
    super.key,
  });

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TimiqRadius.pill),
      child: SizedBox(
        height: 6,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0).toDouble(),
          backgroundColor: context.timiq.border,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: TimiqSpace.md),
        decoration: BoxDecoration(
          color: context.timiq.border,
          borderRadius: BorderRadius.circular(TimiqRadius.pill),
        ),
      ),
    );
  }
}

class TimiqLoader extends StatefulWidget {
  const TimiqLoader({
    super.key,
    this.size = 28,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<TimiqLoader> createState() => _TimiqLoaderState();
}

class _TimiqLoaderState extends State<TimiqLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
      child: Icon(
        Icons.hourglass_top_rounded,
        size: widget.size,
        color: widget.color ?? context.timiq.primaryGlow,
      ),
    );
  }
}
