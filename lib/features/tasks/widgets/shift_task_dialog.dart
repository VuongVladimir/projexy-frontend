import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/features/tasks/services/tasks_service.dart';
import 'package:frontend/models/task.dart';
import 'package:intl/intl.dart';

class ShiftTaskDialog extends StatefulWidget {
  final Task task;
  final VoidCallback onShifted;
  
  const ShiftTaskDialog({
    super.key,
    required this.task,
    required this.onShifted,
  });
  
  @override
  State<ShiftTaskDialog> createState() => _ShiftTaskDialogState();
}

class _ShiftTaskDialogState extends State<ShiftTaskDialog> {
  final _controller = TextEditingController();
  int _selectedDays = 0;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('shift_task'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? GlobalVariables.darkTextPrimary
                    : GlobalVariables.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('shift_description'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode
                    ? GlobalVariables.darkTextSecondary
                    : GlobalVariables.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickButton(-7, '-7d'),
                _buildQuickButton(-3, '-3d'),
                _buildQuickButton(-1, '-1d'),
                _buildQuickButton(1, '+1d'),
                _buildQuickButton(3, '+3d'),
                _buildQuickButton(7, '+7d'),
                _buildQuickButton(30, '+30d'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Custom input
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
              ],
              decoration: InputDecoration(
                labelText: tr('custom_days'),
                hintText: tr('enter_number_days'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                setState(() => _selectedDays = int.tryParse(val) ?? 0);
              },
            ),
            const SizedBox(height: 24),
            
            // Preview
            if (_selectedDays != 0 && widget.task.hasValidDates) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GlobalVariables.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GlobalVariables.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('preview'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GlobalVariables.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tr('current')}: ${_formatDateRange(widget.task.startDate!, widget.task.endDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDarkMode
                            ? GlobalVariables.darkTextPrimary
                            : GlobalVariables.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tr('after_shift')}: ${_formatDateRange(
                        widget.task.startDate!.add(Duration(days: _selectedDays)),
                        widget.task.endDate!.add(Duration(days: _selectedDays)),
                      )}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: GlobalVariables.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedDays != 0 ? _shift : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlobalVariables.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(tr('shift')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickButton(int days, String label) {
    final isSelected = _selectedDays == days;
    
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedDays = days;
          _controller.text = days.toString();
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected 
            ? GlobalVariables.primaryBlue.withValues(alpha: 0.1) 
            : null,
        side: BorderSide(
          color: isSelected 
              ? GlobalVariables.primaryBlue 
              : Colors.grey.shade400,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected 
              ? GlobalVariables.primaryBlue 
              : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
  
  String _formatDateRange(DateTime start, DateTime end) {
    return '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}';
  }
  
  void _shift() {
    if (!widget.task.hasValidDates) {
      showSnackBar(context, tr('task_must_have_dates'));
      return;
    }

    TasksService.shiftTask(
      context: context,
      taskId: widget.task.id,
      deltaDays: _selectedDays,
      onSuccess: () {
        Navigator.pop(context);
        widget.onShifted();
        showSnackBar(context, tr('task_shifted_successfully'));
      },
    );
  }
}
