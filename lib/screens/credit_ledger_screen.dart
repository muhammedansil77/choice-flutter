import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreditLedgerScreen extends StatefulWidget {
  const CreditLedgerScreen({super.key});

  @override
  State<CreditLedgerScreen> createState() => _CreditLedgerScreenState();
}

class _CreditLedgerScreenState extends State<CreditLedgerScreen> {
  bool _isLoading = true;
  String _selectedCategory = 'all'; // 'all', 'electronic', 'hardware'
  final String _selectedStatus = 'all'; // 'all', 'unpaid', 'partial', 'settled'

  Map<String, dynamic> _summary = {
    'totalBilled': 0.0,
    'totalReceived': 0.0,
    'totalReturned': 0.0,
    'totalOutstanding': 0.0,
    'totalInvoices': 0,
  };
  List<dynamic> _entries = [];

  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color bgSurface = AppColors.background;
  static const Color cardBorder = AppColors.border;
  static const Color successGreen = AppColors.successGreen;

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  Future<void> _fetchLedger({bool forceRefresh = false}) async {
    if (forceRefresh || _entries.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final api = context.read<ApiService>();
      final res = await api.getMyCreditLedger(
        category: _selectedCategory,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _summary = res['summary'] ?? _summary;
          _entries = res['entries'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final dt = DateTime.parse(dateVal.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final num val = num.tryParse(amount.toString()) ?? 0;
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return formatter.format(val);
  }

  Widget _buildSummaryCard() {
    final outstanding = num.tryParse((_summary['totalOutstanding'] ?? 0).toString()) ?? 0;
    final billed = num.tryParse((_summary['totalBilled'] ?? 0).toString()) ?? 0;
    final received = num.tryParse((_summary['totalReceived'] ?? 0).toString()) ?? 0;
    final returned = num.tryParse((_summary['totalReturned'] ?? 0).toString()) ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Label + Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TOTAL OUTSTANDING DUE',
                    style: TextStyle(
                      color: Color(0xFFB0C4DE),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: outstanding > 0
                      ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                      : successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: outstanding > 0 ? const Color(0xFFEF4444) : successGreen,
                    width: 1,
                  ),
                ),
                child: Text(
                  outstanding > 0 ? 'Payment Due' : 'All Settled',
                  style: TextStyle(
                    color: outstanding > 0 ? const Color(0xFFFF8080) : const Color(0xFF4ADE80),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Big Outstanding Amount
          Text(
            _formatCurrency(outstanding),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF284870), height: 1),
          const SizedBox(height: 14),

          // 3-Metric Breakdown Row
          Row(
            children: [
              _buildMicroMetric('Total Billed', _formatCurrency(billed), const Color(0xFF93C5FD)),
              Container(width: 1, height: 32, color: const Color(0xFF284870)),
              _buildMicroMetric('Paid / Received', _formatCurrency(received), const Color(0xFF86EFAC)),
              Container(width: 1, height: 32, color: const Color(0xFF284870)),
              _buildMicroMetric('Goods Return', _formatCurrency(returned), const Color(0xFFD8B4FE)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetric(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children: [
        _buildCategoryChip('All Invoices', 'all'),
        const SizedBox(width: 8),
        _buildCategoryChip('⚡ Electronic', 'electronic'),
        const SizedBox(width: 8),
        _buildCategoryChip('🔧 Hardware', 'hardware'),
      ],
    );
  }

  Widget _buildCategoryChip(String label, String categoryKey) {
    final isSelected = _selectedCategory == categoryKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedCategory == categoryKey) return;
          setState(() {
            _selectedCategory = categoryKey;
          });
          _fetchLedger();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? secondaryTeal : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? secondaryTeal : cardBorder,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: secondaryTeal.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? Colors.white : textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(dynamic entry) {
    final invoiceNumber = (entry['invoiceNumber'] ?? 'N/A').toString();
    final dateStr = _formatDate(entry['date']);
    final category = (entry['category'] ?? 'electronic').toString().toLowerCase();
    final billAmount = num.tryParse((entry['billAmount'] ?? 0).toString()) ?? 0;
    final receivedAmount = num.tryParse((entry['receivedAmount'] ?? 0).toString()) ?? 0;
    final returnAmount = num.tryParse((entry['returnAmount'] ?? 0).toString()) ?? 0;
    final balanceAmount = num.tryParse((entry['balanceAmount'] ?? 0).toString()) ?? 0;
    final status = (entry['status'] ?? 'unpaid').toString().toLowerCase();
    final narration = entry['narration']?.toString();

    // Status Pill
    Color statusBg;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'settled' || balanceAmount <= 0) {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
      statusText = 'Settled';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'partial') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFB45309);
      statusText = 'Partial';
      statusIcon = Icons.schedule_rounded;
    } else {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFB91C1C);
      statusText = 'Unpaid';
      statusIcon = Icons.error_outline_rounded;
    }

    final isHardware = category == 'hardware';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Invoice # + Category Badge + Date
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHardware
                            ? const Color(0xFFFFEDD5)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isHardware ? Icons.build_rounded : Icons.bolt_rounded,
                            size: 13,
                            color: isHardware ? const Color(0xFFC2410C) : const Color(0xFF1D4ED8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isHardware ? 'Hardware' : 'Electronic',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isHardware ? const Color(0xFFC2410C) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      invoiceNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: cardBorder),

          // Amounts Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bill Amount', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(billAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Received', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(receivedAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Return', style: TextStyle(fontSize: 11, color: textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(returnAmount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Bar: Balance Due & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
              border: Border(top: BorderSide(color: cardBorder, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Balance Due: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(balanceAmount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: balanceAmount > 0 ? const Color(0xFFDC2626) : successGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (narration != null && narration.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 13,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          narration.trim(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shop Credit Ledger',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: primaryNavy,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryNavy, size: 22),
            onPressed: () => _fetchLedger(forceRefresh: true),
            tooltip: 'Refresh Ledger',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchLedger(forceRefresh: true),
        color: secondaryTeal,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: secondaryTeal))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // 1. Summary Card
                  _buildSummaryCard(),

                  const SizedBox(height: 16),

                  // 2. Category Filter Tabs
                  _buildCategoryTabs(),

                  const SizedBox(height: 16),

                  // 3. Entries Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Invoice Records (${_entries.length})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      if (_selectedCategory != 'all')
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = 'all');
                            _fetchLedger();
                          },
                          child: const Text(
                            'Clear Filter',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: secondaryTeal,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 4. Entries List or Empty State
                  if (_entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondaryTeal.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 40,
                              color: secondaryTeal,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Credit Records Found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your credit bills, received payments, and returned goods will appear here once recorded at Choice Electricals store.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._entries.map((e) => _buildEntryCard(e)),
                ],
              ),
      ),
    );
  }
}
