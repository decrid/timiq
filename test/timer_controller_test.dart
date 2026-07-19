import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/application/timiq_controller.dart';
import 'package:timiq/domain/models.dart';

import 'support/memory_repository.dart';

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
}
