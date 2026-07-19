import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/app/timiq_app.dart';
import 'package:timiq/application/timiq_controller.dart';
import 'package:timiq/domain/models.dart';

import 'support/memory_repository.dart';

void main() {
  testWidgets('first launch shows the concise TimIQ onboarding', (tester) async {
    final repository = MemoryTimiqRepository()
      ..settings = const AppSettings(onboardingCompleted: false);
    final controller = TimiqController(
      repository: repository,
      platformBridge: const NoopPlatformBridge(),
    );
    await controller.initialize();

    await tester.pumpWidget(TimiqApp(controller: controller));
    await tester.pump();

    expect(find.text('TimIQ'), findsOneWidget);
    expect(find.text('Tvůj čas.\nBez domněnek.'), findsOneWidget);
    expect(find.text('Začít se základní sadou'), findsOneWidget);
  });
}
