class Activity {
  final int? id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String userId;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Activity({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.userId,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      userId: json['user_id'],
      category: json['category'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'user_id': userId,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}