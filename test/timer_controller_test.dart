import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/application/timiq_controller.dart';
import 'package:timiq/domain/models.dart';

import 'support/memory_repository.dart';

class _FailingPlatformBridge extends NoopPlatformBridge {
  const _FailingPlatformBridge();

  @override
  Future<void> sync({
    required EntryDetails? active,
    required List<ActivityDetails> favorites,
  }) async {
    throw StateError('platform unavailable');
  }
}

void main() {
  test('start, switch and stop preserve one timer and exact boundary', () async {
    var now = DateTime(2026, 7, 19, 8);
    final repository = MemoryTimiqRepository();
    final category = TimiqCategory(
      id: 'category',
      name: 'Práce',
      colorValue: Colors.blue.toARGB32(),
      iconCodePoint: Icons.work.codePoint,
      sortOrder: 0,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
    repository.categories.add(category);
    for (final id in <String>['one', 'two']) {
      repository.activities.add(
        TimiqActivity(
          id: id,
          categoryId: category.id,
          name: id,
          iconCodePoint: Icons.bolt.codePoint,
          isFavorite: false,
          sortOrder: repository.activities.length,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    final controller = TimiqController(
      repository: repository,
      platformBridge: const NoopPlatformBridge(),
      clock: () => now,
    );
    await controller.initialize();

    await controller.startOrSwitch('one');
    expect(repository.entries.where((entry) => entry.isRunning), hasLength(1));
    await controller.startOrSwitch('one');
    expect(repository.entries.where((entry) => entry.isRunning), hasLength(1));

    now = DateTime(2026, 7, 19, 9, 15);
    await controller.startOrSwitch('two');
    final first = repository.entries.firstWhere(
      (entry) => entry.activityId == 'one',
    );
    final second = repository.entries.firstWhere(
      (entry) => entry.activityId == 'two',
    );
    expect(first.endTime, second.startTime);
    expect(repository.entries.where((entry) => entry.isRunning), hasLength(1));

    now = DateTime(2026, 7, 19, 10);
    await controller.stop();
    expect(repository.entries.where((entry) => entry.isRunning), isEmpty);
  });

  test('repository guard rejects a second concurrently active timer', () async {
    final repository = MemoryTimiqRepository();
    final at = DateTime(2026, 7, 19, 8);
    await repository.startActivity('one', at);

    await expectLater(
      repository.startActivity('two', at.add(const Duration(minutes: 1))),
      throwsA(isA<TimiqValidationException>()),
    );
    expect(repository.entries.where((entry) => entry.isRunning), hasLength(1));
  });

  test('successful database mutation survives platform sync failure', () async {
    final now = DateTime(2026, 7, 19, 8);
    final repository = MemoryTimiqRepository();
    repository.categories.add(
      TimiqCategory(
        id: 'category',
        name: 'Práce',
        colorValue: Colors.blue.toARGB32(),
        iconCodePoint: Icons.work.codePoint,
        sortOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    repository.activities.add(
      TimiqActivity(
        id: 'activity',
        categoryId: 'category',
        name: 'Vývoj',
        iconCodePoint: Icons.code.codePoint,
        isFavorite: false,
        sortOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final controller = TimiqController(
      repository: repository,
      platformBridge: const _FailingPlatformBridge(),
      clock: () => now,
    );
    await controller.initialize();

    await controller.startOrSwitch('activity');

    expect(repository.entries.single.isRunning, isTrue);
    expect(controller.activeEntry?.activityId, 'activity');
  });

  test('manual completed entries cannot end in the future', () async {
    final now = DateTime(2026, 7, 19, 12);
    final repository = MemoryTimiqRepository();
    repository.categories.add(
      TimiqCategory(
        id: 'category',
        name: 'PrĂˇce',
        colorValue: Colors.blue.toARGB32(),
        iconCodePoint: Icons.work.codePoint,
        sortOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    repository.activities.add(
      TimiqActivity(
        id: 'activity',
        categoryId: 'category',
        name: 'VĂ˝voj',
        iconCodePoint: Icons.code.codePoint,
        isFavorite: false,
        sortOrder: 0,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final controller = TimiqController(
      repository: repository,
      platformBridge: const NoopPlatformBridge(),
      clock: () => now,
    );
    await controller.initialize();

    await expectLater(
      controller.saveEntry(
        TimeEntry(
          id: 'entry',
          activityId: 'activity',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(minutes: 1)),
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<TimiqValidationException>()),
    );
    expect(repository.entries, isEmpty);
  });

  test('today breakdown includes an archived activity', () async {
    final now = DateTime(2026, 7, 19, 12);
    final repository = MemoryTimiqRepository();
    final category = TimiqCategory(
      id: 'category',
      name: 'Práce',
      colorValue: Colors.blue.toARGB32(),
      iconCodePoint: Icons.work.codePoint,
      sortOrder: 0,
      isArchived: true,
      createdAt: now,
      updatedAt: now,
    );
    final activity = TimiqActivity(
      id: 'activity',
      categoryId: category.id,
      name: 'Vývoj',
      iconCodePoint: Icons.code.codePoint,
      isFavorite: false,
      sortOrder: 0,
      isArchived: true,
      createdAt: now,
      updatedAt: now,
    );
    repository.categories.add(category);
    repository.activities.add(activity);
    repository.entries.add(
      TimeEntry(
        id: 'entry',
        activityId: activity.id,
        startTime: DateTime(2026, 7, 19, 8),
        endTime: DateTime(2026, 7, 19, 11),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final controller = TimiqController(
      repository: repository,
      platformBridge: const NoopPlatformBridge(),
      clock: () => now,
    );
    await controller.initialize();

    expect(controller.todayTotal, const Duration(hours: 3));
    expect(
      controller.todayCategoryTotals.single.duration,
      const Duration(hours: 3),
    );
  });
}
