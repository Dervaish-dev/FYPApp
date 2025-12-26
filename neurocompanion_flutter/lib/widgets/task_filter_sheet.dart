import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/models/task.dart';
import 'package:intl/intl.dart';

class TaskFilterSheet extends StatefulWidget {
  final TaskPriority? selectedPriority;
  final TaskStatus? selectedStatus;
  final DateTimeRange? selectedDateRange;
  final Function(TaskPriority?) onPriorityChanged;
  final Function(TaskStatus?) onStatusChanged;
  final Function(DateTimeRange?) onDateRangeChanged;
  final VoidCallback onReset;

  const TaskFilterSheet({
    super.key,
    this.selectedPriority,
    this.selectedStatus,
    this.selectedDateRange,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onReset,
  });

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskPriority? _priority;
  late TaskStatus? _status;
  late DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _priority = widget.selectedPriority;
    _status = widget.selectedStatus;
    _dateRange = widget.selectedDateRange;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Tasks',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _priority = null;
                        _status = null;
                        _dateRange = null;
                      });
                      widget.onReset();
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(color: theme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Priority Filter
              Text(
                'Priority',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    theme,
                    'All',
                    _priority == null,
                    () {
                      setState(() => _priority = null);
                      widget.onPriorityChanged(null);
                    },
                  ),
                  ...TaskPriority.values.map((p) => _buildFilterChip(
                    theme,
                    p.name[0].toUpperCase() + p.name.substring(1),
                    _priority == p,
                    () {
                      setState(() => _priority = p);
                      widget.onPriorityChanged(p);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // Status Filter
              Text(
                'Status',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip(
                    theme,
                    'All',
                    _status == null,
                    () {
                      setState(() => _status = null);
                      widget.onStatusChanged(null);
                    },
                  ),
                  ...TaskStatus.values.map((s) => _buildFilterChip(
                    theme,
                    s == TaskStatus.inProgress 
                        ? 'In Progress' 
                        : s.name[0].toUpperCase() + s.name.substring(1),
                    _status == s,
                    () {
                      setState(() => _status = s);
                      widget.onStatusChanged(s);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 24),

              // Date Range Filter
              Text(
                'Due Date',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _dateRange,
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: theme.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    setState(() => _dateRange = range);
                    widget.onDateRangeChanged(range);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _dateRange == null
                            ? 'Select date range'
                            : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                        style: TextStyle(
                          color: theme.text.withOpacity(_dateRange == null ? 0.5 : 1),
                          fontSize: 14,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: theme.text.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (_dateRange != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() => _dateRange = null);
                    widget.onDateRangeChanged(null);
                  },
                  child: Text(
                    'Clear date range',
                    style: TextStyle(color: theme.primary),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(AppTheme theme, String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.background,
      selectedColor: theme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: selected ? theme.primary : theme.text,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? theme.primary : theme.border,
      ),
    );
  }
}
