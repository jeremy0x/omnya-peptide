// Writes the tab bar's Hugeicons as SVG files for the native tab bar. Run: flutter test tool/gen_icons_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

String svg(List<List<dynamic>> icon, double stroke) {
  final parts = icon.map((e) {
    final attrs = (e[1] as Map).entries
        .where((a) => a.key != 'key')
        .map(
          (a) => '${a.key}="${a.key == 'strokeWidth' ? stroke : (a.value == 'currentColor' ? '#000000' : a.value)}"'
              .replaceFirst('strokeWidth', 'stroke-width')
              .replaceFirst('strokeLinecap', 'stroke-linecap')
              .replaceFirst('strokeLinejoin', 'stroke-linejoin')
              .replaceFirst('fillRule', 'fill-rule')
              .replaceFirst('clipRule', 'clip-rule'),
        )
        .join(' ');
    return '<${e[0]} $attrs/>';
  }).join();
  return '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">$parts</svg>';
}

void main() {
  test('generate', () {
    final icons = {
      'today': HugeIcons.strokeRoundedCalendar03,
      'progress': HugeIcons.strokeRoundedProgress02,
      'stack': HugeIcons.strokeRoundedAmpoule,
      'circle': HugeIcons.strokeRoundedUserGroup,
      'add': HugeIcons.strokeRoundedAdd01,
      'share': HugeIcons.strokeRoundedShare01,
      'camera': HugeIcons.strokeRoundedCameraSmile02,
      'calculator': HugeIcons.strokeRoundedCalculator,
    };
    for (final e in icons.entries) {
      File('assets/icons/${e.key}.svg').writeAsStringSync(svg(e.value, 1.5));
      File('assets/icons/${e.key}_active.svg').writeAsStringSync(svg(e.value, 2));
    }
  });
}
