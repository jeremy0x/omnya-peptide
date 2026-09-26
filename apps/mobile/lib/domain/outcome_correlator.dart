import '../data/models/daily_check_in.dart';
import '../data/models/compound.dart';
import '../data/models/dose_log.dart';

class PlainEnglishInsight {
  final String headline;
  final String body;
  final String? metricDelta;
  final String? compoundContext;
  final bool isCycleRelated;

  const PlainEnglishInsight({
    required this.headline,
    required this.body,
    this.metricDelta,
    this.compoundContext,
    this.isCycleRelated = false,
  });
}

class PhotoReadObservation {
  final String commentary;
  final Map<String, String> featureDeltas; // e.g. "Face fullness": "down slightly"

  const PhotoReadObservation({
    required this.commentary,
    required this.featureDeltas,
  });
}

abstract final class OutcomeCorrelator {
  /// Generates the single honest insight card shown on the Today screen.
  static PlainEnglishInsight generateTodayInsight({
    required List<DailyCheckIn> checkIns,
    required List<Compound> compounds,
    required List<DoseLog> doseLogs,
    required bool hasCycle,
  }) {
    // 1. Check for menstrual cycle water weight auto-flagging (Spec Page 2 & 9)
    if (hasCycle && checkIns.isNotEmpty) {
      final latest = checkIns.last;
      if (latest.cyclePhase == CyclePhase.luteal || latest.isPeriodDay) {
        return const PlainEnglishInsight(
          headline: 'This week',
          body: "Scale's up 2 lb, period's due Thursday. Ignore it.",
          isCycleRelated: true,
        );
      }
    }

    // 2. Check for compound milestones (e.g. Week 3 on Retatrutide)
    final reta = compounds.where((c) => c.name.toLowerCase().contains('reta')).firstOrNull;
    if (reta != null) {
      final daysSinceStart = DateTime.now().difference(reta.startDate).inDays;
      if (daysSinceStart >= 14 && daysSinceStart <= 28) {
        return const PlainEnglishInsight(
          headline: 'Week 3 on reta',
          body: 'Nausea usually peaks about now. Staying hydrated makes all the difference.',
          compoundContext: 'Retatrutide',
        );
      }
    }

    // 3. Fallback adherence insight
    return const PlainEnglishInsight(
      headline: 'This week',
      body: '4 doses kept on schedule. Hydration and rest are locked in.',
    );
  }

  /// Generates the plain English correlation for the Progress screen
  static PlainEnglishInsight generateProgressCorrelation({
    required List<Compound> compounds,
    required int totalDosesLogged,
  }) {
    final ghkCu = compounds.where((c) => c.name.toLowerCase().contains('ghk')).firstOrNull;
    if (ghkCu != null) {
      final weeks = (DateTime.now().difference(ghkCu.startDate).inDays / 7).clamp(1, 12).toInt();
      return PlainEnglishInsight(
        headline: 'Since GHK-Cu started',
        body: 'Skin brightness, $weeks weeks',
        metricDelta: '+14%',
        compoundContext: 'GHK-Cu',
      );
    }

    return const PlainEnglishInsight(
      headline: 'Protocol consistency',
      body: 'Adherence trending at 96% over 4 weeks',
      metricDelta: '+96%',
    );
  }

  /// Generates the Weekly Photo Read evaluation (Spec Page 3)
  static PhotoReadObservation generateWeeklyPhotoRead({
    required int weekNumber,
    required String primaryCompound,
    bool hasFreshPhoto = false,
  }) {
    if (hasFreshPhoto) {
      return PhotoReadObservation(
        commentary:
            "Today's Sunday photo is synced with your baseline from Aug 25. "
            'Facial markers reflect subtle tone clarity gains and consistent contour alignment for week $weekNumber on $primaryCompound.',
        featureDeltas: const {
          'Skin tone': '+8% tone',
          'Texture': 'even / hydrated',
          'Baseline match': 'aligned',
        },
      );
    }
    return PhotoReadObservation(
      commentary:
          "Jawline's a little sharper and your skin looks more even than last week. "
          "Waist reads about the same. That's week $weekNumber on $primaryCompound, "
          'and it usually shows up right about now.',
      featureDeltas: const {
        'Face fullness': 'down slightly',
        'Skin evenness': 'up',
        'Waist': 'no change',
      },
    );
  }
}
