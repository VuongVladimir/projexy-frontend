import 'dart:convert';

/// Model cho Reaction trên Comment
class CommentReaction {
  final Map<String, dynamic> user;
  final String emoji;

  CommentReaction({
    required this.user,
    required this.emoji,
  });

  factory CommentReaction.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CommentReaction(user: {}, emoji: '');
    }

    return CommentReaction(
      user: map['userId'] is Map
          ? {
              '_id': map['userId']['_id']?.toString() ?? '',
              'name': map['userId']['name']?.toString() ?? '',
              'email': map['userId']['email']?.toString() ?? '',
              'avatar': map['userId']['avatar']?.toString() ?? '',
              'avatarColor': map['userId']['avatarColor']?.toString() ?? '',
            }
          : {'_id': map['userId']?.toString() ?? ''},
      emoji: map['emoji']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': user,
      'emoji': emoji,
    };
  }

  String get userId => user['_id']?.toString() ?? '';
  String get userName => user['name']?.toString() ?? '';
  String get userAvatar => user['avatar']?.toString() ?? '';
  String get userAvatarColor => user['avatarColor']?.toString() ?? '';
}

/// Model cho Comment
class TaskComment {
  final String id;
  final String content;
  final Map<String, dynamic> author;
  final String? parentCommentId;
  final List<Map<String, dynamic>> mentions;
  final List<CommentReaction> reactions;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskComment> replies;

  TaskComment({
    required this.id,
    required this.content,
    required this.author,
    this.parentCommentId,
    this.mentions = const [],
    this.reactions = const [],
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory TaskComment.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError('TaskComment.fromMap: map cannot be null');
    }

    // Parse author
    Map<String, dynamic> authorData = {};
    if (map['author'] is Map) {
      authorData = {
        '_id': map['author']['_id']?.toString() ?? '',
        'name': map['author']['name']?.toString() ?? '',
        'email': map['author']['email']?.toString() ?? '',
        'avatar': map['author']['avatar']?.toString() ?? '',
        'avatarColor': map['author']['avatarColor']?.toString() ?? '',
      };
    } else if (map['author'] is String) {
      authorData = {'_id': map['author']};
    }

    // Parse mentions
    List<Map<String, dynamic>> mentionsList = [];
    if (map['mentions'] is List) {
      mentionsList = (map['mentions'] as List).map((m) {
        if (m is Map) {
          return {
            '_id': m['_id']?.toString() ?? '',
            'name': m['name']?.toString() ?? '',
            'email': m['email']?.toString() ?? '',
            'avatar': m['avatar']?.toString() ?? '',
            'avatarColor': m['avatarColor']?.toString() ?? '',
          };
        }
        return {'_id': m?.toString() ?? ''};
      }).toList();
    }

    // Parse reactions
    List<CommentReaction> reactionsList = [];
    if (map['reactions'] is List) {
      reactionsList = (map['reactions'] as List)
          .map((r) => CommentReaction.fromMap(r as Map<String, dynamic>?))
          .toList();
    }

    // Parse replies
    List<TaskComment> repliesList = [];
    if (map['replies'] is List) {
      repliesList = (map['replies'] as List)
          .map((r) => TaskComment.fromMap(r as Map<String, dynamic>?))
          .toList();
    }

    return TaskComment(
      id: map['_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      author: authorData,
      parentCommentId: map['parentCommentId']?.toString(),
      mentions: mentionsList,
      reactions: reactionsList,
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null
          ? DateTime.parse(map['editedAt'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      replies: repliesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'content': content,
      'author': author,
      'parentCommentId': parentCommentId,
      'mentions': mentions,
      'reactions': reactions.map((r) => r.toMap()).toList(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'replies': replies.map((r) => r.toMap()).toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory TaskComment.fromJson(String source) =>
      TaskComment.fromMap(json.decode(source));

  TaskComment copyWith({
    String? id,
    String? content,
    Map<String, dynamic>? author,
    String? parentCommentId,
    List<Map<String, dynamic>>? mentions,
    List<CommentReaction>? reactions,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskComment>? replies,
  }) {
    return TaskComment(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replies: replies ?? this.replies,
    );
  }

  @override
  String toString() {
    return 'TaskComment(id: $id, content: $content, author: ${author['name']}, replies: ${replies.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Utility getters
  String get authorId => author['_id']?.toString() ?? '';
  String get authorName => author['name']?.toString() ?? '';
  String get authorEmail => author['email']?.toString() ?? '';
  String get authorAvatar => author['avatar']?.toString() ?? '';
  String get authorAvatarColor => author['avatarColor']?.toString() ?? '#2196F3';

  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty;
  bool get hasReplies => replies.isNotEmpty;
  int get replyCount => replies.length;
  
  bool get hasReactions => reactions.isNotEmpty;
  int get totalReactionCount => reactions.length;

  /// Đếm số lượng mỗi loại emoji
  Map<String, int> get reactionCounts {
    final counts = <String, int>{};
    for (final reaction in reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return counts;
  }

  /// Lấy danh sách emoji duy nhất đã được react
  List<String> get uniqueEmojis {
    return reactionCounts.keys.toList();
  }

  /// Kiểm tra xem user đã react emoji này chưa
  bool hasUserReacted(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  /// Kiểm tra xem user đã react bất kỳ emoji nào chưa
  bool hasUserReactedAny(String userId) {
    return reactions.any((r) => r.userId == userId);
  }

  /// Lấy danh sách users đã react một emoji cụ thể
  List<Map<String, dynamic>> getUsersForEmoji(String emoji) {
    return reactions
        .where((r) => r.emoji == emoji)
        .map((r) => r.user)
        .toList();
  }
}

/// Model cho kết quả reactions grouped theo emoji
class ReactionsByEmoji {
  final int total;
  final Map<String, List<Map<String, dynamic>>> byEmoji;

  ReactionsByEmoji({
    required this.total,
    required this.byEmoji,
  });

  factory ReactionsByEmoji.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return ReactionsByEmoji(total: 0, byEmoji: {});
    }

    final byEmojiData = <String, List<Map<String, dynamic>>>{};
    if (map['byEmoji'] is Map) {
      (map['byEmoji'] as Map).forEach((key, value) {
        if (value is List) {
          byEmojiData[key.toString()] = value.map((user) {
            if (user is Map) {
              return {
                '_id': user['_id']?.toString() ?? '',
                'name': user['name']?.toString() ?? '',
                'email': user['email']?.toString() ?? '',
                'avatar': user['avatar']?.toString() ?? '',
                'avatarColor': user['avatarColor']?.toString() ?? '',
              };
            }
            return <String, dynamic>{};
          }).toList();
        }
      });
    }

    return ReactionsByEmoji(
      total: map['total']?.toInt() ?? 0,
      byEmoji: byEmojiData,
    );
  }
}

/// Danh sách emoji mặc định cho reactions
class CommentEmojis {
  static const List<String> all = ['👍', '👏', '🔥', '💖', '😮', '🤔'];
  
  static const thumbsUp = '👍';
  static const clap = '👏';
  static const fire = '🔥';
  static const heart = '💖';
  static const wow = '😮';
  static const thinking = '🤔';
}
