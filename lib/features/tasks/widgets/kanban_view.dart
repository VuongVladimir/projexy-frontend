import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as easy;
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/features/tasks/screens/task_detail_screen.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';
import 'package:intl/intl.dart';

enum _KanbanBucket { today, thisWeek, nextWeek, later, overdue }

class TaskKanbanView extends StatefulWidget {
  final List<Task> tasks;
  final VoidCallback onRefresh;

  const TaskKanbanView({
    super.key,
    required this.tasks,
    required this.onRefresh,
  });

  @override
  State<TaskKanbanView> createState() => _TaskKanbanViewState();
}

class _TaskKanbanViewState extends State<TaskKanbanView> {
  bool _isShifting = false;
  final ScrollController _horizontalScrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _autoScrollDirection = 0;

  static const double _edgeAutoScrollZone = 72;
  static const double _autoScrollStep = 20;
  static const Duration _autoScrollInterval = Duration(milliseconds: 16);

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _startOfWeek(DateTime value) {
    final date = _dateOnly(value);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  void _handleCardDragUpdate(Offset globalPosition) {
    if (!_horizontalScrollController.hasClients) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final localPosition = renderObject.globalToLocal(globalPosition);
    final viewportWidth = renderObject.size.width;

    int direction = 0;
    if (localPosition.dx < _edgeAutoScrollZone) {
      direction = -1;
    } else if (localPosition.dx > viewportWidth - _edgeAutoScrollZone) {
      direction = 1;
    }

    _setAutoScrollDirection(direction);
  }

  void _setAutoScrollDirection(int direction) {
    if (_autoScrollDirection == direction) return;

    _autoScrollDirection = direction;
    _autoScrollTimer?.cancel();

    if (direction == 0) return;

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_horizontalScrollController.hasClients) {
        _stopAutoScroll();
        return;
      }

      final position = _horizontalScrollController.position;
      final nextPixels = (position.pixels + (direction * _autoScrollStep))
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();

      if (nextPixels == position.pixels) {
        _stopAutoScroll();
        return;
      }

      _horizontalScrollController.jumpTo(nextPixels);
    });
  }

  void _stopAutoScroll() {
    _autoScrollDirection = 0;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  Map<_KanbanBucket, List<Task>> _bucketize(List<Task> tasks) {
    final now = DateTime.now();
    final todayStart = _dateOnly(now);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final currentWeekStart = _startOfWeek(todayStart);
    final nextWeekStart = currentWeekStart.add(const Duration(days: 7));
    final weekAfterNextStart = currentWeekStart.add(const Duration(days: 14));

    final map = <_KanbanBucket, List<Task>>{
      _KanbanBucket.overdue: [],
      _KanbanBucket.today: [],
      _KanbanBucket.thisWeek: [],
      _KanbanBucket.nextWeek: [],
      _KanbanBucket.later: [],
    };

    for (final task in tasks) {
      if (task.isCompleted) {
        continue;
      }

      if (task.endDate == null) {
        map[_KanbanBucket.later]!.add(task);
        continue;
      }

      final deadline = _dateOnly(task.endDate!);

      if (deadline.isBefore(todayStart)) {
        map[_KanbanBucket.overdue]!.add(task);
      } else if (deadline.isAtSameMomentAs(todayStart)) {
        map[_KanbanBucket.today]!.add(task);
      } else if (deadline.isAtSameMomentAs(tomorrowStart) ||
          (deadline.isAfter(tomorrowStart) &&
              deadline.isBefore(nextWeekStart))) {
        map[_KanbanBucket.thisWeek]!.add(task);
      } else if (deadline.isAtSameMomentAs(nextWeekStart) ||
          (deadline.isAfter(nextWeekStart) &&
              deadline.isBefore(weekAfterNextStart))) {
        map[_KanbanBucket.nextWeek]!.add(task);
      } else {
        map[_KanbanBucket.later]!.add(task);
      }
    }

    return map;
  }

  String _bucketTitle(_KanbanBucket bucket) {
    switch (bucket) {
      case _KanbanBucket.today:
        return easy.tr('today');
      case _KanbanBucket.thisWeek:
        return easy.tr('this_week');
      case _KanbanBucket.nextWeek:
        return easy.tr('next_week');
      case _KanbanBucket.later:
        return easy.tr('later');
      case _KanbanBucket.overdue:
        return easy.tr('overdue');
    }
  }

  Color _bucketColor(_KanbanBucket bucket) {
    switch (bucket) {
      case _KanbanBucket.today:
        return GlobalVariables.primaryBlue;
      case _KanbanBucket.thisWeek:
        return GlobalVariables.successGreen;
      case _KanbanBucket.nextWeek:
        return const Color(0xFF8E44AD);
      case _KanbanBucket.later:
        return Colors.blueGrey;
      case _KanbanBucket.overdue:
        return GlobalVariables.errorRed;
    }
  }

  int _calculateDeltaDays(Task task, _KanbanBucket from, _KanbanBucket to) {
    if (task.endDate == null) return 0;

    final now = DateTime.now();
    final todayStart = _dateOnly(now);
    //final tomorrowStart = todayStart.add(const Duration(days: 1));
    final currentWeekStart = _startOfWeek(todayStart);
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
    final nextWeekEnd = currentWeekEnd.add(const Duration(days: 7));
    final weekAfterNextEnd = currentWeekEnd.add(const Duration(days: 14));
    final currentDeadline = _dateOnly(task.endDate!);

    DateTime targetDeadline;
    switch (to) {
      case _KanbanBucket.today:
        targetDeadline = todayStart;
        break;
      case _KanbanBucket.thisWeek:
        targetDeadline = currentWeekEnd;
        break;
      case _KanbanBucket.nextWeek:
        targetDeadline = nextWeekEnd;
        break;
      case _KanbanBucket.later:
        targetDeadline = weekAfterNextEnd;
        break;
      case _KanbanBucket.overdue:
        return 0;
    }

    return targetDeadline.difference(currentDeadline).inDays;
  }

  Future<void> _shiftTask(Task task, int deltaDays) async {
    if (_isShifting || deltaDays == 0) return;
    setState(() => _isShifting = true);

    TasksService.shiftTask(
      context: context,
      taskId: task.id,
      deltaDays: deltaDays,
      onSuccess: () {
        if (mounted) {
          setState(() => _isShifting = false);
          widget.onRefresh();
        }
      },
      onError: () {
        if (mounted) {
          setState(() => _isShifting = false);
          _showPermissionDeniedDialog();
        }
      },
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && _isShifting) {
      setState(() => _isShifting = false);
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(easy.tr('permission_denied')),
        content: Text(easy.tr('no_edit_permission')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(easy.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(
    BuildContext ctx,
    Task task,
    _KanbanBucket fromBucket,
  ) {
    final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? GlobalVariables.darkSurfaceCard
              : GlobalVariables.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? GlobalVariables.darkBorderPrimary
                      : GlobalVariables.borderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDarkMode
                        ? GlobalVariables.darkTextPrimary
                        : GlobalVariables.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.today_rounded,
                  color: GlobalVariables.primaryBlue,
                ),
                title: Text(easy.tr('move_to_tomorrow')),
                onTap: () {
                  Navigator.pop(context);
                  _shiftTask(task, 1);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.date_range_rounded,
                  color: const Color(0xFF8E44AD),
                ),
                title: Text(easy.tr('move_to_next_week')),
                onTap: () {
                  Navigator.pop(context);
                  _shiftTask(task, 7);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, String taskId) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: {'taskId': taskId},
    ).then((_) => widget.onRefresh());
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _bucketize(widget.tasks);
    final bucketOrder = [
      _KanbanBucket.overdue,
      _KanbanBucket.today,
      _KanbanBucket.thisWeek,
      _KanbanBucket.nextWeek,
      _KanbanBucket.later,
    ];

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bucketOrder.map((bucket) {
              final tasks = buckets[bucket] ?? [];
              return Padding(
                padding: EdgeInsets.only(
                  right: bucket != bucketOrder.last ? 12 : 0,
                ),
                child: _KanbanColumn(
                  bucket: bucket,
                  title: _bucketTitle(bucket),
                  color: _bucketColor(bucket),
                  tasks: tasks,
                  onTaskTap: (task) => _navigateToTaskDetail(context, task.id),
                  onTaskLongPress: (task) =>
                      _showQuickActions(context, task, bucket),
                  onCardDragUpdate: _handleCardDragUpdate,
                  onCardDragEnd: _stopAutoScroll,
                  onAcceptDrop: bucket == _KanbanBucket.overdue
                      ? null
                      : (task, fromBucket) {
                          final delta = _calculateDeltaDays(
                            task,
                            fromBucket,
                            bucket,
                          );
                          if (delta != 0) {
                            _shiftTask(task, delta);
                          }
                        },
                  sourceBucket: bucket,
                ),
              );
            }).toList(),
          ),
        ),
        if (_isShifting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final _KanbanBucket bucket;
  final String title;
  final Color color;
  final List<Task> tasks;
  final Function(Task) onTaskTap;
  final Function(Task) onTaskLongPress;
  final ValueChanged<Offset> onCardDragUpdate;
  final VoidCallback onCardDragEnd;
  final Function(Task task, _KanbanBucket fromBucket)? onAcceptDrop;
  final _KanbanBucket sourceBucket;

  const _KanbanColumn({
    required this.bucket,
    required this.title,
    required this.color,
    required this.tasks,
    required this.onTaskTap,
    required this.onTaskLongPress,
    required this.onCardDragUpdate,
    required this.onCardDragEnd,
    this.onAcceptDrop,
    required this.sourceBucket,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (details) {
        if (onAcceptDrop == null) return false;
        return details.data.fromBucket != bucket;
      },
      onAcceptWithDetails: (details) {
        onAcceptDrop?.call(details.data.task, details.data.fromBucket);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          width: 280,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? color.withValues(alpha: 0.08)
                : (isDarkMode
                      ? GlobalVariables.darkSurfaceCard.withValues(alpha: 0.5)
                      : GlobalVariables.surfaceCard.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? color
                  : (isDarkMode
                        ? GlobalVariables.darkBorderPrimary
                        : GlobalVariables.borderPrimary),
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDarkMode
                          ? GlobalVariables.darkTextPrimary
                          : GlobalVariables.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      easy.tr('no_tasks'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? GlobalVariables.darkTextTertiary
                            : GlobalVariables.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: tasks.map((task) {
                        return _DraggableKanbanCard(
                          task: task,
                          fromBucket: sourceBucket,
                          onTap: () => onTaskTap(task),
                          onLongPress: () => onTaskLongPress(task),
                          onDragUpdate: onCardDragUpdate,
                          onDragEnd: onCardDragEnd,
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DragData {
  final Task task;
  final _KanbanBucket fromBucket;

  const _DragData({required this.task, required this.fromBucket});
}

class _DraggableKanbanCard extends StatefulWidget {
  final Task task;
  final _KanbanBucket fromBucket;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  const _DraggableKanbanCard({
    required this.task,
    required this.fromBucket,
    required this.onTap,
    required this.onLongPress,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_DraggableKanbanCard> createState() => _DraggableKanbanCardState();
}

class _DraggableKanbanCardState extends State<_DraggableKanbanCard> {
  Timer? _quickActionTimer;
  Offset? _pointerDownPosition;
  bool _movedTooMuch = false;
  bool _quickActionTriggered = false;

  static const Duration _quickActionHoldDuration = Duration(milliseconds: 500);
  static const double _quickActionMoveTolerance = 10;

  void _cancelQuickActionTimer() {
    _quickActionTimer?.cancel();
    _quickActionTimer = null;
  }

  void _startQuickActionTimer(Offset position) {
    _cancelQuickActionTimer();
    _pointerDownPosition = position;
    _movedTooMuch = false;
    _quickActionTriggered = false;

    _quickActionTimer = Timer(_quickActionHoldDuration, () {
      if (!mounted || _movedTooMuch) return;
      _quickActionTriggered = true;
      widget.onLongPress();
    });
  }

  void _handlePointerMove(Offset position) {
    if (_pointerDownPosition == null || _movedTooMuch) return;

    final dx = position.dx - _pointerDownPosition!.dx;
    final dy = position.dy - _pointerDownPosition!.dy;
    final moveDistanceSquared = (dx * dx) + (dy * dy);
    final toleranceSquared =
        _quickActionMoveTolerance * _quickActionMoveTolerance;

    if (moveDistanceSquared > toleranceSquared) {
      _movedTooMuch = true;
      _cancelQuickActionTimer();
    }
  }

  void _handlePointerUpOrCancel() {
    _cancelQuickActionTimer();
    _pointerDownPosition = null;
    _movedTooMuch = false;
  }

  @override
  void dispose() {
    _cancelQuickActionTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _startQuickActionTimer(event.position),
      onPointerMove: (event) => _handlePointerMove(event.position),
      onPointerUp: (_) => _handlePointerUpOrCancel(),
      onPointerCancel: (_) => _handlePointerUpOrCancel(),
      child: Draggable<_DragData>(
        data: _DragData(task: widget.task, fromBucket: widget.fromBucket),
        onDragStarted: () {
          _cancelQuickActionTimer();
        },
        onDragUpdate: (details) {
          widget.onDragUpdate(details.globalPosition);
        },
        onDragEnd: (_) {
          widget.onDragEnd();
        },
        onDraggableCanceled: (_, __) {
          widget.onDragEnd();
        },
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 260,
            child: _KanbanCardContent(task: widget.task),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _KanbanCardContent(task: widget.task),
        ),
        child: GestureDetector(
          onTap: () {
            if (_quickActionTriggered) {
              _quickActionTriggered = false;
              return;
            }
            widget.onTap();
          },
          child: _KanbanCardContent(task: widget.task),
        ),
      ),
    );
  }
}

class _KanbanCardContent extends StatelessWidget {
  final Task task;

  const _KanbanCardContent({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? GlobalVariables.darkBackgroundSecondary
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? GlobalVariables.darkBorderPrimary
              : GlobalVariables.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey).withValues(
              alpha: 0.08,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? GlobalVariables.darkTextPrimary
                  : GlobalVariables.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GlobalVariables.getPriorityColor(
                    task.priority,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: GlobalVariables.getPriorityColor(
                      task.priority,
                    ).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  task.priorityDisplayName,
                  style: TextStyle(
                    color: GlobalVariables.getPriorityColor(task.priority),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // const SizedBox(width: 6),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              //   decoration: BoxDecoration(
              //     color: GlobalVariables.getStatusColor(task.status)
              //         .withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(4),
              //   ),
              //   child: Text(
              //     task.statusDisplayName,
              //     style: TextStyle(
              //       color: GlobalVariables.getStatusColor(task.status),
              //       fontSize: 10,
              //       fontWeight: FontWeight.w600,
              //     ),
              //   ),
              // ),
              const Spacer(),
              if (task.hasValidDates)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: task.isOverdue
                          ? GlobalVariables.errorRed
                          : (isDarkMode
                                ? GlobalVariables.darkTextSecondary
                                : GlobalVariables.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM dd').format(task.startDate!)} - ${DateFormat('MMM dd').format(task.endDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: task.isOverdue
                            ? GlobalVariables.errorRed
                            : (isDarkMode
                                  ? GlobalVariables.darkTextSecondary
                                  : GlobalVariables.textSecondary),
                        fontSize: 11,
                        fontWeight: task.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (task.progress > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: task.progressPercentage,
                      backgroundColor: isDarkMode
                          ? GlobalVariables.darkBorderPrimary
                          : GlobalVariables.borderPrimary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isCompleted
                            ? GlobalVariables.successGreen
                            : GlobalVariables.primaryBlue,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${task.progress}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDarkMode
                        ? GlobalVariables.darkTextSecondary
                        : GlobalVariables.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
