import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String token;
  final String? avatar;
  final String? avatarColor;
  final String? bio;
  final List<String>? skills;
  final bool isPremium;
  final DateTime? premiumValidUntil;

  bool get isPremiumActive =>
      isPremium && premiumValidUntil != null && premiumValidUntil!.isAfter(DateTime.now());

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.token,
    this.avatar,
    this.avatarColor,
    this.bio,
    this.skills,
    this.isPremium = false,
    this.premiumValidUntil,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? token,
    String? avatar,
    String? avatarColor,
    String? bio,
    List<String>? skills,
    bool? isPremium,
    DateTime? premiumValidUntil,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      avatarColor: avatarColor ?? this.avatarColor,
      bio: bio ?? this.bio,
      skills: skills ?? this.skills,
      isPremium: isPremium ?? this.isPremium,
      premiumValidUntil: premiumValidUntil ?? this.premiumValidUntil,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'token': token,
      'avatar': avatar,
      'avatarColor': avatarColor,
      'bio': bio,
      'skills': skills,
      'isPremium': isPremium,
      'premiumValidUntil': premiumValidUntil?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('User.fromMap: map cannot be null');
    }
    
    return User(
      id: map['_id']?.toString() ?? '', // MongoDB trả về _id
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
      avatar: map['avatar']?.toString() ?? '',
      avatarColor: map['avatarColor']?.toString(),
      bio: map['bio']?.toString(),
      skills: map['skills'] != null
          ? List<String>.from((map['skills'] as List).map((x) => x.toString()))
          : null,
      isPremium: map['isPremium'] == true,
      premiumValidUntil: map['premiumValidUntil'] != null
          ? DateTime.tryParse(map['premiumValidUntil'].toString())
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, password: $password, token: $token, avatar: $avatar, bio: $bio, skills: $skills, isPremium: $isPremium, premiumValidUntil: $premiumValidUntil)';
  }
}
