import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';

class PlatformBridge {
  const PlatformBridge();

  static const MethodChannel _channel = MethodChannel('app.timiq/platform');

  Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('requestNotificationPermission');
    } on MissingPluginException {
      // The Android integration is intentionally optional on other platforms.
    }
  }

  Future<void> sync({
    required EntryDetails? active,
    required List<ActivityDetails> favorites,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final payload = <String, Object?>{
      'active': active == null
          ? null
          : <String, Object?>{
              'entryId': active.entry.id,
              'activityId': active.activity.id,
              'activityName': active.activity.name,
              'categoryName': active.category.name,
              'color': active.color.toARGB32(),
              'startTime': active.entry.startTime.millisecondsSinceEpoch,
            },
      'favorites': favorites
          .take(6)
          .map(
            (item) => <String, Object?>{
              'activityId': item.activity.id,
              'activityName': item.activity.name,
              'categoryName': item.category.name,
              'color': item.color.toARGB32(),
              'trackedToday': item.trackedToday.inMilliseconds,
            },
          )
          .toList(growable: false),
    };
    try {
      await _channel.invokeMethod<void>('syncPlatform', payload);
    } on MissingPluginException {
      // Allows widget tests and supported non-Android targets to run normally.
    }
  }

  Future<void> resetPlatform() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('resetPlatform');
    } on MissingPluginException {
      // Allows widget tests and supported non-Android targets to run normally.
    }
  }
}
