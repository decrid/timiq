import 'package:flutter_test/flutter_test.dart';
import 'package:timiq/application/timiq_controller.dart';
import 'package:timiq/data/timiq_repository.dart';

void main() {
  test('CSV export includes names and safely escapes user notes', () {
    final start = DateTime(2026, 7, 19, 8);
    final data = <String, Object?>{
      'categories': <Map<String, Object?>>[
        <String, Object?>{'id': 'c1', 'name': 'Práce, tým'},
      ],
      'activities': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'a1',
          'category_id': 'c1',
          'name': 'Vývoj',
        },
      ],
      'timeEntries': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'e1',
          'activity_id': 'a1',
          'start_time': start.millisecondsSinceEpoch,
          'end_time': start
              .add(const Duration(hours: 2))
              .millisecondsSinceEpoch,
          'note': 'Řádek 1, "citace"\nŘádek 2',
        },
      ],
    };

    final csv = buildCsvExport(data, DateTime(2026, 7, 19, 12));

    expect(csv, startsWith('\uFEFFid,activity_id,activity_name'));
    expect(csv, contains('"Vývoj"'));
    expect(csv, contains('"Práce, tým"'));
    expect(csv, contains('"Řádek 1, ""citace""\nŘádek 2"'));
    expect(csv, contains(',7200,'));
  });

  test('running entry duration is evaluated at export time', () {
    final start = DateTime(2026, 7, 19, 8);
    final data = <String, Object?>{
      'categories': <Map<String, Object?>>[],
      'activities': <Map<String, Object?>>[],
      'timeEntries': <Map<String, Object?>>[
        <String, Object?>{
          'id': 'e1',
          'activity_id': 'missing',
          'start_time': start.millisecondsSinceEpoch,
          'end_time': null,
          'note': '',
        },
      ],
    };

    final csv = buildCsvExport(data, DateTime(2026, 7, 19, 9, 30));

    expect(csv, contains(',5400,'));
  });

  test('JSON backup payload keeps every required collection and metadata', () {
    final exportedAt = DateTime.utc(2026, 7, 19, 12);
    final payload = buildBackupPayload(
      categories: <Map<String, Object?>>[
        <String, Object?>{'id': 'category'},
      ],
      activities: <Map<String, Object?>>[
        <String, Object?>{'id': 'activity'},
      ],
      timeEntries: <Map<String, Object?>>[
        <String, Object?>{'id': 'entry'},
      ],
      tags: <Map<String, Object?>>[
        <String, Object?>{'id': 'tag'},
      ],
      timeEntryTags: <Map<String, Object?>>[
        <String, Object?>{'time_entry_id': 'entry', 'tag_id': 'tag'},
      ],
      settings: <Map<String, Object?>>[
        <String, Object?>{'key': 'theme_mode', 'value': 'dark'},
      ],
      exportedAt: exportedAt,
    );

    expect(payload['format'], 'timiq-backup');
    expect(payload['version'], 1);
    expect(payload['exportedAt'], exportedAt.toIso8601String());
    for (final key in <String>[
      'categories',
      'activities',
      'timeEntries',
      'tags',
      'timeEntryTags',
      'settings',
    ]) {
      expect(payload[key], isNotEmpty);
    }
  });
}
