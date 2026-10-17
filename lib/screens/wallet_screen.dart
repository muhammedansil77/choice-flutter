import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  // Choice Electricals Brand Design System Tokens
  static const Color darkNavy = AppColors.textPrimary;
  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color secondaryGray = AppColors.textSecondary;
  static const Color borderSubtle = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color emeraldSuccess = AppColors.successGreen;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet({bool forceRefresh = false}) async {
    if (_balance == 0 || forceRefresh) {
      setState(() => _isLoading = true);
    }
    try {
      final wallet = await context.read<ApiService>().getMyWallet(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _balance = wallet['balance'] ?? wallet['coinBalance'] ?? 0;
          _transactions = wallet['transactions'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: const Text(
          'My Wallet',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _fetchWallet(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white),
            tooltip: 'Refresh Balance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: secondaryTeal),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchWallet(forceRefresh: true),
              color: secondaryTeal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LUXURY EXECUTIVE WALLET CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryNavy,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: secondaryTeal.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Top Bar: Brand tag + Chip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: secondaryTeal.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.electric_bolt_rounded,
                                        size: 18,
                                        color: secondaryTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'CHOICE COINS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 12, color: secondaryTeal),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Balance Caption
                          const Text(
                            'AVAILABLE BALANCE',
                            style: TextStyle(
                              color: secondaryTeal,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Large Balance Number
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '🪙',
                                style: TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_balance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  'COINS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Card Footer: Info Note
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: secondaryTeal),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '1 Choice Coin = ₹1 Store Value · Redeemable at checkout',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // RECENT ACTIVITY HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: darkNavy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (_transactions.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_transactions.length} total',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: secondaryGray,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // TRANSACTION LIST OR EMPTY STATE
                    if (_transactions.isEmpty)
                      _buildEmptyActivity()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final currentUser = context.read<ApiService>().currentUser;
                          final currentUserId =
                              (currentUser?['id'] ?? currentUser?['_id'])?.toString();

                          final receiverId = tx['receiverId']?.toString();
                          final senderId = tx['senderId']?.toString();
                          final rawType =
                              (tx['transactionType'] ?? tx['type'] ?? '').toString().toLowerCase();

                          bool isCredit;
                          if (tx['isCredit'] is bool) {
                            isCredit = tx['isCredit'] as bool;
                          } else if (currentUserId != null && currentUserId.isNotEmpty) {
                            if (receiverId == currentUserId) {
                              isCredit = true;
                            } else if (senderId == currentUserId) {
                              isCredit = false;
                            } else {
                              isCredit = rawType == 'distribution' ||
                                  rawType == 'credit' ||
                                  rawType == 'reward' ||
                                  rawType == 'added' ||
                                  rawType == 'mint' ||
                                  rawType == 'refund' ||
                                  rawType == 'deposit';
                            }
                          } else {
                            isCredit = rawType == 'distribution' ||
                                rawType == 'credit' ||
                                rawType == 'reward' ||
                                rawType == 'added' ||
                                rawType == 'mint' ||
                                rawType == 'refund' ||
                                rawType == 'deposit';
                          }

                          // Parse and format date safely
                          DateTime? date;
                          if (tx['createdAt'] != null) {
                            try {
                              date = DateTime.parse(tx['createdAt'].toString()).toLocal();
                            } catch (_) {}
                          }
                          final dateStr = date != null
                              ? DateFormat('dd MMM yyyy · hh:mm a').format(date)
                              : '';

                          // Format amount safely
                          final num rawAmount = tx['amount'] is num
                              ? (tx['amount'] as num)
                              : (num.tryParse(tx['amount']?.toString() ?? '0') ?? 0);
                          final num absAmount = rawAmount.abs();
                          final amountText = (absAmount % 1 == 0)
                              ? absAmount.toInt().toString()
                              : absAmount.toString();
                          final formattedAmount = '${isCredit ? '+' : '-'}$amountText Coins';

                          // Title
                          final note = tx['note']?.toString();
                          final desc = tx['description']?.toString();
                          String title;
                          if (note != null && note.trim().isNotEmpty) {
                            title = note.trim();
                          } else if (desc != null && desc.trim().isNotEmpty) {
                            title = desc.trim();
                          } else {
                            title = isCredit ? 'Coins Added' : 'Coins Deducted';
                          }

                          return _buildActivityCard(
                            title: title,
                            amount: formattedAmount,
                            date: dateStr,
                            isCredit: isCredit,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyActivity() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: darkNavy.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your wallet reward distributions and product purchase deductions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryGray,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String amount,
    required String date,
    required bool isCredit,
  }) {
    final statusColor = isCredit ? emeraldSuccess : const Color(0xFF92400E);
    final statusBg = isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: darkNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.shopping_bag_outlined,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: darkNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: const TextStyle(
                      color: secondaryGray,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Amount
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              color: isCredit ? emeraldSuccess : darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
