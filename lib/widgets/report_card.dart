import 'package:flutter/material.dart';

import '../models/report.dart';
import '../utils/formatter.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final ValueChanged<String?> onStatusChanged;

  const ReportCard({
    super.key,
    required this.report,
    required this.onStatusChanged,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'Reviewed':
        return Colors.blue;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${report.reporterName} reported ${report.reportedUserName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.reason,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              Formatter.formatDate(report.createdAt),
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                report.messagePreview,
                style: TextStyle(color: Colors.grey[800], height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: report.status,
              decoration: const InputDecoration(
                labelText: 'Update status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'Reviewed', child: Text('Reviewed')),
                DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
              ],
              onChanged: onStatusChanged,
            ),
          ],
        ),
      ),
    );
  }
}
