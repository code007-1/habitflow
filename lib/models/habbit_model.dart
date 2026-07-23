import 'package:flutter/material.dart';
import 'package:habbit/core/constants/selectable_icons.dart';
import 'package:habbit/models/unit_of_measure.dart';

class HabbitModel {
  final String id;
  final String name;
  final String description;
  final int icon;

  /// Interval frequency of the habit: 'Daily' / 'Weekly' / 'Custom'.
  final String intervalFrequency;

  /// What the habit is measured in — see [Units].
  /// [dimensionId] is a [Dimension] id ('binary', 'count', 'length', …) and
  /// [unitId] is the goal's [Unit] id ('done', 'times', 'km', …).
  final String dimensionId;
  final double goalValue;
  final String unitId;

  final List<String> selectedDays;
  final int streak;
  final String progress;

  HabbitModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.intervalFrequency,
    required this.dimensionId,
    this.goalValue = 1,
    this.unitId = 'done',
    this.selectedDays = const [],
    this.streak = 0,
    this.progress = '0 Ticks',
  });

  // ── Unit-of-measure helpers ────────────────────────────────────────────────
  Dimension get dimension => Units.dimensionById(dimensionId);
  Unit get unit => Units.byId(unitId);

  /// The target the user is aiming for, as a [Measurement] (e.g. `2 L`).
  Measurement get goal => Measurement(goalValue, unit);

  /// A yes/no habit has no numeric goal — just done or not done.
  bool get isBinary => dimensionId == Units.binary.id;

  IconData get iconData {
    return selectable_icons.firstWhere(
      (icon) => icon.codePoint == this.icon,
      orElse: () => Icons.water_drop_rounded,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon,
      'frequency': intervalFrequency,
      'dimension': dimensionId,
      'goalValue': goalValue,
      'unit': unitId,
      'selectedDays': selectedDays,
      'streak': streak,
      'progress': progress,
    };
  }

  factory HabbitModel.fromJson(Map<String, dynamic> json) {
    return HabbitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['iconCodePoint'] as int,
      intervalFrequency: json['frequency'] as String,
      dimensionId: json['dimension'] as String? ?? Units.binary.id,
      goalValue: (json['goalValue'] as num?)?.toDouble() ?? 1,
      unitId: json['unit'] as String? ?? Units.done.id,
      selectedDays:
          (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      streak: json['streak'] as int? ?? 0,
      progress: json['progress'] as String? ?? '0 Ticks',
    );
  }
}
