class HabbitLogModel {
  final String id;
  final String userId;
  final String habbitId;
  final DateTime date;
  final int value;
  final String note;
  final bool isCompleted;

  HabbitLogModel({
    required this.id,
    required this.userId,
    required this.habbitId,
    required this.date,
    required this.value,
    required this.isCompleted,
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'habbitId': habbitId,
      'date': date.toIso8601String(),
      'value': value,
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
      value: json['value'] as int,
      isCompleted: json['isCompleted'] as bool? ?? true,
      note: json['note'] as String? ?? '',
    );
  }
}
