class HabbitLogModel {
  final String id;
  final DateTime date;
  final int value;
  final String note;
  final bool isCompleted;

  HabbitLogModel({
    required this.id,
    required this.date,
    required this.value,
    required this.isCompleted,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'value': value,
      'note': note,
      'isCompleted': isCompleted,
    };
  }

  factory HabbitLogModel.fromJson(Map<String, dynamic> json) {
    return HabbitLogModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      value: json['value'] as int,
      isCompleted: json['isCompleted'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}
