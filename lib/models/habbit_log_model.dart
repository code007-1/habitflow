import 'package:habbit/models/unit_of_measure.dart';

class HabbitLogModel {
  final String id;
  final String userId;
  final String habbitId;
  final DateTime date;

  /// The logged amount, stored together with the [Unit] it was measured in.
  /// For binary habits this is `1` with the `done` unit.
  final double value;
  final String unitId;

  final String note;
  final bool isCompleted;

  HabbitLogModel({
    required this.id,
    required this.userId,
    required this.habbitId,
    required this.date,
    required this.value,
    required this.isCompleted,
    this.unitId = 'done',
    this.note = '',
  });

  /// The logged value as a [Measurement], enabling conversion/aggregation.
  Measurement get measurement => Measurement(value, Units.byId(unitId));

  /// A copy with selected fields replaced. [userId] and [habbitId] are fixed —
  /// a log never moves to another habit or owner.
  HabbitLogModel copyWith({
    String? id,
    DateTime? date,
    double? value,
    String? unitId,
    bool? isCompleted,
    String? note,
  }) {
    return HabbitLogModel(
      id: id ?? this.id,
      userId: userId,
      habbitId: habbitId,
      date: date ?? this.date,
      value: value ?? this.value,
      unitId: unitId ?? this.unitId,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'habbitId': habbitId,
      'date': date.toIso8601String(),
      'value': value,
      'unit': unitId,
      'note': note,
      'isCompleted': isCompleted,
    };
  }

  factory HabbitLogModel.fromJson(Map<String, dynamic> json) {
    return HabbitLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      habbitId: json['habbitId'] as String,
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toDouble(),
      unitId: json['unit'] as String? ?? 'done',
      isCompleted: json['isCompleted'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}
