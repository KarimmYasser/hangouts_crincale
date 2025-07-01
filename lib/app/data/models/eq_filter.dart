/// Enum for the types of EQ filters available.
enum FilterType {
  PK,  // Peaking filter
  LSQ, // Low-shelf filter
  HSQ, // High-shelf filter
}

/// Represents a single parametric equalizer filter/band.
class EqFilter {
  final bool isEnabled;
  final FilterType type;
  final double freq; // Frequency in Hz
  final double gain; // Gain in dB
  final double q;    // Q-factor (bandwidth)

  EqFilter({
    this.isEnabled = true,
    required this.type,
    required this.freq,
    required this.gain,
    required this.q,
  });

  // Helper method to easily create a modified copy of a filter.
  // This is useful for updating state immutably.
  EqFilter copyWith({
    bool? isEnabled,
    FilterType? type,
    double? freq,
    double? gain,
    double? q,
  }) {
    return EqFilter(
      isEnabled: isEnabled ?? this.isEnabled,
      type: type ?? this.type,
      freq: freq ?? this.freq,
      gain: gain ?? this.gain,
      q: q ?? this.q,
    );
  }
}