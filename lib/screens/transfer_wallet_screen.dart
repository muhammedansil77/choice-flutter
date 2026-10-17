import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TransferWalletScreen extends StatefulWidget {
  const TransferWalletScreen({super.key});

  @override
  State<TransferWalletScreen> createState() => _TransferWalletScreenState();
}

class _TransferWalletScreenState extends State<TransferWalletScreen> {
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int _availablePoints = 0;
  List<dynamic> _withdrawals = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Choice Electricals Brand Design System Tokens
  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color goldAccent = AppColors.secondaryTeal;
  static const Color textDark = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color emeraldSuccess = AppColors.successGreen;
  static const Color lightTeal = AppColors.lightTeal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getMyWallet(forceRefresh: true),
        api.getMyWithdrawals(),
      ]);

      if (mounted) {
        final wallet = results[0] as Map<String, dynamic>;
        setState(() {
          _availablePoints = (wallet['coinBalance'] ?? wallet['balance'] ?? 0) as int;
          _withdrawals = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRequest() async {
    final text = _pointsController.text.trim();
    final points = int.tryParse(text);

    if (points == null || points <= 0) {
      _showSnackbar('Please enter a valid points amount to withdraw.', isError: true);
      return;
    }

    if (points < 50) {
      _showSnackbar('Minimum withdrawal is 50 points (₹50).', isError: true);
      return;
    }

    if (points > _availablePoints) {
      _showSnackbar('You only have $_availablePoints points available.', isError: true);
      return;
    }

    // Confirmation dialog before deducting points
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.store_rounded, color: secondaryTeal, size: 26),
            SizedBox(width: 10),
            Text('Confirm Cash Pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textDark)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are requesting ₹$points Real Cash for $points Points.',
              style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                '• Points will be reserved immediately.\n• Visit Choice Electricals shop counter to collect your physical cash.',
                style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Confirm Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final api = context.read<ApiService>();
      final res = await api.requestCashWithdrawal(points, notes: _notesController.text.trim());

      _pointsController.clear();
      _notesController.clear();

      if (mounted) {
        _showSnackbar(res['message'] ?? 'Payout request submitted successfully!');
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFFDC2626) : emeraldSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildQuickChip(int pts) {
    final isSelected = _pointsController.text == pts.toString();
    return InkWell(
      onTap: () {
        if (pts <= _availablePoints) {
          setState(() {
            _pointsController.text = pts.toString();
          });
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? secondaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryTeal : (pts > _availablePoints ? const Color(0xFFE2E8F0) : cardBorder),
            width: 1.4,
          ),
        ),
        child: Text(
          '$pts Pts (₹$pts)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? Colors.white
                : (pts > _availablePoints ? const Color(0xFF94A3B8) : textDark),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().currentUser;
    final memberId = user != null ? 'AE${(user['id'] ?? '').toString().substring(0, 8).toUpperCase()}' : 'AE000000';

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: const Text(
          'Transfer Wallet Amount',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            fontSize: 18,
            color: primaryNavy,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryNavy),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: secondaryTeal))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: secondaryTeal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. EXECUTIVE BALANCE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryNavy,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'AVAILABLE POINTS',
                                style: TextStyle(
                                  color: goldAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Member: $memberId',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_availablePoints',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Points',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Real Cash Value', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
                                  Text(
                                    '₹$_availablePoints.00',
                                    style: const TextStyle(
                                      color: emeraldSuccess,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 14, color: goldAccent),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '1 Point = ₹1.00 Real Cash · Collect instantly at shop counter',
                                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. CASH WITHDRAWAL REQUEST BOX
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Cash Payout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Enter how many points you want to convert to real cash:',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                          const SizedBox(height: 14),

                          // Quick Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildQuickChip(50),
                              _buildQuickChip(100),
                              _buildQuickChip(200),
                              if (_availablePoints > 0)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pointsController.text = _availablePoints.toString();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: lightTeal,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: secondaryTeal, width: 1.2),
                                    ),
                                    child: const Text(
                                      'All Points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: secondaryTeal,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Text Input Field
                          TextField(
                            controller: _pointsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Points to Withdraw',
                              hintText: 'e.g. 100',
                              prefixIcon: const Icon(Icons.toll_rounded, color: secondaryTeal),
                              suffixText: 'Pts',
                              suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: secondaryTeal),
                              filled: true,
                              fillColor: bgSurface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: secondaryTeal, width: 1.6),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Shop Collection Guide
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.storefront_rounded, size: 20, color: textDark),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'How it works: Once submitted, show your Member ID to Choice Electricals shop counter. The staff will verify and hand you real cash instantly.',
                                    style: TextStyle(fontSize: 12, color: textDark, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryNavy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Request Cash Payout',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 3. WITHDRAWAL HISTORY
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cash Payout Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        if (_withdrawals.isNotEmpty)
                          Text(
                            '${_withdrawals.length} total',
                            style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_withdrawals.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 8),
                            Text(
                              'No payout requests yet',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textDark),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Submit a request above to collect cash at Choice Electricals store.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _withdrawals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _withdrawals[index];
                          final status = (item['status'] ?? 'pending').toString().toLowerCase();
                          final points = item['points'] ?? item['cashAmount'] ?? 0;
                          final cash = item['cashAmount'] ?? points;
                          final dateStr = item['createdAt'] != null
                              ? DateTime.tryParse(item['createdAt'].toString())?.toLocal().toString().substring(0, 16) ?? ''
                              : '';
                          final id = (item['id'] ?? '').toString();

                          Color statusColor;
                          String statusText;
                          IconData statusIcon;

                          if (status == 'approved') {
                            statusColor = emeraldSuccess;
                            statusText = 'Paid & Collected';
                            statusIcon = Icons.check_circle_rounded;
                          } else if (status == 'rejected') {
                            statusColor = const Color(0xFFDC2626);
                            statusText = 'Rejected / Refunded';
                            statusIcon = Icons.cancel_rounded;
                          } else {
                            statusColor = const Color(0xFFD97706);
                            statusText = 'Pending Store Pickup';
                            statusIcon = Icons.pending_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Icon(statusIcon, color: statusColor, size: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹$cash Cash ($points Pts)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ID: #${id.length > 8 ? id.substring(0, 8).toUpperCase() : id} · $dateStr',
                                        style: const TextStyle(fontSize: 11, color: textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
