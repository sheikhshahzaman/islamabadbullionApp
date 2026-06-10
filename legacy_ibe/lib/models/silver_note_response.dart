class SilverNoteResponse {
  final bool success;
  final String noteEn;
  final String noteUr;
  final bool isActive;
  final String? updatedAt;

  SilverNoteResponse({
    required this.success,
    required this.noteEn,
    required this.noteUr,
    required this.isActive,
    this.updatedAt,
  });

  String noteFor(bool isUrdu) {
    final en = noteEn.trim();
    final ur = noteUr.trim();

    if (!isActive) return "";
    if (isUrdu) return ur.isNotEmpty ? ur : en;
    return en.isNotEmpty ? en : ur;
  }

  factory SilverNoteResponse.fromJson(Map<String, dynamic> json) {
    return SilverNoteResponse(
      success: json["success"] == true,
      noteEn: (json["note_en"] ?? "").toString(),
      noteUr: (json["note_ur"] ?? "").toString(),
      isActive: json["is_active"] == true,
      updatedAt: json["updated_at"]?.toString(),
    );
  }
}