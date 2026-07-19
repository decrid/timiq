import 'package:flutter/material.dart';

import '../application/timiq_controller.dart';
import '../core/design/timiq_theme.dart';
import 'widgets/timiq_components.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _working = false;

  Future<void> _finish(bool starterSet) async {
    setState(() => _working = true);
    try {
      await TimiqScope.of(context, listen: false)
          .completeOnboarding(useStarterSet: starterSet);
    } catch (error) {
      if (mounted) {
        showTimiqMessage(
          context,
          error is Exception ? error.toString() : 'Něco se nepovedlo.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.8),
            radius: 1.2,
            colors: <Color>[
              context.timiq.primary.withValues(alpha: 0.18),
              context.timiq.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TimiqSpace.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.sizeOf(context).height - TimiqSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: <Color>[
                              TimiqColors.primary,
                              TimiqColors.primaryGlow,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(TimiqRadius.medium),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: TimiqColors.primary
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: TimiqSpace.sm),
                      Text(
                        'TimIQ',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: TimiqSpace.xxl),
                  Text(
                    'Tvůj čas.\nBez domněnek.',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: 42, height: 1.05),
                  ),
                  const SizedBox(height: TimiqSpace.md),
                  Text(
                    'Jedním klepnutím začneš. Klepnutím na jinou aktivitu '
                    'plynule přepneš. TimIQ pak ukáže, čemu skutečně věnuješ '
                    'své dny.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: context.timiq.muted),
                  ),
                  const SizedBox(height: TimiqSpace.xl),
                  const _Principle(
                    icon: Icons.touch_app_outlined,
                    title: 'Jedno klepnutí',
                    message: 'Žádné formuláře při běžném měření.',
                  ),
                  const SizedBox(height: TimiqSpace.sm),
                  const _Principle(
                    icon: Icons.offline_bolt_outlined,
                    title: 'Offline a soukromě',
                    message: 'Všechna data zůstávají v tomto zařízení.',
                  ),
                  const SizedBox(height: TimiqSpace.sm),
                  const _Principle(
                    icon: Icons.auto_graph_outlined,
                    title: 'Skutečný obraz dne',
                    message: 'Historie, mezery a trendy ze skutečných dat.',
                  ),
                  const SizedBox(height: TimiqSpace.xl),
                  FilledButton.icon(
                    onPressed: _working ? null : () => _finish(true),
                    icon: _working
                        ? const TimiqLoader(size: 18, color: Colors.white)
                        : const Icon(Icons.bolt),
                    label: const Text('Začít se základní sadou'),
                  ),
                  const SizedBox(height: TimiqSpace.sm),
                  OutlinedButton(
                    onPressed: _working ? null : () => _finish(false),
                    child: const Text('Nastavit vše ručně'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return TimiqCard(
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
                const SizedBox(height: 2),
                Text(
                  message,
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
    );
  }
}
