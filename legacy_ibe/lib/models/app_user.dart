class AppUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String status;

  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.status,
  });

  String get fullName {
    final name = "$firstName $lastName".trim();
    return name.isEmpty ? email : name;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: int.tryParse("${json["id"] ?? 0}") ?? 0,
      firstName: "${json["first_name"] ?? ""}",
      lastName: "${json["last_name"] ?? ""}",
      email: "${json["email"] ?? ""}",
      phone: "${json["phone"] ?? ""}",
      status: "${json["status"] ?? "active"}",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "phone": phone,
      "status": status,
    };
  }
}