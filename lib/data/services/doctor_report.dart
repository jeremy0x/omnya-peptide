import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_copy.dart';
import '../../domain/schedule.dart';
import '../repositories/protocol_repository.dart';

/// A plain record for her doctor: what she takes, what she logged, and her measurements.
/// Facts from her log only, no interpretation.
Future<Uint8List> buildDoctorReport(ProtocolRepository repo, DateTime now) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/InstrumentSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/InstrumentSans-SemiBold.ttf'));
  final day = DateFormat('MMM d, y');
  final from = addDays(dayOf(now), -89);
  final logs = repo.doseLogs.where((l) => !l.timestamp.isBefore(from)).toList();
  final checkIns = repo.checkIns.where((c) => !c.date.isBefore(from)).toList();
  String n(double? v) => v == null ? '' : v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');

  pw.Widget heading(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
    child: pw.Text(t, style: pw.TextStyle(font: bold, fontSize: 13)),
  );
  pw.Widget table(List<String> head, List<List<String>> rows) => rows.isEmpty
      ? pw.Text('None logged.', style: const pw.TextStyle(color: PdfColors.grey700))
      : pw.TableHelper.fromTextArray(
          headers: head,
          data: rows,
          headerStyle: pw.TextStyle(font: bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
        );

  final doc = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        pw.Text('Protocol log', style: pw.TextStyle(font: bold, fontSize: 20)),
        pw.Text(
          '${day.format(from)} to ${day.format(now)} · from the Omnya app',
          style: const pw.TextStyle(color: PdfColors.grey700),
        ),
        heading('Current compounds'),
        table(
          ['Compound', 'Dose', 'How often', 'Route', 'Started'],
          [
            for (final c in repo.compounds)
              [
                c.name,
                c.dose > 0 ? formatDose(c.dose, c.unit) : '',
                c.frequencyDays > 0 ? everyLabel(c.frequencyDays) : '',
                c.route,
                day.format(c.startDate),
              ],
          ],
        ),
        heading('Doses logged (last 90 days)'),
        table(
          ['Date', 'Compound', 'Dose', 'Site'],
          [
            for (final l in logs)
              [
                DateFormat('MMM d, y h:mm a').format(l.timestamp),
                l.compoundName,
                formatDose(l.dose, l.unit),
                l.injectionSite,
              ],
          ],
        ),
        heading('Check-ins (last 90 days)'),
        table(
          ['Date', 'Weight lb', 'Waist in', 'Sleep h', 'Energy', 'Appetite', 'Pain', 'Notes'],
          [
            for (final c in checkIns)
              [
                day.format(c.date),
                n(c.weightLbs),
                n(c.waistIn),
                n(c.sleepHours),
                c.energyLevel?.toString() ?? '',
                c.appetiteLevel?.toString() ?? '',
                c.pain?.toString() ?? '',
                [...c.sideEffects, if (c.periodStarted) 'Period started', if (c.notes.isNotEmpty) c.notes].join('; '),
              ],
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Text(AppCopy.medicalDisclaimer, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    ),
  );
  return doc.save();
}
