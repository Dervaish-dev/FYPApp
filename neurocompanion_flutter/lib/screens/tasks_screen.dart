import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:neurocompanion_flutter/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'package:neurocompanion_flutter/models/task.dart';
import 'package:neurocompanion_flutter/screens/task_statistics_screen.dart';
import 'package:neurocompanion_flutter/widgets/task_filter_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final NotificationService _notificationService = NotificationService();
  
  TaskPriority? _filterPriority;
  TaskStatus? _filterStatus;
  DateTimeRange? _filterDateRange;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    context.read<TaskBloc>().add(LoadTasks());
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state is TaskLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.primary),
                  );
                } else if (state is TaskLoaded) {
                  final filteredTasks = _applyFilters(state.tasks);
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TaskBloc>().add(LoadTasks());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: theme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _buildHeader(theme),
                          const SizedBox(height: 16),
                          
                          // Filter and Stats Bar
                          _buildFilterBar(theme),
                          const SizedBox(height: 24),

                          // Metrics Cards
                          _buildMetricsSection(theme, filteredTasks),
                          const SizedBox(height: 24),

                          // Task Categories
                          _buildTaskCategories(theme, filteredTasks),
                        ],
                      ),
                    ),
                  );
                } else if (state is TaskError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<TaskBloc>().add(LoadTasks());
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_box_outline_blank,
                        color: theme.text.withOpacity(0.5),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first task',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(theme),
        );
      },
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.check_box, color: theme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task Scheduling & Guidance',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Organize your tasks and stay on track',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Task',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(AppTheme theme, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Overview',
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Single column layout for mobile
        Column(
          children: [
            _buildMetricCard(
              theme,
              'Today completion',
              '${_calculateTodayCompletion(tasks)}%',
              Icons.show_chart,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              theme,
              'Weekly average',
              '${_calculateWeeklyAverage(tasks)}%',
              Icons.bar_chart,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              theme,
              'Completed today',
              '${_getCompletedToday(tasks)}',
              Icons.check_circle,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    AppTheme theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCategories(AppTheme theme, List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Categories',
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Single column layout for mobile
        Column(
          children: [
            _buildCategoryCard(
              theme,
              'To Do',
              '${tasks.where((t) => t.status == TaskStatus.todo).length}',
              Colors.orange,
              TaskStatus.todo,
              tasks.where((t) => t.status == TaskStatus.todo).toList(),
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              theme,
              'Done',
              '${tasks.where((t) => t.status == TaskStatus.completed).length}',
              Colors.green,
              TaskStatus.completed,
              tasks.where((t) => t.status == TaskStatus.completed).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    AppTheme theme,
    String title,
    String count,
    Color color,
    TaskStatus status,
    List<Task> tasks,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title $count',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task list or empty state
          if (tasks.isEmpty)
            _buildEmptyState(theme, status)
          else
            _buildTaskList(theme, tasks, status),
        ],
      ),
    );
  }

  Widget _buildTaskList(AppTheme theme, List<Task> tasks, TaskStatus status) {
    return Column(
      children: tasks.map((task) => _buildTaskItem(theme, task)).toList(),
    );
  }

  Widget _buildTaskItem(AppTheme theme, Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: task.status == TaskStatus.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: theme.text.withOpacity(0.7)),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editTask(task);
                      break;
                    case 'delete':
                      _deleteTask(task);
                      break;
                    case 'complete':
                      _toggleTaskStatus(task);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('Mark Complete'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              // Priority indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.priority.name.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Due date
              if (task.dueDate != null) ...[
                Icon(
                  Icons.calendar_today,
                  color: theme.text.withOpacity(0.6),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${task.dueDate!.day}/${task.dueDate!.month}',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Reminder time
              if (task.reminderTime != null) ...[
                Icon(Icons.alarm, color: theme.text.withOpacity(0.6), size: 16),
                const SizedBox(width: 4),
                Text(
                  'Remind: ${task.reminderTime!.format(context)}',
                  style: TextStyle(
                    color: theme.text.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme, TaskStatus status) {
    String message = '';
    IconData icon = Icons.check_box_outlined;

    switch (status) {
      case TaskStatus.todo:
        message = 'No tasks in to do';
        icon = Icons.add_task;
        break;
      case TaskStatus.inProgress:
        message = 'No tasks in progress';
        icon = Icons.hourglass_empty;
        break;
      case TaskStatus.completed:
        message = 'No tasks completed';
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.text.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: theme.text.withOpacity(0.5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(AppTheme theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(child: Text('😘', style: const TextStyle(fontSize: 24))),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.priority_high,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.green;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  void _showAddTaskDialog() {
    showDialog(context: context, builder: (context) => _AddTaskDialog());
  }

  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(editingTask: task),
    );
  }

  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context).currentTheme.card,
        title: Text(
          'Delete Task',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).currentTheme.text,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).currentTheme.text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Provider.of<ThemeProvider>(
                  context,
                ).currentTheme.text.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTask(taskId: task.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task "${task.title}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    TaskStatus newStatus;
    if (task.status == TaskStatus.completed) {
      newStatus = TaskStatus.todo;
    } else {
      newStatus = TaskStatus.completed;
    }

    context.read<TaskBloc>().add(
      UpdateTaskStatus(taskId: task.id, status: newStatus),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task "${task.title}" ${newStatus == TaskStatus.completed ? 'completed' : 'moved to todo'}',
        ),
        backgroundColor: newStatus == TaskStatus.completed
            ? Colors.green
            : Colors.blue,
      ),
    );
  }

  int _calculateTodayCompletion(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final today = DateTime.now();
    final todayTasks = tasks.where((task) {
      return task.createdAt.year == today.year &&
          task.createdAt.month == today.month &&
          task.createdAt.day == today.day;
    }).toList();

    if (todayTasks.isEmpty) return 0;
    final completedToday = todayTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    return ((completedToday / todayTasks.length) * 100).round();
  }

  int _calculateWeeklyAverage(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weeklyTasks = tasks
        .where((task) => task.createdAt.isAfter(weekAgo))
        .toList();

    if (weeklyTasks.isEmpty) return 0;
    final completedWeekly = weeklyTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    return ((completedWeekly / weeklyTasks.length) * 100).round();
  }

  int _getCompletedToday(List<Task> tasks) {
    final today = DateTime.now();
    return tasks.where((task) {
      return task.status == TaskStatus.completed &&
          task.completedAt != null &&
          task.completedAt!.year == today.year &&
          task.completedAt!.month == today.month &&
          task.completedAt!.day == today.day;
    }).length;
  }

  List<Task> _applyFilters(List<Task> tasks) {
    var filtered = tasks;

    if (_filterPriority != null) {
      filtered = filtered.where((t) => t.priority == _filterPriority).toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((t) => t.status == _filterStatus).toList();
    }

    if (_filterDateRange != null) {
      filtered = filtered.where((t) {
        if (t.dueDate == null) return false;
        return t.dueDate!.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
               t.dueDate!.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Widget _buildFilterBar(AppTheme theme) {
    final hasFilters = _filterPriority != null || _filterStatus != null || _filterDateRange != null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TaskFilterSheet(
                  selectedPriority: _filterPriority,
                  selectedStatus: _filterStatus,
                  selectedDateRange: _filterDateRange,
                  onPriorityChanged: (p) => setState(() => _filterPriority = p),
                  onStatusChanged: (s) => setState(() => _filterStatus = s),
                  onDateRangeChanged: (d) => setState(() => _filterDateRange = d),
                  onReset: () {
                    setState(() {
                      _filterPriority = null;
                      _filterStatus = null;
                      _filterDateRange = null;
                    });
                  },
                ),
              );
            },
            icon: Icon(
              hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasFilters ? theme.primary : theme.text.withOpacity(0.7),
            ),
            label: Text(
              hasFilters ? 'Filtered' : 'Filter',
              style: TextStyle(
                color: hasFilters ? theme.primary : theme.text.withOpacity(0.7),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasFilters ? theme.primary : theme.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaskStatisticsScreen(),
              ),
            );
          },
          icon: Icon(
            Icons.bar_chart,
            color: theme.text.withOpacity(0.7),
          ),
          label: Text(
            'Stats',
            style: TextStyle(
              color: theme.text.withOpacity(0.7),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _AddTaskDialog extends StatefulWidget {
  final Task? editingTask;

  const _AddTaskDialog({this.editingTask});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _reminderTime;
  TaskPriority _priority = TaskPriority.medium;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingTask != null) {
      _titleController.text = widget.editingTask!.title;
      _descriptionController.text = widget.editingTask!.description ?? '';
      _dueDate = widget.editingTask!.dueDate;
      _reminderTime = widget.editingTask!.reminderTime;
      _priority = widget.editingTask!.priority;
      _hasReminder = widget.editingTask!.reminderTime != null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return AlertDialog(
          backgroundColor: theme.card,
          title: Text(
            widget.editingTask != null ? 'Edit Task' : 'Add New Task',
            style: TextStyle(color: theme.text),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      labelStyle: TextStyle(color: theme.text.withOpacity(0.8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.card,
                    ),
                    style: TextStyle(color: theme.text, fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a task title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Task Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: theme.text.withOpacity(0.8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.card,
                    ),
                    style: TextStyle(color: theme.text, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Priority Selection
                  DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      labelStyle: TextStyle(color: theme.text.withOpacity(0.8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: theme.card,
                    ),
                    dropdownColor: theme.card,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    items: TaskPriority.values.map((priority) {
                      Color priorityColor = _getPriorityColor(priority);
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              priority.name.toUpperCase(),
                              style: TextStyle(
                                color: theme.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _priority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  ListTile(
                    title: Text(
                      'Due Date',
                      style: TextStyle(color: theme.text),
                    ),
                    subtitle: Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'No due date',
                      style: TextStyle(color: theme.text.withOpacity(0.7)),
                    ),
                    trailing: Icon(Icons.calendar_today, color: theme.primary),
                    onTap: _selectDueDate,
                  ),
                  const SizedBox(height: 16),

                  // Reminder Toggle
                  SwitchListTile(
                    title: Text(
                      'Set Reminder',
                      style: TextStyle(color: theme.text),
                    ),
                    subtitle: Text(
                      'Get notified about this task',
                      style: TextStyle(color: theme.text.withOpacity(0.7)),
                    ),
                    value: _hasReminder,
                    onChanged: (value) {
                      setState(() {
                        _hasReminder = value;
                        if (value) {
                          _selectReminderTime();
                        }
                      });
                    },
                    activeColor: theme.primary,
                  ),

                  // Reminder Time
                  if (_hasReminder) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        'Reminder Time',
                        style: TextStyle(color: theme.text),
                      ),
                      subtitle: Text(
                        _reminderTime != null
                            ? '${_reminderTime!.hour}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                            : 'Select time',
                        style: TextStyle(color: theme.text.withOpacity(0.7)),
                      ),
                      trailing: Icon(Icons.access_time, color: theme.primary),
                      onTap: _selectReminderTime,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.text.withOpacity(0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                widget.editingTask != null ? 'Update Task' : 'Save Task',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final task = Task(
        id:
            widget.editingTask?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        status: widget.editingTask?.status ?? TaskStatus.todo,
        dueDate: _dueDate,
        reminderTime: _reminderTime,
        createdAt: widget.editingTask?.createdAt ?? DateTime.now(),
        completedAt: widget.editingTask?.completedAt,
      );

      if (widget.editingTask != null) {
        // Update existing task
        context.read<TaskBloc>().add(UpdateTask(task: task));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" updated successfully!'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // Add new task
        context.read<TaskBloc>().add(AddTask(task: task));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Schedule notification if reminder is set
      if (_hasReminder && _reminderTime != null) {
        _scheduleNotification(task);
      }

      Navigator.pop(context);
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.green;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  Future<void> _scheduleNotification(Task task) async {
    if (task.reminderTime == null) return;

    final now = DateTime.now();
    var reminderDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      task.reminderTime!.hour,
      task.reminderTime!.minute,
    );

    if (reminderDateTime.isBefore(now)) {
      reminderDateTime = reminderDateTime.add(const Duration(days: 1));
    }

    final notificationService = NotificationService();
    await notificationService.scheduleNotification(
      id: task.id.hashCode,
      title: 'Task Reminder',
      body: 'Don\'t forget: ${task.title}',
      scheduledDate: reminderDateTime,
      channel: NotificationChannel.tasks,
      payload: 'task:${task.id}',
    );
  }
}
