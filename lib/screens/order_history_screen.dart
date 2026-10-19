import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'transfer_wallet_screen.dart';
import 'reward_store_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Cash', 'Products', 'Pending'

  // Choice Electricals Brand Design System Tokens (Matches Homepage)
  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color textDark = AppColors.textPrimary;
  static const Color darkNavy = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color emeraldSuccess = AppColors.successGreen;
  static const Color amberWarning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadAllActivity();
  }

  Future<void> _loadAllActivity() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getMyOrders(),
        api.getMyWithdrawals(),
      ]);

      if (mounted) {
        setState(() {
          _orders = results[0];
          _withdrawals = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProductThumbnail(dynamic imgData) {
    if (imgData == null) {
      return const Center(
        child: Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF94A3B8)),
      );
    }
    final str = imgData.toString().trim();
    if (str.isEmpty) {
      return const Center(
        child: Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF94A3B8)),
      );
    }

    if (str.startsWith('data:image')) {
      try {
        final base64String = str.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 24, color: Color(0xFFCBD5E1)),
        );
      } catch (_) {
        return const Icon(Icons.broken_image_outlined, size: 24, color: Color(0xFFCBD5E1));
      }
    }

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 24, color: Color(0xFFCBD5E1)),
      );
    }

    return const Icon(Icons.inventory_2_outlined, size: 24, color: Color(0xFF94A3B8));
  }

  // Combine and sort both orders and cash withdrawals by creation date
  List<Map<String, dynamic>> get _combinedActivity {
    final List<Map<String, dynamic>> list = [];

    // Add Product Orders
    for (final o in _orders) {
      list.add({
        'type': 'order',
        'data': o,
        'createdAt': DateTime.tryParse((o['createdAt'] ?? '').toString()) ?? DateTime(2020),
        'status': (o['status'] ?? 'pending').toString().toLowerCase(),
      });
    }

    // Add Cash Withdrawals
    for (final w in _withdrawals) {
      list.add({
        'type': 'withdrawal',
        'data': w,
        'createdAt': DateTime.tryParse((w['createdAt'] ?? '').toString()) ?? DateTime(2020),
        'status': (w['status'] ?? 'pending').toString().toLowerCase(),
      });
    }

    // Sort newest first
    list.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

    // Apply Filter
    if (_selectedFilter == 'Cash') {
      return list.where((item) => item['type'] == 'withdrawal').toList();
    } else if (_selectedFilter == 'Products') {
      return list.where((item) => item['type'] == 'order').toList();
    } else if (_selectedFilter == 'Pending') {
      return list.where((item) => item['status'] == 'pending').toList();
    }

    return list;
  }

  // Calculate totals
  int get _totalCashRedeemed {
    return _withdrawals
        .where((w) => (w['status'] ?? '').toString().toLowerCase() == 'approved')
        .fold(0, (sum, w) => sum + (int.tryParse((w['cashAmount'] ?? w['points'] ?? 0).toString()) ?? 0));
  }

  int get _pendingCount {
    final pendingOrders = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'pending').length;
    final pendingWithdrawals = _withdrawals.where((w) => (w['status'] ?? '').toString().toLowerCase() == 'pending').length;
    return pendingOrders + pendingWithdrawals;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().currentUser;
    final userName = (user?['name'] ?? 'Choice Member').toString();
    final userPhone = (user?['phoneNumber'] ?? 'Registered Member').toString();
    final memberId = user != null ? 'AE${(user['id'] ?? '').toString().substring(0, 8).toUpperCase()}' : 'AE000000';
    final regDate = user?['createdAt'] != null
        ? DateTime.tryParse(user!['createdAt'].toString())?.toLocal().toString().substring(0, 10) ?? '25/01/2025'
        : '25/01/2025';

    final activityList = _combinedActivity;

    return Scaffold(
      backgroundColor: bgSurface,
      // 1. BRAND APP BAR (Matches Homepage styling)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: primaryNavy),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choice Electricals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: primaryNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'ORDERS & CASH STATUS',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: primaryNavy, size: 22),
            onPressed: _loadAllActivity,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllActivity,
        color: secondaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. USER PROFILE HEADER CARD (Matches Homepage)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: darkNavy.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Profile Image with Approved Checkmark
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: secondaryTeal, width: 2),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mem ID $memberId',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Mobile No $userPhone',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Reg Date $regDate',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Approved',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. ACTIVITY RIBBON (Matches Homepage Ribbon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'Orders & Cash Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadAllActivity,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4. DUAL TOP METRIC CARDS (Matches Homepage style)
              Row(
                children: [
                  // Card 1: Solid Navy Blue Card (Total Cash Collected)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransferWalletScreen()),
                        );
                      },
                      child: Container(
                        height: 84,
                        decoration: BoxDecoration(
                          color: primaryNavy,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.currency_exchange_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Cash Paid Out',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ $_totalCashRedeemed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Card 2: White Card with Teal Border (Product Orders Count)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RewardStoreScreen()),
                        );
                      },
                      child: Container(
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: secondaryTeal, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: secondaryTeal,
                              size: 36,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Product Orders',
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_orders.length} items',
                                  style: const TextStyle(
                                    color: secondaryTeal,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 5. MODERN FILTER CHIPS (Pill Selector)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip('All', _orders.length + _withdrawals.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cash', _withdrawals.length, icon: Icons.currency_exchange_rounded),
                    const SizedBox(width: 8),
                    _buildFilterChip('Products', _orders.length, icon: Icons.inventory_2_outlined),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', _pendingCount, isAlert: _pendingCount > 0),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 6. ACTIVITY LIST
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: secondaryTeal)),
                )
              else if (activityList.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activityList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = activityList[index];
                    if (item['type'] == 'withdrawal') {
                      return _buildCashWithdrawalCard(item['data']);
                    } else {
                      return _buildProductOrderCard(item['data']);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {IconData? icon, bool isAlert = false}) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? secondaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryTeal : cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: secondaryTeal.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : textDark),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isAlert ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : (isAlert ? const Color(0xFFDC2626) : textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CASH WITHDRAWAL CARD (Displays real cash status at store counter)
  Widget _buildCashWithdrawalCard(dynamic w) {
    final status = (w['status'] ?? 'pending').toString().toLowerCase();
    final points = w['points'] ?? w['cashAmount'] ?? 0;
    final cash = w['cashAmount'] ?? points;
    final date = DateTime.tryParse(w['createdAt'].toString())?.toLocal() ?? DateTime.now();
    final id = (w['id'] ?? '').toString();
    final ref = id.length >= 8 ? '#CW-${id.substring(0, 8).toUpperCase()}' : '#CW-CASH';
    final adminNotes = (w['adminNotes'] ?? '').toString();

    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'approved') {
      statusBg = const Color(0xFFECFDF5);
      statusColor = emeraldSuccess;
      statusLabel = 'PAID & COLLECTED';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'REFUNDED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = amberWarning;
      statusLabel = 'PENDING PICKUP';
      statusIcon = Icons.pending_actions_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Reference + Date + Status Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CASH PAYOUT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          ref,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cash Icon Container
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.currency_rupee_rounded,
                      color: Color(0xFF059669),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Cash Amount Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹$cash.00 Real Cash',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$points Choice Points Redeemed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondaryTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy · hh:mm a').format(date),
                        style: const TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Store Counter Pickup Guidance Banner (Shown if Pending)
          if (status == 'pending')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.storefront_rounded, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready for pickup: Visit Choice Electricals counter and show your Member ID to receive physical cash.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (adminNotes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Text(
                'Note: $adminNotes',
                style: const TextStyle(fontSize: 11, color: textMuted, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  // PRODUCT ORDER CARD (Reward store items redeemed)
  Widget _buildProductOrderCard(dynamic order) {
    final product = order['product'];
    final date = DateTime.tryParse(order['createdAt'].toString())?.toLocal() ?? DateTime.now();
    final status = (order['status'] ?? 'pending').toString().toLowerCase();

    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'approved') {
      statusBg = const Color(0xFFECFDF5);
      statusColor = emeraldSuccess;
      statusLabel = 'DELIVERED';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusBg = const Color(0xFFFEF2F2);
      statusColor = const Color(0xFFDC2626);
      statusLabel = 'REJECTED';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFFFFBEB);
      statusColor = amberWarning;
      statusLabel = 'PENDING';
      statusIcon = Icons.pending_rounded;
    }

    final images = (product != null && product['images'] is List && (product['images'] as List).isNotEmpty)
        ? (product['images'] as List)
        : [];
    final dynamic firstImage = images.isNotEmpty ? images.first : null;
    final productName = product != null ? (product['name'] ?? 'Electrical Product') : 'Electrical Product';
    final quantity = order['quantity'] ?? 1;
    final coinsSpent = order['coinsSpent'] ?? 0;
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final orderRef = orderId.length >= 6 ? '#CE-${orderId.substring(orderId.length - 6).toUpperCase()}' : '#CE-ORDER';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'REWARD ITEM',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          orderRef,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Product Details Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: _buildProductThumbnail(firstImage),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: darkNavy,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Qty: $quantity unit(s) · $coinsSpent Coins Redeemed',
                        style: const TextStyle(
                          color: secondaryTeal,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy · hh:mm a').format(date),
                        style: const TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long_outlined, size: 30, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _selectedFilter == 'All' ? 'No Activity Found' : 'No $_selectedFilter Activity Found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your product reward purchases and store cash withdrawal requests will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransferWalletScreen()),
                      );
                    },
                    icon: const Icon(Icons.currency_exchange_rounded, size: 16, color: Colors.white),
                    label: const Text('Request Cash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RewardStoreScreen()),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: secondaryTeal),
                    label: const Text('Reward Store', style: TextStyle(color: secondaryTeal, fontWeight: FontWeight.w800, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: secondaryTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
