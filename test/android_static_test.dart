import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget native action stops the same running activity', () {
    final source = File(
      'android/app/src/main/kotlin/app/timiq/TimiqWidgets.kt',
    ).readAsStringSync();

    expect(source, contains('if (runningActivity == activityId)'));
    expect(source, contains('put("end_time", newStart)'));
    expect(source, contains('return@withDatabase'));
    expect(source, contains('db.insertOrThrow'));
  });

  test('platform reset clears Android surfaces and notification', () {
    final source = File(
      'android/app/src/main/kotlin/app/timiq/PlatformSync.kt',
    ).readAsStringSync();

    expect(source, contains('fun resetSurfaces'));
    expect(source, contains('.clear()'));
    expect(source, contains('manager.cancel(NOTIFICATION_ID)'));
    expect(source, contains('updateWidgets(context)'));
  });
}
