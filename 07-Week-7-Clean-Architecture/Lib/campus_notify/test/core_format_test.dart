import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/format.dart';

void main() {
  group('Core Pure Format & Route Parser Tests', () {
    test('formatDateIndo memformat DateTime menjadi format teks bahasa Indonesia',
        () {
      final date = DateTime(2026, 10, 19, 14, 30);
      final formatted = formatDateIndo(date);

      expect(formatted, '19 Oktober 2026, 14:30 WIB');
    });

    test('parseRouteFromMessage menangani route normal, route tanpa slash, dan route kosong',
        () {
      expect(parseRouteFromMessage({'route': '/pengumuman/99'}), '/pengumuman/99');
      expect(parseRouteFromMessage({'route': 'pengumuman/99'}), '/pengumuman/99');
      expect(parseRouteFromMessage({'route': ''}), '/');
      expect(parseRouteFromMessage({}), '/');
    });
  });
}
