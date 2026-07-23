/// A robust, extensible unit-of-measure system for habits.
///
/// Three concepts, converted through a single canonical base unit per
/// dimension (so conversions are O(N) data, never pairwise):
///   • [Dimension]   – the kind of quantity (Distance, Weight, Volume, …)
///   • [Unit]        – a unit within a dimension + its affine transform to base
///   • [Measurement] – an immutable value + unit (what a habit log stores)
///
/// To add a unit: append one `const` in [Units] and add it to [Units.all].
/// To add a dimension: add a [Dimension] and its units. Nothing else changes.
library;

/// The kind of quantity being measured. The stable [id] is what gets persisted.
class Dimension {
  final String id; // 'length', 'mass', … — serialization key, never change it
  final String label; // 'Distance', 'Weight' — for the UI

  const Dimension(this.id, this.label);

  @override
  bool operator ==(Object other) => other is Dimension && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A unit within a [dimension]. Converts via a single canonical base unit
/// using an affine transform: `base = value * toBaseFactor + offset`.
///
/// Most units are purely linear, so [offset] defaults to 0 and the transform
/// collapses to a plain multiplication. Units that need a shift (e.g. °C → K
/// adds 273.15) just set [offset]. Only reach for a subclass if a unit's
/// conversion is genuinely non-linear (logarithmic scales like decibels or pH),
/// where the formula shape itself differs — an offset can't express that.
class Unit {
  final String id; // 'km', 'kg', 'ml' — stable, for JSON
  final String name; // 'Kilometer'
  final String symbol; // 'km'
  final Dimension dimension;
  final double toBaseFactor; // multiply a value by this to reach the base unit
  final double offset; // additive shift toward the base unit (0 for linear)

  const Unit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.dimension,
    required this.toBaseFactor,
    this.offset = 0,
  });

  /// The canonical unit of a dimension: no scaling and no shift.
  bool get isBase => toBaseFactor == 1 && offset == 0;

  double toBase(double value) => value * toBaseFactor + offset;
  double fromBase(double baseValue) => (baseValue - offset) / toBaseFactor;

  @override
  bool operator ==(Object other) => other is Unit && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// An immutable value + unit. This is what a habit log actually stores.
class Measurement implements Comparable<Measurement> {
  final double value;
  final Unit unit;

  const Measurement(this.value, this.unit);

  Dimension get dimension => unit.dimension;

  /// The value expressed in the dimension's canonical base unit.
  double get baseValue => unit.toBase(value);

  /// Convert to another unit of the **same** dimension.
  Measurement convertTo(Unit target) {
    assert(
      target.dimension == unit.dimension,
      'Cannot convert ${unit.dimension.label} to ${target.dimension.label}',
    );
    return Measurement(target.fromBase(baseValue), target);
  }

  /// Add another measurement (converted through the base unit). Result keeps
  /// this measurement's unit.
  Measurement operator +(Measurement other) =>
      Measurement(unit.fromBase(baseValue + other.baseValue), unit);

  @override
  int compareTo(Measurement other) => baseValue.compareTo(other.baseValue);

  /// A short display string, e.g. "5 km" or "1.5 L".
  String format() {
    final v = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return unit.symbol.isEmpty ? v : '$v ${unit.symbol}';
  }

  Map<String, dynamic> toJson() => {'value': value, 'unit': unit.id};

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    (json['value'] as num).toDouble(),
    Units.byId(json['unit'] as String),
  );
}

/// The registry of every dimension and unit the app knows about.
/// This is the extensibility point — add here, and conversion, serialization
/// and UI listing all pick it up for free.
class Units {
  Units._();

  // ── Dimensions ────────────────────────────────────────────────────────────
  static const length = Dimension('length', 'Distance');
  static const mass = Dimension('mass', 'Weight');
  static const volume = Dimension('volume', 'Volume');
  static const time = Dimension('time', 'Time');
  static const count = Dimension('count', 'Count');
  static const binary = Dimension('binary', 'Yes / No');

  static const dimensions = [length, mass, volume, time, count, binary];

  // ── Length (base: meter) ──────────────────────────────────────────────────
  static const meter = Unit(
    id: 'm',
    name: 'Meter',
    symbol: 'm',
    dimension: length,
    toBaseFactor: 1,
  );
  static const kilometer = Unit(
    id: 'km',
    name: 'Kilometer',
    symbol: 'km',
    dimension: length,
    toBaseFactor: 1000,
  );
  static const mile = Unit(
    id: 'mi',
    name: 'Mile',
    symbol: 'mi',
    dimension: length,
    toBaseFactor: 1609.344,
  );

  // ── Mass / Weight (base: gram) ────────────────────────────────────────────
  static const gram = Unit(
    id: 'g',
    name: 'Gram',
    symbol: 'g',
    dimension: mass,
    toBaseFactor: 1,
  );
  static const kilogram = Unit(
    id: 'kg',
    name: 'Kilogram',
    symbol: 'kg',
    dimension: mass,
    toBaseFactor: 1000,
  );
  static const pound = Unit(
    id: 'lb',
    name: 'Pound',
    symbol: 'lb',
    dimension: mass,
    toBaseFactor: 453.59237,
  );

  // ── Volume (base: milliliter) ─────────────────────────────────────────────
  static const milliliter = Unit(
    id: 'ml',
    name: 'Milliliter',
    symbol: 'ml',
    dimension: volume,
    toBaseFactor: 1,
  );
  static const liter = Unit(
    id: 'l',
    name: 'Liter',
    symbol: 'L',
    dimension: volume,
    toBaseFactor: 1000,
  );

  // ── Time (base: second) ───────────────────────────────────────────────────
  static const second = Unit(
    id: 'sec',
    name: 'Second',
    symbol: 's',
    dimension: time,
    toBaseFactor: 1,
  );
  static const minute = Unit(
    id: 'min',
    name: 'Minute',
    symbol: 'min',
    dimension: time,
    toBaseFactor: 60,
  );
  static const hour = Unit(
    id: 'hr',
    name: 'Hour',
    symbol: 'h',
    dimension: time,
    toBaseFactor: 3600,
  );

  // ── Count (base: a plain tally, dimensionless) ────────────────────────────
  static const times = Unit(
    id: 'times',
    name: 'Times',
    symbol: '×',
    dimension: count,
    toBaseFactor: 1,
  );

  // ── Binary (done / not done — a single unitless 0-or-1 measure) ────────────
  static const done = Unit(
    id: 'done',
    name: 'Done',
    symbol: '',
    dimension: binary,
    toBaseFactor: 1,
  );

  /// Every registered unit. Add new units here.
  static const all = [
    meter, kilometer, mile, // length
    gram, kilogram, pound, // mass
    milliliter, liter, // volume
    second, minute, hour, // time
    times, // count
    done, // binary
  ];

  static final Map<String, Unit> _byId = {for (final u in all) u.id: u};
  static final Map<String, Dimension> _dimById = {
    for (final d in dimensions) d.id: d,
  };

  /// Look up a unit by its stable id (used when deserializing).
  static Unit byId(String id) => _byId[id]!;

  /// Look up a dimension by its stable id (used when deserializing).
  static Dimension dimensionById(String id) => _dimById[id]!;

  /// All units belonging to a dimension (for populating pickers).
  static List<Unit> forDimension(Dimension d) =>
      all.where((u) => u.dimension == d).toList();

  /// The canonical base unit of a dimension.
  static Unit baseUnitOf(Dimension d) =>
      all.firstWhere((u) => u.dimension == d && u.isBase);
}
