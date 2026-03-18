import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/features/tasks/services/activity_log_service.dart';
import 'package:frontend/features/tasks/widgets/activity_log_item.dart';
import 'package:frontend/models/comment.dart';
import 'package:frontend/models/activity_log.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Widget hiển thị section Comments trong Task Detail
class CommentSection extends StatefulWidget {
  final String taskId;
  final String projectId;

  const CommentSection({
    super.key,
    required this.taskId,
    required this.projectId,
  });

  @override
  State<CommentSection> createState() => CommentSectionState();
}

class CommentSectionState extends State<CommentSection> {
  static const int _maxMentionSuggestions = 5;
  static const int _commentPageSize = 5;

  List<TaskComment> _comments = [];
  bool _isLoading = true;
  bool _isSubmittingComment = false;
  bool _canSubmitComment = false;
  bool _hasMoreComments = false;
  int _commentPage = 1;
  bool _isLoadingMoreComments = false;
  String _sortOrder = 'newest';
  String _selectedTab = 'comments';

  // Controller cho input comment mới
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  // State cho reply
  TaskComment? _replyingTo;

  // State cho edit
  TaskComment? _editingComment;

  // State cho mention suggestions
  List<Map<String, dynamic>> _projectMembers = [];
  List<Map<String, dynamic>> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;
  Timer? _mentionDebounce;
  String _lastMentionQuery = '';

  // State cho Activity tab
  List<ActivityLog> _activityLogs = [];
  bool _isLoadingActivity = true;
  bool _hasMoreActivity = false;
  int _activityPage = 1;
  bool _isLoadingMoreActivity = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _preloadMentionMembers();
    _commentController.addListener(_onCommentTextChanged);
  }

  void refreshActivity() {
    if (!mounted) return;
    _loadActivity();
  }

  @override
  void dispose() {
    _mentionDebounce?.cancel();
    _commentController.removeListener(_onCommentTextChanged);
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _preloadMentionMembers() async {
    await TasksService.searchMembersForMention(
      context: context,
      projectId: widget.projectId,
      query: '',
      limit: _maxMentionSuggestions,
      onSuccess: (users) {
        if (!mounted) return;
        setState(() {
          _projectMembers = users;
        });
      },
    );
  }

  void _onCommentTextChanged() {
    final text = _commentController.text;
    final cursorPosition = _commentController.selection.baseOffset;
    final canSubmit = text.trim().isNotEmpty;
    if (canSubmit != _canSubmitComment && mounted) {
      setState(() {
        _canSubmitComment = canSubmit;
      });
    }

    if (cursorPosition > 0) {
      // Tìm @ gần nhất trước cursor
      final beforeCursor = text.substring(0, cursorPosition);
      final lastAtIndex = beforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        final afterAt = beforeCursor.substring(lastAtIndex + 1);
        // Hiển thị ngay khi vừa gõ @, miễn là mention chưa kết thúc bởi space
        if (!afterAt.contains(' ')) {
          _searchMentions(afterAt);
          return;
        }
      }
    }

    // Ẩn suggestions
    _hideMentionSuggestions();
  }

  void _hideMentionSuggestions() {
    if (!_showMentionSuggestions && _mentionSuggestions.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });
  }

  void _searchMentions(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final currentUserId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user.id;

    // Ưu tiên phản hồi tức thì từ cache local
    if (_projectMembers.isNotEmpty) {
      final localMatches = _projectMembers
          .where((user) {
            final id = (user['_id'] ?? '').toString();
            final name = (user['name'] ?? '').toString().toLowerCase();
            final email = (user['email'] ?? '').toString().toLowerCase();
            if (id == currentUserId) return false;
            if (normalizedQuery.isEmpty) return true;
            return name.contains(normalizedQuery) ||
                email.contains(normalizedQuery);
          })
          .take(_maxMentionSuggestions)
          .toList();

      if (mounted) {
        setState(() {
          _mentionSuggestions = localMatches;
          _showMentionSuggestions = localMatches.isNotEmpty;
        });
      }
    }

    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(const Duration(milliseconds: 140), () {
      _fetchMentionSuggestions(normalizedQuery);
    });
  }

  Future<void> _fetchMentionSuggestions(String query) async {
    _lastMentionQuery = query;

    TasksService.searchMembersForMention(
      context: context,
      projectId: widget.projectId,
      query: query,
      limit: _maxMentionSuggestions,
      onSuccess: (users) {
        if (!mounted || _lastMentionQuery != query) return;
        final currentUserId = Provider.of<UserProvider>(
          context,
          listen: false,
        ).user.id;
        final filteredUsers = users
            .where((user) => (user['_id'] ?? '').toString() != currentUserId)
            .toList();
        setState(() {
          _projectMembers = query.isEmpty ? filteredUsers : _projectMembers;
          _mentionSuggestions = filteredUsers
              .take(_maxMentionSuggestions)
              .toList();
          _showMentionSuggestions = _mentionSuggestions.isNotEmpty;
        });
      },
    );
  }

  void _insertMention(Map<String, dynamic> user) {
    final text = _commentController.text;
    final cursorPosition = _commentController.selection.baseOffset;
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    // Tìm vị trí @ gần nhất
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    if (lastAtIndex != -1) {
      final newText =
          beforeCursor.substring(0, lastAtIndex) +
          '@${user['name']} ' +
          afterCursor;

      _commentController.text = newText;
      _commentController.selection = TextSelection.collapsed(
        offset: lastAtIndex + user['name'].toString().length + 2,
      );
    }

    setState(() {
      _showMentionSuggestions = false;
      _mentionSuggestions = [];
    });
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _commentPage = 1;
      _comments = [];
    });

    await TasksService.getComments(
      context: context,
      taskId: widget.taskId,
      sort: _sortOrder,
      page: 1,
      limit: _commentPageSize,
      onSuccess: (comments, hasMore) {
        if (mounted) {
          setState(() {
            _comments = comments;
            _hasMoreComments = hasMore;
            _isLoading = false;
          });
        }
      },
    );

    if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMoreComments || !_hasMoreComments) return;

    setState(() {
      _isLoadingMoreComments = true;
    });

    final nextPage = _commentPage + 1;
    await TasksService.getComments(
      context: context,
      taskId: widget.taskId,
      sort: _sortOrder,
      page: nextPage,
      limit: _commentPageSize,
      onSuccess: (comments, hasMore) {
        if (!mounted) return;
        setState(() {
          _comments.addAll(comments);
          _commentPage = nextPage;
          _hasMoreComments = hasMore;
          _isLoadingMoreComments = false;
        });
      },
    );

    if (mounted && _isLoadingMoreComments) {
      setState(() {
        _isLoadingMoreComments = false;
      });
    }
  }

  List<TaskComment> _updateCommentTree(
    List<TaskComment> source,
    String targetId,
    TaskComment Function(TaskComment) updater,
  ) {
    return source.map((comment) {
      if (comment.id == targetId) {
        return updater(comment);
      }

      if (comment.replies.isNotEmpty) {
        final updatedReplies = _updateCommentTree(
          comment.replies,
          targetId,
          updater,
        );
        if (updatedReplies != comment.replies) {
          return comment.copyWith(replies: updatedReplies);
        }
      }

      return comment;
    }).toList();
  }

  List<TaskComment> _replaceOrInsertCreatedComment(
    List<TaskComment> source,
    TaskComment comment,
  ) {
    if (comment.isReply && comment.parentCommentId != null) {
      return _updateCommentTree(source, comment.parentCommentId!, (parent) {
        final nextReplies = List<TaskComment>.from(parent.replies);
        if (_sortOrder == 'newest') {
          nextReplies.insert(0, comment);
        } else {
          nextReplies.add(comment);
        }
        return parent.copyWith(replies: nextReplies);
      });
    }

    final next = List<TaskComment>.from(source);
    if (_sortOrder == 'newest') {
      next.insert(0, comment);
    } else {
      next.add(comment);
    }
    return next;
  }

  List<TaskComment> _replaceCommentById(
    List<TaskComment> source,
    String targetId,
    TaskComment replacement,
  ) {
    return _updateCommentTree(source, targetId, (existing) {
      return replacement.copyWith(replies: existing.replies);
    });
  }

  List<TaskComment> _removeCommentById(
    List<TaskComment> source,
    String targetId,
  ) {
    return source.where((comment) => comment.id != targetId).map((comment) {
      if (comment.replies.isEmpty) return comment;
      final nextReplies = _removeCommentById(comment.replies, targetId);
      if (nextReplies.length == comment.replies.length) return comment;
      return comment.copyWith(replies: nextReplies);
    }).toList();
  }

  List<CommentReaction> _toggleLocalReaction(
    List<CommentReaction> reactions,
    String userId,
    String emoji,
  ) {
    final existingIndex = reactions.indexWhere(
      (reaction) => reaction.userId == userId && reaction.emoji == emoji,
    );
    final next = List<CommentReaction>.from(reactions);

    if (existingIndex != -1) {
      next.removeAt(existingIndex);
      return next;
    }

    next.add(CommentReaction(user: {'_id': userId}, emoji: emoji));
    return next;
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoadingActivity = true;
      _activityPage = 1;
      _activityLogs = [];
    });

    await ActivityLogService.getTaskActivity(
      context: context,
      taskId: widget.taskId,
      page: 1,
      limit: 5,
      sort: _sortOrder,
      onSuccess: (logs, hasMore) {
        if (mounted) {
          setState(() {
            _activityLogs = logs;
            _hasMoreActivity = hasMore;
            _isLoadingActivity = false;
          });
        }
      },
    );

    if (mounted && _isLoadingActivity) {
      setState(() => _isLoadingActivity = false);
    }
  }

  Future<void> _loadMoreActivity() async {
    if (_isLoadingMoreActivity || !_hasMoreActivity) return;

    setState(() => _isLoadingMoreActivity = true);

    final nextPage = _activityPage + 1;

    await ActivityLogService.getTaskActivity(
      context: context,
      taskId: widget.taskId,
      page: nextPage,
      limit: 5,
      sort: _sortOrder,
      onSuccess: (logs, hasMore) {
        if (mounted) {
          setState(() {
            _activityLogs.addAll(logs);
            _hasMoreActivity = hasMore;
            _activityPage = nextPage;
            _isLoadingMoreActivity = false;
          });
        }
      },
    );

    if (mounted && _isLoadingMoreActivity) {
      setState(() => _isLoadingMoreActivity = false);
    }
  }

  void _startReply(TaskComment comment) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    setState(() {
      _replyingTo = comment;
      _editingComment = null;
    });

    // Tự động chèn @username nếu reply người khác
    if (comment.authorId != currentUser.id) {
      _commentController.text = '@${comment.authorName} ';
      _commentController.selection = TextSelection.collapsed(
        offset: _commentController.text.length,
      );
    } else {
      _commentController.clear();
    }

    _commentFocusNode.requestFocus();
  }

  void _startEdit(TaskComment comment) {
    setState(() {
      _editingComment = comment;
      _replyingTo = null;
    });

    _commentController.text = comment.content;
    _commentFocusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingTo = null;
      _editingComment = null;
    });
    _commentController.clear();
    _commentFocusNode.unfocus();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    final previousComments = List<TaskComment>.from(_comments);
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    setState(() {
      _isSubmittingComment = true;
    });

    if (_editingComment != null) {
      final editingId = _editingComment!.id;
      // Optimistic update for edited comment content
      setState(() {
        _comments = _updateCommentTree(_comments, editingId, (comment) {
          return comment.copyWith(
            content: content,
            isEdited: true,
            editedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });
        _editingComment = null;
        _commentController.clear();
      });

      await TasksService.updateComment(
        context: context,
        taskId: widget.taskId,
        commentId: editingId,
        content: content,
        onSuccess: (updatedComment) {
          if (!mounted) return;
          setState(() {
            _comments = _replaceCommentById(
              _comments,
              editingId,
              updatedComment,
            );
            _isSubmittingComment = false;
          });
        },
        onError: () {
          if (!mounted) return;
          setState(() {
            _comments = previousComments;
            _isSubmittingComment = false;
          });
        },
      );
    } else {
      final replyTargetId = _replyingTo?.id;
      final tempId = 'temp_${DateTime.now().microsecondsSinceEpoch}';
      final optimisticComment = TaskComment(
        id: tempId,
        content: content,
        author: {
          '_id': currentUser.id,
          'name': currentUser.name,
          'email': currentUser.email,
          'avatar': currentUser.avatar ?? '',
          'avatarColor': currentUser.avatarColor ?? '#2196F3',
        },
        parentCommentId: replyTargetId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Optimistic add
      setState(() {
        _comments = _replaceOrInsertCreatedComment(
          _comments,
          optimisticComment,
        );
        _replyingTo = null;
        _commentController.clear();
      });

      await TasksService.addComment(
        context: context,
        taskId: widget.taskId,
        content: content,
        parentCommentId: replyTargetId,
        onSuccess: (newComment) {
          if (!mounted) return;
          setState(() {
            _comments = _replaceCommentById(_comments, tempId, newComment);
            _isSubmittingComment = false;
          });
        },
        onError: () {
          if (!mounted) return;
          setState(() {
            _comments = previousComments;
            _isSubmittingComment = false;
          });
        },
      );
    }

    if (mounted && _isSubmittingComment) {
      setState(() {
        _isSubmittingComment = false;
      });
    }
  }

  Future<void> _deleteComment(TaskComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('confirm_delete')),
        content: Text(tr('confirm_delete_comment')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalVariables.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final previousComments = List<TaskComment>.from(_comments);

      setState(() {
        _comments = _removeCommentById(_comments, comment.id);
      });

      await TasksService.deleteComment(
        context: context,
        taskId: widget.taskId,
        commentId: comment.id,
        onSuccess: () {
          if (!mounted) return;
        },
        onError: () {
          if (!mounted) return;
          setState(() {
            _comments = previousComments;
          });
        },
      );
    }
  }

  Future<void> _toggleReaction(TaskComment comment, String emoji) async {
    final previousComments = List<TaskComment>.from(_comments);
    final currentUserId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).user.id;

    setState(() {
      _comments = _updateCommentTree(_comments, comment.id, (target) {
        return target.copyWith(
          reactions: _toggleLocalReaction(
            target.reactions,
            currentUserId,
            emoji,
          ),
        );
      });
    });

    await TasksService.toggleReaction(
      context: context,
      taskId: widget.taskId,
      commentId: comment.id,
      emoji: emoji,
      onSuccess: (updatedComment) {
        if (!mounted) return;
        setState(() {
          _comments = _replaceCommentById(
            _comments,
            comment.id,
            updatedComment,
          );
        });
      },
      onError: () {
        if (!mounted) return;
        setState(() {
          _comments = previousComments;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final sectionHeight = MediaQuery.of(context).size.height * 0.55;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header với sort dropdown
        _buildHeader(isDarkMode, theme),
        const SizedBox(height: 16),

        if (_selectedTab == 'comments') ...[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _hideMentionSuggestions();
            },
            child: SizedBox(
              height: sectionHeight,
              child: Column(
                children: [
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (_showMentionSuggestions) {
                          _hideMentionSuggestions();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        child: _isLoading
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _comments.isEmpty
                            ? _buildEmptyState(isDarkMode, theme)
                            : _buildCommentsList(isDarkMode, theme),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TapRegion(
                    onTapOutside: (_) => _hideMentionSuggestions(),
                    child: Column(
                      children: [
                        if (_replyingTo != null || _editingComment != null)
                          _buildReplyEditIndicator(isDarkMode),
                        if (_showMentionSuggestions)
                          _buildMentionSuggestions(isDarkMode),
                        _buildCommentInput(isDarkMode, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: sectionHeight,
            child: SingleChildScrollView(
              child: _buildActivityList(isDarkMode, theme),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(bool isDarkMode, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PopupMenuButton<String>(
          initialValue: _selectedTab,
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onSelected: (value) {
            setState(() {
              _selectedTab = value;
            });
            if (value == 'activity') {
              _loadActivity();
            } else {
              _loadComments();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedTab == 'comments' ? tr('comments') : tr('activity'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_outlined,
                  size: 24,
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'comments', child: Text(tr('comments'))),
            PopupMenuItem(value: 'activity', child: Text(tr('activity'))),
          ],
        ),
        PopupMenuButton<String>(
          initialValue: _sortOrder,
          position: PopupMenuPosition.under,
          onSelected: (value) {
            setState(() {
              _sortOrder = value;
            });
            if (_selectedTab == 'comments') {
              _loadComments();
            } else {
              _loadActivity();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? GlobalVariables.darkBackgroundSecondary
                  : GlobalVariables.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode
                    ? GlobalVariables.darkBorderPrimary
                    : GlobalVariables.borderPrimary,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sortOrder == 'newest'
                      ? tr('newest_first')
                      : tr('oldest_first'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'newest', child: Text(tr('newest_first'))),
            PopupMenuItem(value: 'oldest', child: Text(tr('oldest_first'))),
          ],
        ),
      ],
    );
  }

  int _getTotalCommentCount() {
    int total = _comments.length;
    for (final comment in _comments) {
      total += comment.replyCount;
    }
    return total;
  }

  Widget _buildActivityList(bool isDarkMode, ThemeData theme) {
    if (_isLoadingActivity) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activityLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                tr('activity_no_logs'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDarkMode
                      ? GlobalVariables.darkTextSecondary
                      : GlobalVariables.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ..._activityLogs.map(
          (log) => ActivityLogItem(log: log, isDarkMode: isDarkMode),
        ),
        // "View more" button
        if (_hasMoreActivity)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _isLoadingMoreActivity
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: _loadMoreActivity,
                    child: Text(
                      tr('activity_view_more'),
                      style: TextStyle(
                        color: GlobalVariables.primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: isDarkMode
                  ? GlobalVariables.darkTextTertiary
                  : GlobalVariables.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              tr('no_comments'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('be_first_to_comment'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(bool isDarkMode, ThemeData theme) {
    return Column(
      children: [
        ..._comments.map((comment) {
          return _CommentCard(
            taskId: widget.taskId,
            comment: comment,
            isDarkMode: isDarkMode,
            theme: theme,
            onReply: () => _startReply(comment),
            onEdit: () => _startEdit(comment),
            onDelete: () => _deleteComment(comment),
            onReaction: (emoji) => _toggleReaction(comment, emoji),
            onReplyReaction: (reply, emoji) => _toggleReaction(reply, emoji),
            onReplyEdit: (reply) => _startEdit(reply),
            onReplyDelete: (reply) => _deleteComment(reply),
            onReplyToReply: (reply) => _startReply(comment),
          );
        }),
        if (_hasMoreComments)
          Align(
            alignment: Alignment.centerLeft,
            child: _isLoadingMoreComments
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _loadMoreComments,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: Text(tr('comment_view_more')),
                  ),
          ),
      ],
    );
  }

  Widget _buildReplyEditIndicator(bool isDarkMode) {
    final isEditing = _editingComment != null;
    final targetComment = isEditing ? _editingComment! : _replyingTo!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GlobalVariables.secondaryCoral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: GlobalVariables.secondaryCoral.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_rounded : Icons.reply_rounded,
            size: 18,
            color: GlobalVariables.secondaryCoral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEditing
                  ? tr('editing_comment')
                  : '${tr('replying_to')} ${targetComment.authorName}',
              style: TextStyle(
                color: GlobalVariables.secondaryCoral,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _cancelReplyOrEdit,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: GlobalVariables.secondaryCoral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionSuggestions(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _mentionSuggestions.length > _maxMentionSuggestions
            ? _maxMentionSuggestions
            : _mentionSuggestions.length,
        itemBuilder: (context, index) {
          final user = _mentionSuggestions[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor:
                  (user['avatarColor'] as String?)?.toColor() ??
                  GlobalVariables.primaryBlue,
              backgroundImage:
                  user['avatar'] != null && user['avatar'].isNotEmpty
                  ? NetworkImage(user['avatar'])
                  : null,
              child: user['avatar'] == null || user['avatar'].isEmpty
                  ? Text(
                      (user['name'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            subtitle: Text(
              user['email'] ?? '',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? GlobalVariables.darkTextTertiary
                    : GlobalVariables.textTertiary,
              ),
            ),
            onTap: () => _insertMention(user),
          );
        },
      ),
    );
  }

  Widget _buildCommentInput(bool isDarkMode, ThemeData theme) {
    final currentUser = Provider.of<UserProvider>(context).user;
    final canSend = _canSubmitComment && !_isSubmittingComment;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkSurfaceCard
            : GlobalVariables.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor:
                currentUser.avatarColor?.toColor() ??
                GlobalVariables.primaryBlue,
            backgroundImage:
                currentUser.avatar != null && currentUser.avatar!.isNotEmpty
                ? NetworkImage(currentUser.avatar!)
                : null,
            child: currentUser.avatar == null || currentUser.avatar!.isEmpty
                ? Text(
                    currentUser.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Text input
          Expanded(
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if (event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  if (canSend) {
                    _submitComment();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: tr('add_comment_hint'),
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? GlobalVariables.darkTextTertiary
                        : GlobalVariables.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: isDarkMode
                      ? GlobalVariables.darkTextPrimary
                      : GlobalVariables.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: canSend ? _submitComment : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: canSend
                    ? GlobalVariables.primaryBlue
                    : GlobalVariables.textTertiary,
                shape: BoxShape.circle,
              ),
              child: _isSubmittingComment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị một comment card
class _CommentCard extends StatefulWidget {
  final String taskId;
  final TaskComment comment;
  final bool isDarkMode;
  final ThemeData theme;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String emoji) onReaction;
  final Function(TaskComment reply, String emoji) onReplyReaction;
  final Function(TaskComment reply) onReplyEdit;
  final Function(TaskComment reply) onReplyDelete;
  final Function(TaskComment reply) onReplyToReply;

  const _CommentCard({
    required this.taskId,
    required this.comment,
    required this.isDarkMode,
    required this.theme,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReaction,
    required this.onReplyReaction,
    required this.onReplyEdit,
    required this.onReplyDelete,
    required this.onReplyToReply,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;
  bool _isLoadingReactions = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    final isAuthor = widget.comment.authorId == currentUser.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment
          _buildCommentContent(
            comment: widget.comment,
            isAuthor: isAuthor,
            onReply: widget.onReply,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onReaction: widget.onReaction,
            showRepliesToggle: widget.comment.hasReplies,
            isRepliesExpanded: _showReplies,
            onToggleReplies: () {
              setState(() {
                _showReplies = !_showReplies;
              });
            },
          ),

          // Replies section
          if (widget.comment.hasReplies) ...[
            if (_showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 8),
                child: Column(
                  children: widget.comment.replies.map((reply) {
                    final isReplyAuthor = reply.authorId == currentUser.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCommentContent(
                        comment: reply,
                        isAuthor: isReplyAuthor,
                        onReply: () => widget.onReplyToReply(reply),
                        onEdit: () => widget.onReplyEdit(reply),
                        onDelete: () => widget.onReplyDelete(reply),
                        onReaction: (emoji) =>
                            widget.onReplyReaction(reply, emoji),
                        isReply: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentContent({
    required TaskComment comment,
    required bool isAuthor,
    required VoidCallback onReply,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required Function(String emoji) onReaction,
    bool showRepliesToggle = false,
    bool isRepliesExpanded = false,
    VoidCallback? onToggleReplies,
    bool isReply = false,
  }) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Author avatar
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: CircleAvatar(
            radius: isReply ? 21 : 24,
            backgroundColor: comment.authorAvatarColor.toColor(),
            backgroundImage: comment.authorAvatar.isNotEmpty
                ? NetworkImage(comment.authorAvatar)
                : null,
            child: comment.authorAvatar.isEmpty
                ? Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isReply ? 18 : 21,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(
              left: 14,
              right: 6,
              top: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? GlobalVariables.darkSurfaceCard
                  : GlobalVariables.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDarkMode
                    ? GlobalVariables.darkBorderPrimary
                    : GlobalVariables.borderPrimary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isReply ? 14 : 15,
                        color: widget.isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),

                    // if (comment.isEdited) ...[
                    //   const SizedBox(width: 4),
                    //   Text(
                    //     tr('edited'),
                    //     style: TextStyle(
                    //       fontSize: 11,
                    //       fontStyle: FontStyle.italic,
                    //       color: widget.isDarkMode
                    //           ? GlobalVariables.darkTextTertiary
                    //           : GlobalVariables.textTertiary,
                    //     ),
                    //   ),
                    // ],
                    const Spacer(),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode
                            ? GlobalVariables.darkTextTertiary
                            : GlobalVariables.textTertiary,
                      ),
                    ),

                    // Menu button (chỉ hiện cho author hoặc owner)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: widget.isDarkMode
                              ? GlobalVariables.darkTextTertiary
                              : GlobalVariables.textTertiary,
                        ),
                        padding: EdgeInsets.zero,
                        splashRadius: 16,
                        iconSize: 18,
                        offset: const Offset(-16, 32),
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit();
                              break;
                            case 'delete':
                              onDelete();
                              break;
                          }
                        },
                        itemBuilder: (context) {
                          final items = <PopupMenuEntry<String>>[];
                          if (isAuthor) {
                            items.add(
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(tr('edit')),
                                  ],
                                ),
                              ),
                            );
                          }
                          items.add(
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: GlobalVariables.errorRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('delete'),
                                    style: TextStyle(
                                      color: GlobalVariables.errorRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          return items;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Content
                _buildCommentText(content: comment.content, isReply: isReply),
                const SizedBox(height: 10),
                _buildActionsRow(
                  comment: comment,
                  currentUserId: currentUser.id,
                  onReaction: onReaction,
                  onReply: onReply,
                  showRepliesToggle: showRepliesToggle,
                  isRepliesExpanded: isRepliesExpanded,
                  onToggleReplies: onToggleReplies,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentText({required String content, required bool isReply}) {
    final baseStyle = TextStyle(
      fontSize: isReply ? 14 : 15,
      color: widget.isDarkMode
          ? GlobalVariables.darkTextPrimary
          : GlobalVariables.textPrimary,
      height: 1.4,
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: _buildMentionSpans(content, baseStyle),
      ),
    );
  }

  List<TextSpan> _buildMentionSpans(String text, TextStyle baseStyle) {
    final regex = RegExp(
      r'@[\p{L}\p{M}0-9_]+(?:\s+[\p{Lu}][\p{L}\p{M}0-9_]*)*',
      unicode: true,
    );
    final spans = <TextSpan>[];
    var lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      spans.add(
        TextSpan(
          text: match.group(0),
          style: baseStyle.copyWith(
            color: GlobalVariables.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans;
  }

  Widget _buildActionsRow({
    required TaskComment comment,
    required String currentUserId,
    required Function(String) onReaction,
    required VoidCallback onReply,
    bool showRepliesToggle = false,
    bool isRepliesExpanded = false,
    VoidCallback? onToggleReplies,
  }) {
    final reactionCounts = comment.reactionCounts;
    final actionItems = <Widget>[];

    for (final entry in reactionCounts.entries) {
      final emoji = entry.key;
      final count = entry.value;
      final hasReacted = comment.hasUserReacted(currentUserId, emoji);

      actionItems.add(
        GestureDetector(
          onTap: () => onReaction(emoji),
          onLongPress: () => _showReactionUsers(comment: comment, emoji: emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasReacted
                  ? GlobalVariables.backgroundBlueLight.withValues(alpha: 0.1)
                  : (widget.isDarkMode
                        ? GlobalVariables.darkBackgroundSecondary
                        : GlobalVariables.backgroundSecondary),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasReacted
                    ? GlobalVariables.backgroundBlueLight
                    : (widget.isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasReacted
                        ? GlobalVariables.backgroundBlueLight
                        : (widget.isDarkMode
                              ? GlobalVariables.darkTextSecondary
                              : GlobalVariables.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (reactionCounts.isEmpty) {
      actionItems.add(
        GestureDetector(
          onTap: () => onReaction(CommentEmojis.thumbsUp),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? GlobalVariables.darkBackgroundPrimary
                  : GlobalVariables.backgroundPrimary,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: widget.isDarkMode
                    ? GlobalVariables.darkBorderSecondary
                    : GlobalVariables.borderSecondary,
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.thumb_up_alt_outlined,
              size: 20,
              color: widget.isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ),
      );
    }

    actionItems.add(
      _EmojiPickerButton(
        onEmojiSelected: onReaction,
        currentUserId: currentUserId,
        comment: comment,
        isDarkMode: widget.isDarkMode,
      ),
    );

    actionItems.add(
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onReply,
          borderRadius: BorderRadius.circular(20),
          splashColor: GlobalVariables.primaryBlue.withValues(alpha: 0.2),
          highlightColor: GlobalVariables.primaryBlue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 9,
              bottom: 14,
              left: 9,
              right: 9,
            ),
            child: Text(
              tr('reply'),
              style: TextStyle(
                color: GlobalVariables.primaryBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    final rows = <Widget>[];
    for (var i = 0; i < actionItems.length; i += 3) {
      final rowItems = actionItems.skip(i).take(3).toList();
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: _buildRowItems(rowItems),
        ),
      );
      if (i + 3 < actionItems.length) {
        rows.add(const SizedBox(height: 7));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rows,
          ),
        ),
        if (showRepliesToggle)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleReplies,
              borderRadius: BorderRadius.circular(15),
              splashColor: GlobalVariables.primaryBlue.withValues(alpha: 0.2),
              highlightColor: GlobalVariables.primaryBlue.withValues(
                alpha: 0.1,
              ),
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Text(
                  isRepliesExpanded ? tr('hide_replies') : tr('show_replies'),
                  style: TextStyle(
                    color: GlobalVariables.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 6),
      ],
    );
  }

  List<Widget> _buildRowItems(List<Widget> items) {
    final rowItems = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      rowItems.add(items[i]);
      if (i < items.length - 1) {
        rowItems.add(const SizedBox(width: 9));
      }
    }
    return rowItems;
  }

  Future<void> _showReactionUsers({
    required TaskComment comment,
    required String emoji,
  }) async {
    if (_isLoadingReactions) return;
    setState(() {
      _isLoadingReactions = true;
    });

    await TasksService.getReactionDetails(
      context: context,
      taskId: widget.taskId,
      commentId: comment.id,
      onSuccess: (details) {
        final users = details.byEmoji[emoji] ?? [];
        if (!mounted) return;

        setState(() {
          _isLoadingReactions = false;
        });

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalVariables.darkSurfaceCard
                    : GlobalVariables.surfaceCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? GlobalVariables.darkBorderPrimary
                            : GlobalVariables.borderPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            tr('reactions'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? GlobalVariables.darkTextPrimary
                                  : GlobalVariables.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (users.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Text(
                          tr('no_reactions_yet'),
                          style: TextStyle(
                            color: isDarkMode
                                ? GlobalVariables.darkTextSecondary
                                : GlobalVariables.textSecondary,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: users.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: isDarkMode
                                ? GlobalVariables.darkBorderPrimary
                                : GlobalVariables.borderPrimary,
                          ),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final avatar = user['avatar']?.toString() ?? '';
                            final name = user['name']?.toString() ?? '';
                            final email = user['email']?.toString() ?? '';
                            final avatarColor =
                                user['avatarColor']?.toString() ?? '#2196F3';

                            return ListTile(
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: avatarColor.toColor(),
                                backgroundImage: avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                child: avatar.isEmpty
                                    ? Text(
                                        name.isNotEmpty
                                            ? name.substring(0, 1).toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextPrimary
                                      : GlobalVariables.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                email,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? GlobalVariables.darkTextTertiary
                                      : GlobalVariables.textTertiary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted && _isLoadingReactions) {
      setState(() {
        _isLoadingReactions = false;
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return tr('just_now');
    } else if (difference.inHours < 1) {
      return 'minutes_ago'.tr(
        namedArgs: {'minutes': '${difference.inMinutes}'},
      );
    } else if (difference.inDays < 1) {
      return 'hours_ago'.tr(namedArgs: {'hours': '${difference.inHours}'});
    } else if (difference.inDays < 7) {
      return 'days_ago'.tr(namedArgs: {'days': '${difference.inDays}'});
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}

/// Widget cho emoji picker button
class _EmojiPickerButton extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;
  final String currentUserId;
  final TaskComment comment;
  final bool isDarkMode;

  const _EmojiPickerButton({
    required this.onEmojiSelected,
    required this.currentUserId,
    required this.comment,
    required this.isDarkMode,
  });

  @override
  State<_EmojiPickerButton> createState() => _EmojiPickerButtonState();
}

class _EmojiPickerButtonState extends State<_EmojiPickerButton> {
  OverlayEntry? _overlayEntry;

  void _showEmojiPicker() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideEmojiPicker() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) {
      return OverlayEntry(builder: (context) => const SizedBox.shrink());
    }

    final target = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    const pickerHeight = 56.0;
    const horizontalMargin = 8.0;
    const verticalMargin = 8.0;

    final overlaySize = overlay.size;
    final availableWidth = overlaySize.width - (horizontalMargin * 2);
    final pickerWidth = availableWidth >= 300.0
        ? 300.0
        : availableWidth >= 240.0
        ? 240.0
        : availableWidth;
    double left = target.dx;
    double top = target.dy - pickerHeight - 6;

    if (top < verticalMargin) {
      top = target.dy + renderBox.size.height + 6;
    }

    left = target.dx - (pickerWidth / 2) + (renderBox.size.width / 2) + 60;

    if (left + pickerWidth > overlaySize.width - horizontalMargin) {
      left = overlaySize.width - pickerWidth - horizontalMargin;
    }
    if (left < horizontalMargin) {
      left = horizontalMargin;
    }

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap outside to close
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideEmojiPicker,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Emoji picker
          Positioned(
            left: left,
            top: top,
            width: pickerWidth,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: widget.isDarkMode
                  ? GlobalVariables.darkSurfaceCard
                  : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CommentEmojis.all.map((emoji) {
                      final hasReacted = widget.comment.hasUserReacted(
                        widget.currentUserId,
                        emoji,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () {
                            widget.onEmojiSelected(emoji);
                            _hideEmojiPicker();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: hasReacted
                                  ? GlobalVariables.backgroundBlueLight
                                        .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showEmojiPicker,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? GlobalVariables.darkBackgroundPrimary
                  : GlobalVariables.backgroundPrimary,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: widget.isDarkMode
                    ? GlobalVariables.darkBorderSecondary
                    : GlobalVariables.borderSecondary,
                width: 1.2,
              ),
            ),
            child: Icon(
              Icons.add_reaction_outlined,
              size: 20,
              color: widget.isDarkMode
                  ? GlobalVariables.darkTextSecondary
                  : GlobalVariables.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
