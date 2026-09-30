import '../models/compound.dart';

// ponytail: Shotsy's export format isn't confirmed yet (spec open item). This reads any
// CSV whose headers name a date plus a medication/dose and/or a weight, which covers
// typical shot-tracker exports. Swap the header lists once we have a real file.

class ImportedDose {
  final DateTime at;
  final String compound;
  final double dose;
  final String unit;
  final String site;
  const ImportedDose(this.at, this.compound, this.dose, this.unit, this.site);
}

class ImportedWeight {
  final DateTime at;
  final double lbs;
  const ImportedWeight(this.at, this.lbs);
}

class ImportResult {
  final List<ImportedDose> doses;
  final List<ImportedWeight> weights;
  final int skipped;
  const ImportResult(this.doses, this.weights, this.skipped);
}

/// RFC 4180 rows: commas, quoted fields, doubled quotes, CRLF or LF.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"' && i + 1 < text.length && text[i + 1] == '"') {
        field.write('"');
        i++;
      } else if (ch == '"') {
        quoted = false;
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      row.add(field.toString().trim());
      field.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString().trim());
      field.clear();
      if (row.any((f) => f.isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(ch);
    }
  }
  row.add(field.toString().trim());
  if (row.any((f) => f.isNotEmpty)) rows.add(row);
  return rows;
}

int _column(List<String> header, List<String> names) {
  final h = header.map((e) => e.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')).toList();
  for (final n in names) {
    final i = h.indexWhere((c) => c == n || c.startsWith(n));
    if (i != -1) return i;
  }
  return -1;
}

/// "2024-05-01", "2024-05-01T08:30:00Z", "05/01/2024", "5/1/2024 8:30 AM".
DateTime? parseDate(String s) {
  final iso = DateTime.tryParse(s.trim());
  if (iso != null) return iso.toLocal();
  final m = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{2,4})(?:[ T,]+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp][Mm])?)?',
  ).firstMatch(s.trim());
  if (m == null) return null;
  var year = int.parse(m[3]!);
  if (year < 100) year += 2000;
  var hour = int.tryParse(m[4] ?? '') ?? 12;
  final pm = m[6]?.toLowerCase() == 'pm';
  if (m[6] != null && hour == 12) hour = 0;
  if (pm) hour += 12;
  return DateTime(year, int.parse(m[1]!), int.parse(m[2]!), hour, int.tryParse(m[5] ?? '') ?? 0);
}

/// "2.5", "2.5 mg", "250mcg". Unit falls back to [fallback].
(double, String)? parseAmount(String s, String fallback) {
  final m = RegExp(r'([\d.]+)\s*(mg|mcg|µg|ug|iu|units?)?', caseSensitive: false).firstMatch(s);
  final v = m == null ? null : double.tryParse(m[1]!);
  if (v == null || v <= 0) return null;
  final u = (m![2] ?? fallback).toLowerCase();
  return (
    v,
    switch (u) {
      'mcg' || 'µg' || 'ug' => 'mcg',
      'iu' || 'unit' || 'units' => 'IU',
      _ => 'mg',
    },
  );
}

String _site(String s) {
  final t = s.toLowerCase();
  if (t.isEmpty) return '';
  final side = t.contains('right') || RegExp(r'\br\b').hasMatch(t) ? 'Right' : 'Left';
  final part = t.contains('thigh') || t.contains('leg')
      ? 'thigh'
      : t.contains('arm')
      ? 'arm'
      : 'abdomen';
  final site = '$side $part';
  return injectionSites.contains(site) ? site : '';
}

ImportResult parseShotsyCsv(String text) {
  final rows = parseCsv(text);
  if (rows.length < 2) return const ImportResult([], [], 0);
  final header = rows.first;
  final date = _column(header, ['date', 'datetime', 'time', 'timestamp', 'loggedat', 'takenat']);
  final med = _column(header, ['medication', 'medicine', 'drug', 'compound', 'peptide', 'name', 'shot']);
  final dose = _column(header, ['dose', 'dosage', 'amount']);
  final unitCol = _column(header, ['unit', 'units']);
  final site = _column(header, ['injectionsite', 'site', 'location', 'spot']);
  final weight = _column(header, ['weight', 'bodyweight']);
  final kg = weight != -1 && header[weight].toLowerCase().contains('kg');

  final doses = <ImportedDose>[];
  final weights = <ImportedWeight>[];
  var skipped = 0;
  String cell(List<String> r, int i) => i >= 0 && i < r.length ? r[i] : '';

  for (final r in rows.skip(1)) {
    final at = parseDate(cell(r, date));
    if (at == null) {
      skipped++;
      continue;
    }
    var used = false;
    final amount = parseAmount(cell(r, dose), cell(r, unitCol).isEmpty ? 'mg' : cell(r, unitCol));
    final name = cell(r, med);
    if (name.isNotEmpty && amount != null) {
      doses.add(ImportedDose(at, name, amount.$1, amount.$2, _site(cell(r, site))));
      used = true;
    }
    final w = double.tryParse(cell(r, weight).replaceAll(RegExp(r'[^\d.]'), ''));
    if (w != null) {
      final lbs = kg ? w * 2.20462 : w;
      if (lbs >= 50 && lbs <= 800) {
        weights.add(ImportedWeight(at, double.parse(lbs.toStringAsFixed(1))));
        used = true;
      }
    }
    if (!used) skipped++;
  }
  return ImportResult(doses, weights, skipped);
}
