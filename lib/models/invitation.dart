import 'dart:convert';

class Invitation {
  final String id;
  final String email;
  final String projectId;
  final String invitedBy;
  final String? invitedUser;
  final String status;
  final String? message;
  final DateTime expiresAt;
  final String token;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated fields
  final ProjectInfo? project;
  final UserInfo? invitedByUser;
  final UserInfo? invitedUserInfo;

  Invitation({
    required this.id,
    required this.email,
    required this.projectId,
    required this.invitedBy,
    this.invitedUser,
    required this.status,
    this.message,
    required this.expiresAt,
    required this.token,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
    this.project,
    this.invitedByUser,
    this.invitedUserInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'projectId': projectId,
      'invitedBy': invitedBy,
      'invitedUser': invitedUser,
      'status': status,
      'message': message,
      'expiresAt': expiresAt.toIso8601String(),
      'token': token,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Invitation.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('Invitation.fromMap: map cannot be null');
    }
    
    return Invitation(
      id: map['_id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      projectId: map['projectId'] is String 
          ? map['projectId'] 
          : (map['projectId'] is Map ? map['projectId']['_id']?.toString() ?? '' : ''),
      invitedBy: map['invitedBy'] is String 
          ? map['invitedBy'] 
          : (map['invitedBy'] is Map ? map['invitedBy']['_id']?.toString() ?? '' : ''),
      invitedUser: map['invitedUser'] is String 
          ? map['invitedUser'] 
          : (map['invitedUser'] is Map ? map['invitedUser']['_id']?.toString() : null),
      status: map['status']?.toString() ?? 'pending',
      message: map['message']?.toString(),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt']) 
          : DateTime.now().add(const Duration(days: 7)),
      token: map['token']?.toString() ?? '',
      acceptedAt: map['acceptedAt'] != null ? DateTime.parse(map['acceptedAt']) : null,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
      project: map['projectId'] is Map<String, dynamic> 
          ? ProjectInfo.fromMap(map['projectId'])
          : null,
      invitedByUser: map['invitedBy'] is Map<String, dynamic> 
          ? UserInfo.fromMap(map['invitedBy'])
          : null,
      invitedUserInfo: map['invitedUser'] is Map<String, dynamic> 
          ? UserInfo.fromMap(map['invitedUser'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Invitation.fromJson(String source) => Invitation.fromMap(json.decode(source));

  Invitation copyWith({
    String? id,
    String? email,
    String? projectId,
    String? invitedBy,
    String? invitedUser,
    String? status,
    String? message,
    DateTime? expiresAt,
    String? token,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectInfo? project,
    UserInfo? invitedByUser,
    UserInfo? invitedUserInfo,
  }) {
    return Invitation(
      id: id ?? this.id,
      email: email ?? this.email,
      projectId: projectId ?? this.projectId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedUser: invitedUser ?? this.invitedUser,
      status: status ?? this.status,
      message: message ?? this.message,
      expiresAt: expiresAt ?? this.expiresAt,
      token: token ?? this.token,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      project: project ?? this.project,
      invitedByUser: invitedByUser ?? this.invitedByUser,
      invitedUserInfo: invitedUserInfo ?? this.invitedUserInfo,
    );
  }

  @override
  String toString() {
    return 'Invitation(id: $id, email: $email, projectId: $projectId, invitedBy: $invitedBy, invitedUser: $invitedUser, status: $status, message: $message, expiresAt: $expiresAt, token: $token, acceptedAt: $acceptedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Invitation && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }

  // Utility getters
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'accepted':
        return 'Đã chấp nhận';
      case 'declined':
        return 'Đã từ chối';
      case 'expired':
        return 'Đã hết hạn';
      default:
        return status;
    }
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);

  bool get canAccept => isPending && !isExpired;

  int get daysUntilExpiry {
    if (isExpired) return 0;
    final difference = expiresAt.difference(DateTime.now()).inDays;
    return difference < 0 ? 0 : difference;
  }
}

class ProjectInfo {
  final String id;
  final String title;
  final String description;

  ProjectInfo({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ProjectInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('ProjectInfo.fromMap: map cannot be null');
    }
    
    return ProjectInfo(
      id: map['_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
    };
  }
}

class UserInfo {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? avatarColor;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.avatarColor,
  });

  factory UserInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('UserInfo.fromMap: map cannot be null');
    }
    
    return UserInfo(
      id: map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      avatar: map['avatar']?.toString(),
      avatarColor: map['avatarColor']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'avatarColor': avatarColor,
    };
  }
}
