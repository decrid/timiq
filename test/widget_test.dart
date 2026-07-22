import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/app/timiq_app.dart';
import 'package:timiq/application/timiq_controller.dart';
import 'package:timiq/core/design/icon_catalog.dart';
import 'package:timiq/core/design/timiq_theme.dart';
import 'package:timiq/domain/models.dart';
import 'package:timiq/presentation/time_entry_editor.dart';
import 'package:timiq/presentation/widgets/timiq_components.dart';
import 'package:timiq/presentation/widgets/timiq_pickers.dart';

import 'support/memory_repository.dart';

void main() {
  test('stored icon code points resolve only through the constant catalog', () {
    expect(
      timiqIconFromCodePoint(timiqIconCatalog.first.icon.codePoint),
      timiqIconCatalog.first.icon,
    );
    expect(
      timiqIconFromCodePoint(Icons.work_outline.codePoint),
      Icons.work_outline_rounded,
    );
    expect(
      timiqIconFromCodePoint(Icons.family_restroom.codePoint),
      Icons.family_restroom_rounded,
    );
    expect(timiqIconFromCodePoint(-1), timiqIconCatalog.last.icon);
  });

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

  testWidgets('ActivityGlyph keeps a public stored icon API', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: ActivityGlyph(
            iconCodePoint: 0xe6f4,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
  });

  testWidgets('time picker exposes a 12 hour period column', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TimiqTheme.dark(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTimiqTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 18, minute: 30),
              use24HourFormat: false,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('PM'), findsWidgets);
    expect(find.text('18'), findsNothing);
  });

  testWidgets('multi-day editor preserves independent start and end dates',
      (tester) async {
    final created = DateTime(2026, 7, 1);
    final category = TimiqCategory(
      id: 'category',
      name: 'Práce',
      colorValue: Colors.blue.toARGB32(),
      iconCodePoint: Icons.work.codePoint,
      sortOrder: 0,
      isArchived: false,
      createdAt: created,
      updatedAt: created,
    );
    final activity = TimiqActivity(
      id: 'activity',
      categoryId: category.id,
      name: 'Vývoj',
      iconCodePoint: Icons.code.codePoint,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: created,
      updatedAt: created,
    );
    final entry = TimeEntry(
      id: 'entry',
      activityId: activity.id,
      startTime: DateTime(2026, 7, 19, 8),
      endTime: DateTime(2026, 7, 21, 10),
      createdAt: created,
      updatedAt: created,
    );
    final repository = MemoryTimiqRepository()
      ..categories.add(category)
      ..activities.add(activity)
      ..entries.add(entry);
    final controller = TimiqController(
      repository: repository,
      platformBridge: const NoopPlatformBridge(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: TimiqTheme.dark(),
        home: TimiqScope(
          controller: controller,
          child: TimeEntryEditor(
            existing: EntryDetails(
              entry: entry,
              activity: activity,
              category: category,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('19. 7. 2026'), findsOneWidget);
    expect(find.text('21. 7. 2026'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
  });
}
