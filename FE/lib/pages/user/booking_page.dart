import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tour.dart';
import '../../models/booking.dart';
import '../../models/trip_session.dart';
import '../../services/tour_service.dart';
import '../../services/booking_service.dart';
import '../../services/trip_session_service.dart';
import '../../services/payos_service.dart';
import '../../constants/app_colors.dart';
import '../../utils/formatter.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> with WidgetsBindingObserver {
  final TourService _tourService = TourService();
  final BookingService _bookingService = BookingService();
  final TripSessionService _sessionService = TripSessionService();
  final PayOSService _payosService = PayOSService();

  Tour? _tour;
  bool _isLoading = true;
  bool _isBooking = false;
  int _participants = 1;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  // Booking type
  String _bookingType = 'private'; // "private" or "group"
  TripSession? _existingSession;
  List<TripSession> _openGroupSessions = [];
  bool _checkingSession = false;

  // PayOS state
  Booking? _pendingBooking;
  int? _paymentOrderCode;
  bool _waitingForPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPayment) {
      _checkPaymentStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tour == null) {
      final tourId = ModalRoute.of(context)!.settings.arguments as String;
      _loadTour(tourId);
    }
  }

  Future<void> _loadTour(String id) async {
    try {
      final tour = await _tourService.getTourById(id);
      setState(() {
        _tour = tour;
        _isLoading = false;
      });
      _loadOpenGroupSessions(id);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOpenGroupSessions(String tourId) async {
    try {
      final sessions = await _sessionService.getOpenGroupSessions(tourId);
      if (mounted) setState(() => _openGroupSessions = sessions);
    } catch (e) {
      // Index not ready or query failed — ignore silently
      debugPrint('Load group sessions error: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _participants = 1;
      });
      if (_bookingType == 'group') {
        _checkGroupSession();
      }
    }
  }

  Future<void> _checkGroupSession() async {
    if (_tour == null) return;
    setState(() => _checkingSession = true);

    try {
      final session =
          await _sessionService.findGroupSession(_tour!.id, _selectedDate);

      if (mounted) {
        setState(() {
          _existingSession = session;
          _checkingSession = false;
          _participants = 1;
        });
      }
    } catch (e) {
      debugPrint('Check group session error: $e');
      if (mounted) {
        setState(() {
          _existingSession = null;
          _checkingSession = false;
          _participants = 1;
        });
      }
    }
  }

  int get _maxParticipantsAllowed {
    if (_bookingType == 'private') {
      return _tour?.maxParticipants ?? 1;
    }
    // Group: if existing session, limit to remaining slots
    if (_existingSession != null) {
      return _existingSession!.remainingSlots.clamp(1, _tour?.maxParticipants ?? 1);
    }
    return _tour?.maxParticipants ?? 1;
  }

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _tour == null) return;

    setState(() => _isBooking = true);

    try {
      final totalPrice = _tour!.basePrice * _participants;
      final orderCode = DateTime.now().millisecondsSinceEpoch % 100000000;
      final bookingId = 'BK-$orderCode';

      // 1. Handle TripSession
      String sessionId;

      if (_bookingType == 'group' && _existingSession != null) {
        // Join existing group session
        sessionId = _existingSession!.id;
        await _sessionService.addSlots(
            sessionId, _participants, _existingSession!.maxSlots);
      } else {
        // Create new session (private or new group)
        sessionId = 'TS-$orderCode';
        final session = TripSession(
          id: sessionId,
          tourId: _tour!.id,
          date: _selectedDate,
          type: _bookingType,
          createdByUserId: user.uid,
          maxSlots: _tour!.maxParticipants,
          bookedSlots: _participants,
          status: _bookingType == 'private' ? 'Closed' : 'Open',
        );
        await _sessionService.createSession(session);
      }

      // 2. Create booking
      final booking = Booking(
        id: bookingId,
        tourId: _tour!.id,
        userId: user.uid,
        bookingDate: _selectedDate,
        status: 'Pending',
        participants: _participants,
        totalPrice: totalPrice,
        paymentOrderCode: orderCode,
        bookingType: _bookingType,
        tripSessionId: sessionId,
      );

      await _bookingService.createBooking(booking);

      setState(() {
        _pendingBooking = booking;
        _paymentOrderCode = orderCode;
      });

      // 3. PayOS payment
      final payosAmount = totalPrice.toInt();
      final result = await _payosService.createPaymentLink(
        orderCode: orderCode,
        amount: payosAmount,
        description: 'Booking Tour #$orderCode'.length > 25
            ? 'Tour #$orderCode'
            : 'Booking Tour #$orderCode',
        buyerName: user.displayName,
        buyerEmail: user.email,
        returnUrl: 'https://payos.vn/payment-success',
        cancelUrl: 'https://payos.vn/payment-cancel',
      );

      if (result['success'] == true) {
        final checkoutUrl = result['checkoutUrl'] as String;
        setState(() => _waitingForPayment = true);
        final uri = Uri.parse(checkoutUrl);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showResultDialog(
            title: 'Booking Created',
            icon: Icons.warning,
            iconColor: Colors.orange,
            message:
                'Payment link error: ${result['message']}\nBooking saved as Pending.',
            bookingId: bookingId,
            totalPrice: totalPrice,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_paymentOrderCode == null) return;
    setState(() => _isBooking = true);

    try {
      final result = await _payosService.getPaymentStatus(_paymentOrderCode!);

      if (result['success'] == true && result['status'] == 'PAID') {
        await _bookingService.updateBookingStatus(_pendingBooking!.id, 'Paid');
        setState(() => _waitingForPayment = false);
        if (mounted) {
          _showResultDialog(
            title: 'Payment Successful!',
            icon: Icons.check_circle,
            iconColor: Colors.green,
            message: 'Status: PAID',
            bookingId: _pendingBooking!.id,
            totalPrice: _pendingBooking!.totalPrice,
          );
        }
      } else if (result['status'] == 'CANCELLED') {
        await _bookingService.updateBookingStatus(
            _pendingBooking!.id, 'Cancelled');
        setState(() => _waitingForPayment = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Payment cancelled'),
                backgroundColor: Colors.orange),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [
                Icon(Icons.access_time, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Waiting for payment'),
              ]),
              content: const Text('Payment not completed yet.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _checkPaymentStatus();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                  child: const Text('Check Again'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showResultDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String message,
    required String bookingId,
    required double totalPrice,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tour: ${_tour!.title}'),
            const SizedBox(height: 4),
            Text(
                'Type: ${_bookingType == 'group' ? 'Join Group' : 'Private'}'),
            const SizedBox(height: 4),
            Text('Total: ${Formatter.formatCurrency(totalPrice)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text('ID: $bookingId',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tour == null) {
      return const Scaffold(body: Center(child: Text('Tour not found.')));
    }

    final totalPrice = _tour!.basePrice * _participants;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Tour'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(
                  Formatter.formatCurrency(totalPrice),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isBooking ? null : _confirmBooking,
                icon: _isBooking
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.payment),
                label: Text(
                    _isBooking ? 'Processing...' : 'Confirm & Pay',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
            if (_waitingForPayment) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _checkPaymentStatus,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Check Payment Status'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tour info card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _tour!.images.isNotEmpty
                            ? _tour!.images
                                .firstWhere((img) => img.isPrimary,
                                    orElse: () => _tour!.images.first)
                                .url
                            : '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child:
                                const Icon(Icons.image, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_tour!.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            '${Formatter.formatCurrency(_tour!.basePrice)} / person',
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ===== BOOKING TYPE TOGGLE =====
            const Text('Booking Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildTypeCard(
                  type: 'private',
                  icon: Icons.person,
                  title: 'Private',
                  subtitle: 'Book for your group only',
                ),
                const SizedBox(width: 12),
                _buildTypeCard(
                  type: 'group',
                  icon: Icons.groups,
                  title: 'Join Group',
                  subtitle: 'Join with other travelers',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ===== SELECT DATE =====
            const Text('Select Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            // Show existing group sessions
            if (_bookingType == 'group' && _openGroupSessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Available Group Sessions:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _openGroupSessions.length,
                  itemBuilder: (ctx, i) {
                    final s = _openGroupSessions[i];
                    final isSelected =
                        _dateString(s.date) == _dateString(_selectedDate);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = s.date;
                          _existingSession = s;
                          _participants = 1;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300),
                        ),
                        child: Text(
                          '${s.date.day}/${s.date.month} (${s.remainingSlots} slots)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Group session info
            if (_bookingType == 'group') ...[
              const SizedBox(height: 12),
              if (_checkingSession)
                const Center(
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_existingSession != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.groups, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Group session found! ${_existingSession!.bookedSlots} joined, ${_existingSession!.remainingSlots} slots left.',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No group yet for this date. You will start a new group!',
                          style: TextStyle(fontSize: 13, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),

            // ===== PARTICIPANTS =====
            const Text('Participants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _participants > 1
                        ? () => setState(() => _participants--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                  ),
                  Text('$_participants',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _participants < _maxParticipantsAllowed
                        ? () => setState(() => _participants++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Text(
              _bookingType == 'group' && _existingSession != null
                  ? 'Available: ${_existingSession!.remainingSlots} slots'
                  : 'Max: ${_tour!.maxParticipants} participants',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // ===== PRICE SUMMARY =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _priceRow('Booking Type',
                      _bookingType == 'group' ? 'Join Group' : 'Private'),
                  const SizedBox(height: 8),
                  _priceRow('Price per person',
                      Formatter.formatCurrency(_tour!.basePrice)),
                  const SizedBox(height: 8),
                  _priceRow('Participants', 'x $_participants'),
                  const Divider(height: 20),
                  _priceRow('Total', Formatter.formatCurrency(totalPrice),
                      isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Payment info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.payment, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment via PayOS (QR Code / Bank Transfer)',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _bookingType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _bookingType = type;
            _existingSession = null;
            _participants = 1;
          });
          if (type == 'group') _checkGroupSession();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 28),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? Colors.green : null)),
      ],
    );
  }

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
