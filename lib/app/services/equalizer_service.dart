import 'dart:math';

import '../data/models/eq_filter.dart';
import '../data/models/frequency_response.dart';

/// A service class to encapsulate the AutoEQ and Biquad filter logic.
class EqualizerService {
  // Configuration constants, ported from JavaScript
  static const double defaultSampleRate = 48000.0;
  static const double trebleStartFrom = 7000.0;
  static const List<double> autoEqRange = [20.0, 15000.0];
  static const List<double> optimizeQRange = [0.5, 2.0];
  static const List<double> optimizeGainRange = [-12.0, 12.0];
  static const List<List<double>> optimizeDeltas = [
    [10.0, 10.0, 10.0, 5.0, 0.1, 0.5],
    [10.0, 10.0, 10.0, 2.0, 0.1, 0.2],
    [10.0, 10.0, 10.0, 1.0, 0.1, 0.1],
  ];

  static final List<double> graphicEqRawFrequencies = List.generate(
    (log(20000 / 20) / log(1.0072)).ceil(),
    (i) => 20 * pow(1.0072, i).toDouble(),
  );

  static final List<double> graphicEqFrequencies =
      Set<double>.from(
          List.generate(
            (log(20000 / 20) / log(1.0563)).ceil(),
            (i) => (20 * pow(1.0563, i)).floorToDouble(),
          ),
        ).toList()
        ..sort((a, b) => a.compareTo(b));

  /// Interpolates frequency response values.
  List<DataPoint> interp(List<double> fv, List<DataPoint> fr) {
    int i = 0;
    return fv.map((f) {
      for (; i < fr.length - 1; ++i) {
        DataPoint dp0 = fr[i];
        DataPoint dp1 = fr[i + 1];

        if (i == 0 && f < dp0.frequency) {
          return DataPoint(frequency: f, db: dp0.db);
        } else if (f >= dp0.frequency && f < dp1.frequency) {
          double v =
              dp0.db +
              (dp1.db - dp0.db) *
                  (f - dp0.frequency) /
                  (dp1.frequency - dp0.frequency);
          return DataPoint(frequency: f, db: v);
        }
      }
      return DataPoint(frequency: f, db: fr[fr.length - 1].db);
    }).toList();
  }

  /// Calculates coefficients for a lowshelf filter.
  List<double> lowshelf(
    double freq,
    double q,
    double gain, [
    double? sampleRate,
  ]) {
    sampleRate ??= defaultSampleRate;
    freq = freq / sampleRate;
    freq = max(1e-6, min(freq, 1.0));
    q = max(1e-4, min(q, 1000.0));
    gain = max(-40.0, min(gain, 40.0));

    double w0 = 2 * pi * freq;
    double sinW0 = sin(w0);
    double cosW0 = cos(w0);
    double a = pow(10, (gain / 40)).toDouble();
    double alpha = sinW0 / (2 * q);
    double alphaMod = (2 * sqrt(a) * alpha);

    double a0 = ((a + 1) + (a - 1) * cosW0 + alphaMod);
    double a1 = -2 * ((a - 1) + (a + 1) * cosW0);
    double a2 = ((a + 1) + (a - 1) * cosW0 - alphaMod);
    double b0 = a * ((a + 1) - (a - 1) * cosW0 + alphaMod);
    double b1 = 2 * a * ((a - 1) - (a + 1) * cosW0);
    double b2 = a * ((a + 1) - (a - 1) * cosW0 - alphaMod);

    return [1.0, a1 / a0, a2 / a0, b0 / a0, b1 / a0, b2 / a0];
  }

  /// Calculates coefficients for a highshelf filter.
  List<double> highshelf(
    double freq,
    double q,
    double gain, [
    double? sampleRate,
  ]) {
    sampleRate ??= defaultSampleRate;
    freq = freq / sampleRate;
    freq = max(1e-6, min(freq, 1.0));
    q = max(1e-4, min(q, 1000.0));
    gain = max(-40.0, min(gain, 40.0));

    double w0 = 2 * pi * freq;
    double sinW0 = sin(w0);
    double cosW0 = cos(w0);
    double a = pow(10, (gain / 40)).toDouble();
    double alpha = sinW0 / (2 * q);
    double alphaMod = (2 * sqrt(a) * alpha);

    double a0 = ((a + 1) - (a - 1) * cosW0 + alphaMod);
    double a1 = 2 * ((a - 1) - (a + 1) * cosW0);
    double a2 = ((a + 1) - (a - 1) * cosW0 - alphaMod);
    double b0 = a * ((a + 1) + (a - 1) * cosW0 + alphaMod);
    double b1 = -2 * a * ((a - 1) + (a + 1) * cosW0);
    double b2 = a * ((a + 1) + (a - 1) * cosW0 - alphaMod);

    return [1.0, a1 / a0, a2 / a0, b0 / a0, b1 / a0, b2 / a0];
  }

  /// Calculates coefficients for a peaking filter.
  List<double> peaking(
    double freq,
    double q,
    double gain, [
    double? sampleRate,
  ]) {
    sampleRate ??= defaultSampleRate;
    freq = freq / sampleRate;
    freq = max(1e-6, min(freq, 1.0));
    q = max(1e-4, min(q, 1000.0));
    gain = max(-40.0, min(gain, 40.0));

    double w0 = 2 * pi * freq;
    double sinW0 = sin(w0);
    double cosW0 = cos(w0);
    double a = pow(10, (gain / 40)).toDouble();
    double alpha = sinW0 / (2 * q);

    double a0 = 1 + alpha / a;
    double a1 = -2 * cosW0;
    double a2 = 1 - alpha / a;
    double b0 = 1 + alpha * a;
    double b1 = -2 * cosW0;
    double b2 = 1 - alpha * a;

    return [1.0, a1 / a0, a2 / a0, b0 / a0, b1 / a0, b2 / a0];
  }

  /// Calculates gains for a set of frequencies given filter coefficients.
  List<double> calcGains(
    List<double> freqs,
    List<List<double>> coeffs, [
    double? sampleRate,
  ]) {
    sampleRate ??= defaultSampleRate;
    List<double> gains = List.filled(freqs.length, 0.0);

    for (int i = 0; i < coeffs.length; ++i) {
      List<double> coeff = coeffs[i];
      double a0 = coeff[0];
      double a1 = coeff[1];
      double a2 = coeff[2];
      double b0 = coeff[3];
      double b1 = coeff[4];
      double b2 = coeff[5];

      for (int j = 0; j < freqs.length; ++j) {
        double w = 2 * pi * freqs[j] / sampleRate;
        double phi = 4 * pow(sin(w / 2), 2).toDouble();
        double c =
            (10 *
                    log(
                      pow(b0 + b1 + b2, 2) +
                          (b0 * b2 * phi - (b1 * (b0 + b2) + 4 * b0 * b2)) *
                              phi,
                    ) -
                10 *
                    log(
                      pow(a0 + a1 + a2, 2) +
                          (a0 * a2 * phi - (a1 * (a0 + a2) + 4 * a0 * a2)) *
                              phi,
                    ));
        gains[j] += c;
      }
    }
    return gains;
  }

  /// Calculates the pre-amp gain needed to prevent clipping.
  double calcPreamp(List<DataPoint> fr1, List<DataPoint> fr2) {
    double maxGain = -double.infinity;
    for (int i = 0; i < fr1.length; ++i) {
      maxGain = max(maxGain, fr2[i].db - fr1[i].db);
    }
    return -maxGain;
  }

  /// Applies a list of filters to a frequency response.
  List<DataPoint> applyFilters(
    List<DataPoint> fr,
    List<EqFilter> filters, [
    double? sampleRate,
  ]) {
    List<double> freqs = fr.map((e) => e.frequency).toList();
    List<List<double>> coeffs = filtersToCoeffs(filters, sampleRate);
    List<double> gains = calcGains(freqs, coeffs, sampleRate);
    // Initialize with correct length and default values
    List<DataPoint> frEq = List.generate(
      fr.length,
      (index) => DataPoint(frequency: 0, db: 0),
    );
    for (int i = 0; i < fr.length; ++i) {
      frEq[i] = DataPoint(frequency: fr[i].frequency, db: fr[i].db + gains[i]);
    }
    return frEq;
  }

  /// Converts EqFilters to biquad coefficients.
  List<List<double>> filtersToCoeffs(
    List<EqFilter> filters, [
    double? sampleRate,
  ]) {
    return filters
        .map((f) {
          if (!f.isEnabled) return null; // Only enabled filters
          if (f.freq == 0 || f.gain == 0 || f.q == 0) {
            return null;
          } else if (f.type == FilterType.LSQ) {
            return lowshelf(f.freq, f.q, f.gain, sampleRate);
          } else if (f.type == FilterType.HSQ) {
            return highshelf(f.freq, f.q, f.gain, sampleRate);
          } else if (f.type == FilterType.PK) {
            return peaking(f.freq, f.q, f.gain, sampleRate);
          }
          return null;
        })
        .whereType<List<double>>()
        .toList();
  }

  /// Calculates the distance between two frequency responses.
  double calcDistance(List<DataPoint> fr1, List<DataPoint> fr2) {
    double distance = 0;
    for (int i = 0; i < fr1.length; ++i) {
      double d = (fr1[i].db - fr2[i].db).abs();
      distance += (d >= 0.1 ? d : 0);
    }
    return distance / fr1.length;
  }

  /// Searches for candidate filters based on the difference between two frequency responses.
  List<EqFilter> searchCandidates(
    List<DataPoint> fr,
    List<DataPoint> frTarget,
    double threshold,
  ) {
    int state = 0; // 1: peak, 0: matched, -1: dip
    int startIndex = -1;
    List<EqFilter> candidates = [];
    double minFreq = autoEqRange[0];
    double maxFreq = autoEqRange[1];

    for (int i = 0; i < fr.length; ++i) {
      DataPoint dp = fr[i];
      DataPoint dpTarget = frTarget[i];
      double f = dp.frequency;
      double v0 = dp.db;
      double v1 = dpTarget.db;
      double delta = v0 - v1;
      double deltaAbs = delta.abs();
      int nextState = (deltaAbs < threshold) ? 0 : (delta / deltaAbs).round();

      if (nextState == state) {
        continue;
      }
      if (startIndex >= 0) {
        if (state != 0) {
          double start = fr[startIndex].frequency;
          double end = f;
          double center = sqrt(start * end);
          // Interpolate to get values at the center frequency
          List<DataPoint> interpolatedTarget = interp([
            center,
          ], frTarget.sublist(startIndex, i));
          List<DataPoint> interpolatedCurrent = interp([
            center,
          ], fr.sublist(startIndex, i));

          double gain = interpolatedTarget[0].db - interpolatedCurrent[0].db;
          double q = center / (end - start);
          if (center >= minFreq && center <= maxFreq) {
            candidates.add(
              EqFilter(
                type: FilterType.PK,
                freq: center,
                q: q,
                gain: gain,
                isEnabled: true,
              ),
            );
          }
        }
        startIndex = -1;
      } else {
        startIndex = i;
      }
      state = nextState;
    }
    return candidates;
  }

  /// Calculates the frequency unit for rounding.
  double freqUnit(double freq) {
    if (freq < 100) {
      return 1;
    } else if (freq < 1000) {
      return 10;
    } else if (freq < 10000) {
      return 100;
    }
    return 1000;
  }

  /// Strips and normalizes filter parameters.
  List<EqFilter> stripFilters(List<EqFilter> filters) {
    double minQ = optimizeQRange[0];
    double maxQ = optimizeQRange[1];
    double minGain = optimizeGainRange[0];
    double maxGain = optimizeGainRange[1];

    return filters
        .map(
          (f) => EqFilter(
            type: f.type,
            freq: (f.freq - (f.freq % freqUnit(f.freq))).floorToDouble(),
            q: min(max((f.q * 10).floorToDouble() / 10, minQ), maxQ),
            gain: min(
              max((f.gain * 10).floorToDouble() / 10, minGain),
              maxGain,
            ),
            isEnabled: f.isEnabled,
          ),
        )
        .toList();
  }

  /// Optimizes a list of filters to reduce the distance to the target.
  List<EqFilter> optimize(
    List<DataPoint> fr,
    List<DataPoint> frTarget,
    List<EqFilter> filters,
    int iteration, [
    int? dir,
  ]) {
    filters = stripFilters(filters);
    double minFreq = autoEqRange[0];
    double maxFreq = autoEqRange[1];
    double minQ = optimizeQRange[0];
    double maxQ = optimizeQRange[1];
    double minGain = optimizeGainRange[0];
    double maxGain = optimizeGainRange[1];

    List<double> deltaConfig = optimizeDeltas[iteration];
    double maxDF = deltaConfig[0];
    double maxDQ = deltaConfig[1];
    double maxDG = deltaConfig[2];
    double stepDF = deltaConfig[3];
    double stepDQ = deltaConfig[4];
    double stepDG = deltaConfig[5];

    int begin = (dir != null && dir == 1) ? filters.length - 1 : 0;
    int end = (dir != null && dir == 1) ? -1 : filters.length;
    int step = (dir != null && dir == 1) ? -1 : 1;

    List<EqFilter> currentFilters = List.from(filters);

    for (int i = begin; i != end; i += step) {
      EqFilter f = currentFilters[i];
      List<EqFilter> filtersWithoutCurrent =
          currentFilters
              .asMap()
              .entries
              .where((entry) => entry.key != i)
              .map((entry) => entry.value)
              .toList();
      List<DataPoint> fr1 = applyFilters(fr, filtersWithoutCurrent);

      EqFilter bestFilter = f;
      double bestDistance = calcDistance(applyFilters(fr1, [f]), frTarget);

      bool testNewFilter(double df, double dq, double dg) {
        double newFreq = f.freq + df * freqUnit(f.freq) * stepDF;
        double newQ = f.q + dq * stepDQ;
        double newGain = f.gain + dg * stepDG;

        if (newFreq < minFreq ||
            newFreq > maxFreq ||
            newQ < minQ ||
            newQ > maxQ ||
            newGain < minGain ||
            newGain > maxGain) {
          return false;
        }

        EqFilter newFilter = EqFilter(
          type: f.type,
          freq: newFreq,
          q: newQ,
          gain: newGain,
          isEnabled: true,
        );
        double newDistance = calcDistance(
          applyFilters(fr1, [newFilter]),
          frTarget,
        );

        if (newDistance < bestDistance) {
          bestFilter = newFilter;
          bestDistance = newDistance;
          return true;
        }
        return false;
      }

      for (double df = -maxDF; df <= maxDF; ++df) {
        for (double dq = maxDQ - 1; dq >= -maxDQ; --dq) {
          for (double dg = 1; dg <= maxDG; ++dg) {
            if (!testNewFilter(df, dq, dg)) {
              break;
            }
          }
          for (double dg = -1; dg >= -maxDG; --dg) {
            if (!testNewFilter(df, dq, dg)) {
              break;
            }
          }
        }
      }
      currentFilters[i] = bestFilter;
    }

    if (dir == null) {
      return optimize(fr, frTarget, currentFilters, iteration, 1);
    } else {
      currentFilters.sort((a, b) => a.freq.compareTo(b.freq));

      // Merge closed filters
      for (int i = 0; i < currentFilters.length - 1;) {
        EqFilter f1 = currentFilters[i];
        EqFilter f2 = currentFilters[i + 1];
        if ((f1.freq - f2.freq).abs() <= freqUnit(f1.freq) &&
            (f1.q - f2.q).abs() <= 0.1) {
          currentFilters[i] = f1.copyWith(gain: f1.gain + f2.gain);
          currentFilters.removeAt(i + 1);
        } else {
          ++i;
        }
      }

      // Remove unnecessary filters
      double bestOverallDistance = calcDistance(
        applyFilters(fr, currentFilters),
        frTarget,
      );
      for (int i = 0; i < currentFilters.length;) {
        if (currentFilters[i].gain.abs() <= 0.1) {
          currentFilters.removeAt(i);
          continue;
        }
        List<EqFilter> filtersWithoutCurrent =
            currentFilters
                .asMap()
                .entries
                .where((entry) => entry.key != i)
                .map((entry) => entry.value)
                .toList();
        double newDistance = calcDistance(
          applyFilters(fr, filtersWithoutCurrent),
          frTarget,
        );
        if (newDistance < bestOverallDistance) {
          currentFilters.removeAt(i);
          bestOverallDistance = newDistance;
        } else {
          ++i;
        }
      }
      return currentFilters;
    }
  }

  /// Performs the AutoEQ process.
  List<EqFilter> autoEq(
    List<DataPoint> fr,
    List<DataPoint> frTarget,
    int maxFilters,
  ) {
    // 2 steps manual optimized algorithm
    // fr, frTarget should has same resolution and normalized
    int firstBatchSize = max((maxFilters / 2).floor() - 1, 1);
    List<EqFilter> firstCandidates = searchCandidates(fr, frTarget, 1.0);
    List<EqFilter> firstFilters =
        (firstCandidates
                // Dont adjust treble in the first batch
                .where((c) => c.freq <= trebleStartFrom)
                // Wider bandwidth (smaller Q) come first
                .toList()
              ..sort((a, b) => a.q.compareTo(b.q)))
            .take(firstBatchSize)
            .toList()
          ..sort((a, b) => a.freq.compareTo(b.freq));

    for (int i = 0; i < optimizeDeltas.length; ++i) {
      firstFilters = optimize(fr, frTarget, firstFilters, i);
    }

    List<DataPoint> secondFR = applyFilters(fr, firstFilters);
    int secondBatchSize = maxFilters - firstFilters.length;
    List<EqFilter> secondCandidates = searchCandidates(secondFR, frTarget, 0.5);
    List<EqFilter> secondFilters =
        (secondCandidates.toList()..sort((a, b) => a.q.compareTo(b.q)))
            .take(secondBatchSize)
            .toList()
          ..sort((a, b) => a.freq.compareTo(b.freq));

    for (int i = 0; i < optimizeDeltas.length; ++i) {
      secondFilters = optimize(secondFR, frTarget, secondFilters, i);
    }
    List<EqFilter> allFilters = [...firstFilters, ...secondFilters];

    for (int i = 0; i < optimizeDeltas.length; ++i) {
      allFilters = optimize(fr, frTarget, allFilters, i);
    }
    return stripFilters(allFilters);
  }
}
