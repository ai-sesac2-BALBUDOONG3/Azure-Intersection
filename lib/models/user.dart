class User {
  final int id;
  final String name;
  final int birthYear;
  final String region;
  final String school;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.name,
    required this.birthYear,
    required this.region,
    required this.school,
    this.profileImageUrl,
  });

  /// JSON → User 변환
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],                                      // int
      name: json["name"],
      birthYear: json["birth_year"] ?? json["birthYear"] ?? 0,
      region: json["region"],
      school: json["school_name"] ?? json["school"] ?? "",
      profileImageUrl: json["profile_image"],
    );
  }

  /// User → JSON 변환 (필요하면 사용)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "birth_year": birthYear,
      "region": region,
      "school_name": school,
      "profile_image": profileImageUrl,
    };
  }
}
