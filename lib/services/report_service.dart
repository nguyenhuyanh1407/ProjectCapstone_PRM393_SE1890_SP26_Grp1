import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/report.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  List<Report> _reports = [];
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final response = await rootBundle.loadString('assets/data/reports.json');
    final data = json.decode(response) as List;

    _reports = data.map((json) => Report.fromJson(json)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isInitialized = true;
  }

  Future<List<Report>> getReports() async {
    await init();
    return List<Report>.from(_reports);
  }

  Future<List<Report>> filterReportsByStatus(String status) async {
    await init();
    if (status == 'All') return getReports();
    return _reports.where((report) => report.status == status).toList();
  }

  Future<void> updateReportStatus(String reportId, String newStatus) async {
    await init();
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) return;
    _reports[index] = _reports[index].copyWith(status: newStatus);
  }
}
