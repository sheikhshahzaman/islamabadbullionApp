class HeadlineItem {
  final int id;
  final String en;
  final String ur;

  HeadlineItem({required this.id, required this.en, required this.ur});

  factory HeadlineItem.fromJson(Map<String, dynamic> json) {
    return HeadlineItem(
      id: (json["id"] ?? 0) as int,
      en: (json["en"] ?? "") as String,
      ur: (json["ur"] ?? "") as String,
    );
  }
}