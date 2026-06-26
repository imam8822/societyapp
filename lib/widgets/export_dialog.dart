import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/api/api_services.dart';
import '../core/constants.dart';

class ExportStatementDialog extends ConsumerStatefulWidget {
  const ExportStatementDialog({super.key});

  @override
  ConsumerState<ExportStatementDialog> createState() => _ExportStatementDialogState();
}

class _ExportStatementDialogState extends ConsumerState<ExportStatementDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _format = 'pdf'; // 'pdf' or 'csv'
  
  bool _isExporting = false;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: AppTheme.theme,
          child: child!,
        );
      },
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final ext = _format == 'pdf' ? '.pdf' : '.csv';
      final fileName = 'Statement_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}$ext';
      final savePath = '${tempDir.path}/$fileName';

      await TransactionApi.exportStatement(
        startDate: _startDate,
        endDate: _endDate,
        format: _format,
        savePath: savePath,
      );

      if (mounted) {
        Navigator.pop(context); // close dialog
        
        // Open the file locally
        final uri = Uri.file(savePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Successful! Saved to: $fileName'),
            backgroundColor: context.colors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${apiError(e)}'), 
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      title: const Text('Export Statement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format Selection
            Text('Format', style: TextStyle(color: context.colors.textGrey, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _FormatButton(
                    label: 'PDF',
                    icon: Icons.picture_as_pdf,
                    isSelected: _format == 'pdf',
                    onTap: () => setState(() => _format = 'pdf'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FormatButton(
                    label: 'CSV',
                    icon: Icons.table_chart,
                    isSelected: _format == 'csv',
                    onTap: () => setState(() => _format = 'csv'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Date Range
            Text('Date Range (Optional)', style: TextStyle(color: context.colors.textGrey, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: context.colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                            : 'All Time',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                        }),
                      )
                  ],
                ),
              ),
            ),
            

          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isExporting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isExporting ? null : _handleExport,
                child: _isExporting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Export'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? context.colors.primary : context.colors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? context.colors.primary : context.colors.textGrey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? context.colors.primary : context.colors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
