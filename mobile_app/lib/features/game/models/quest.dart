class Quest {
  final String title;
  final String description;
  final String status;
  final List<Quest>? sideQuests;

  Quest({
    required this.title,
    required this.description,
    required this.status,
    this.sideQuests,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      title: json['title'] ?? 'Unnamed Quest',
      description: json['description'] ?? '',
      status: json['status'] ?? 'unknown',
      sideQuests: json['sideQuests'] != null
          ? (json['sideQuests'] as List).map((sq) => Quest.fromJson(sq)).toList()
          : null,
    );
  }
}
