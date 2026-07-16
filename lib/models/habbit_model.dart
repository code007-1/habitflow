import 'package:flutter/material.dart';
import 'package:habbit/models/habbit_log_model.dart';

class HabbitModel {
  final String id;
  final String name;
  final String description;
  final int iconCodePoint;
  final String frequency;
  final String type;
  final List<String> selectedDays;
  final int streak;
  final String progress;
  final int goalThreshold;

  HabbitModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCodePoint,
    required this.frequency,
    required this.type,
    this.selectedDays = const [],
    this.streak = 0,
    this.progress = '0 Ticks',
    this.goalThreshold = 1,
  });

  IconData get iconData => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'frequency': frequency,
      'type': type,
      'selectedDays': selectedDays,
      'streak': streak,
      'progress': progress,
      'goalThreshold': goalThreshold,
    };
  }

  factory HabbitModel.fromJson(Map<String, dynamic> json) {
    return HabbitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      frequency: json['frequency'] as String,
      type: json['type'] as String,
      selectedDays:
          (json['selectedDays'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      streak: json['streak'] as int? ?? 0,
      progress: json['progress'] as String? ?? '0 Ticks',
      goalThreshold: json['goalThreshold'] as int? ?? 1,
    );
  }
}
