class User {
  String email;
  String password;
  String fullName;
  String phone;
  String bio;
  DateTime? birthDate;
  String gender;
  bool rememberMe;

  User({
    required this.email,
    required this.password,
    this.fullName = '',
    this.phone = '',
    this.bio = '',
    this.birthDate,
    this.gender = 'Laki-laki',
    this.rememberMe = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'rememberMe': rememberMe,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email']?.toString() ?? '', // HANDLE NULL
      password: json['password']?.toString() ?? '', // HANDLE NULL
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      birthDate: json['birthDate'] != null && json['birthDate'] is String
          ? DateTime.tryParse(json['birthDate']) // GUNAKAN tryParse
          : null,
      gender: json['gender']?.toString() ?? 'Laki-laki',
      rememberMe: json['rememberMe'] == true,
    );
  }
}