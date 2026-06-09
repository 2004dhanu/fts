class User {
  final String? fullName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? chapterName;

  User({
    this.fullName,
    this.username,
    this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.chapterName,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'chapter_name': chapterName,
    };
  }
}