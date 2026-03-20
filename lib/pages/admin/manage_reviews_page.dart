import 'package:flutter/material.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../widgets/review_card.dart';

class ManageReviewsPage extends StatefulWidget {
  const ManageReviewsPage({super.key});

  @override
  State<ManageReviewsPage> createState() => _ManageReviewsPageState();
}

class _ManageReviewsPageState extends State<ManageReviewsPage>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();

  late TabController _tabController;
  String _selectedStatus = 'Pending';

  List<Review> _pendingReviews = [];
  List<Review> _approvedReviews = [];
  List<Review> _rejectedReviews = [];
  List<Review> _allReviews = [];

  bool _isLoading = true;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        setState(() => _selectedStatus = 'Pending');
        break;
      case 1:
        setState(() => _selectedStatus = 'Approved');
        break;
      case 2:
        setState(() => _selectedStatus = 'Rejected');
        break;
      case 3:
        setState(() => _selectedStatus = 'All');
        break;
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _reviewService.getAllReviews(statusFilter: 'Pending'),
        _reviewService.getAllReviews(statusFilter: 'Approved'),
        _reviewService.getAllReviews(statusFilter: 'Rejected'),
        _reviewService.getAllReviews(),
      ]);

      setState(() {
        _pendingReviews = results[0];
        _approvedReviews = results[1];
        _rejectedReviews = results[2];
        _allReviews = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reviews: $e')));
      }
    }
  }

  List<Review> get _currentReviews {
    switch (_selectedStatus) {
      case 'Pending':
        return _pendingReviews;
      case 'Approved':
        return _approvedReviews;
      case 'Rejected':
        return _rejectedReviews;
      case 'All':
        return _allReviews;
      default:
        return _pendingReviews;
    }
  }

  Future<void> _approveReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Review'),
        content: Text('Are you sure you want to approve this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isApproving = true);

    try {
      await _reviewService.approveReview(review.id);
      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving review: $e')));
      }
    } finally {
      setState(() => _isApproving = false);
    }
  }

  Future<void> _rejectReview(Review review) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Rejection reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminNote = noteController.text.trim();
    if (adminNote.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide a rejection reason')),
        );
      }
      return;
    }

    setState(() => _isApproving = true);

    try {
      await _reviewService.rejectReview(review.id, adminNote);
      await _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting review: $e')));
      }
    } finally {
      setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReviews,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Badge(
                label: Text('${_pendingReviews.length}'),
                child: const Text('Pending'),
              ),
            ),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final reviews = _currentReviews;

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $_selectedStatus Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          // Safe substring - handle short userIds
          final userIdDisplay = review.userId.length >= 8 
              ? review.userId.substring(0, 8) 
              : review.userId;
          return ReviewCard(
            review: review,
            userName: 'User $userIdDisplay',
            showStatus: true,
            onApprove: review.status == 'Pending'
                ? () => _approveReview(review)
                : null,
            onReject: review.status == 'Pending'
                ? () => _rejectReview(review)
                : null,
          );
        },
      ),
    );
  }
}

/// Stats card showing review statistics
class ReviewStatsCard extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;

  const ReviewStatsCard({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatItem('Pending', pendingCount, Colors.orange),
            const VerticalDivider(width: 32),
            _buildStatItem('Approved', approvedCount, Colors.green),
            const VerticalDivider(width: 32),
            _buildStatItem('Rejected', rejectedCount, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
