import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/report_card.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  final ReportService _reportService = ReportService();
  List<Report> _reports = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';

  final List<String> _statuses = ['All', 'Pending', 'Reviewed', 'Resolved', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = _selectedStatus == 'All'
        ? await _reportService.getReports()
        : await _reportService.filterReportsByStatus(_selectedStatus);

    if (!mounted) return;
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(Report report, String? newStatus) async {
    if (newStatus == null || newStatus == report.status) return;
    await _reportService.updateReportStatus(report.id, newStatus);
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statuses.map((status) {
                    return ChoiceChip(
                      label: Text(status),
                      selected: status == _selectedStatus,
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        _loadReports();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ..._reports.map(
                  (report) => ReportCard(
                    report: report,
                    onStatusChanged: (value) => _updateStatus(report, value),
                  ),
                ),
              ],
            ),
    );
  }
}
