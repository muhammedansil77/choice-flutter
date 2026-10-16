import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  // Choice Electricals Brand Design System Tokens
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldAccentDark = Color(0xFFC59A27);
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color secondaryGray = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color emeraldSuccess = Color(0xFF10B981);
  static const Color roseRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await context.read<ApiService>().getMyOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: roseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildProductThumbnail(dynamic imgData) {
    if (imgData == null) {
      return const Center(
        child: Icon(Icons.electrical_services_rounded, size: 28, color: Color(0xFFCBD5E1)),
      );
    }
    final str = imgData.toString().trim();
    if (str.isEmpty) {
      return const Center(
        child: Icon(Icons.electrical_services_rounded, size: 28, color: Color(0xFFCBD5E1)),
      );
    }

    if (str.startsWith('data:image')) {
      try {
        final base64String = str.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_outlined, size: 26, color: Color(0xFFCBD5E1)),
        );
      }
    }

    if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 26, color: Color(0xFFCBD5E1)),
        ),
      );
    }

    return Image.asset(
      str,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.electrical_services_rounded, size: 28, color: Color(0xFFCBD5E1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: const Text(
          'Purchase History',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchOrders,
            icon: const Icon(Icons.refresh_rounded, size: 22, color: goldAccent),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: goldAccentDark),
            )
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: goldAccentDark,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final product = order['product'];
                      final date = DateTime.tryParse(order['createdAt'].toString())?.toLocal() ?? DateTime.now();
                      final status = (order['status'] ?? 'pending').toString().toLowerCase();

                      return _buildOrderCard(order, product, date, status);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(26),
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
                Icons.receipt_long_outlined,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No Orders Found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You haven\'t made any purchases yet. Your history will appear here once you redeem an order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryGray,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _fetchOrders,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: darkNavy),
                label: const Text(
                  'Refresh History',
                  style: TextStyle(
                    color: darkNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, dynamic product, DateTime date, String status) {
    Color statusBg;
    Color statusText;
    Color statusDot;
    String statusLabel;

    switch (status) {
      case 'approved':
        statusBg = const Color(0xFFECFDF5);
        statusText = const Color(0xFF065F46);
        statusDot = emeraldSuccess;
        statusLabel = 'APPROVED';
        break;
      case 'rejected':
        statusBg = const Color(0xFFFEF2F2);
        statusText = const Color(0xFF991B1B);
        statusDot = roseRed;
        statusLabel = 'REJECTED';
        break;
      default:
        statusBg = const Color(0xFFFFFBEB);
        statusText = const Color(0xFF92400E);
        statusDot = goldAccentDark;
        statusLabel = 'PENDING';
    }

    final images = (product != null &&
            product['images'] is List &&
            (product['images'] as List).isNotEmpty)
        ? (product['images'] as List)
        : [];
    final dynamic firstImage = images.isNotEmpty ? images.first : null;
    final productName = product != null ? (product['name'] ?? 'Product') : 'Product';
    final quantity = order['quantity'] ?? 1;
    final coinsSpent = order['coinsSpent'] ?? 0;
    final orderId = (order['id'] ?? order['_id'] ?? '').toString();
    final orderRef = orderId.length >= 6
        ? '#CE-${orderId.substring(orderId.length - 6).toUpperCase()}'
        : '#CE-ORDER';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderSubtle),
        boxShadow: [
          BoxShadow(
            color: darkNavy.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Reference + Date + Status Pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderRef,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: darkNavy,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy · hh:mm a').format(date),
                      style: const TextStyle(
                        color: secondaryGray,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusDot.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusText,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Product Overview Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _buildProductThumbnail(firstImage),
                  ),
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
                          fontSize: 14.5,
                          color: darkNavy,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantity: $quantity ${quantity == 1 ? 'unit' : 'units'}',
                        style: const TextStyle(
                          color: secondaryGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Card Footer: Coins Redeemed Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Coins Redeemed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: secondaryGray,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: goldLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: goldAccent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Center(
                        child: Text('🪙', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$coinsSpent',
                      style: const TextStyle(
                        color: darkNavy,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Coins',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: goldAccentDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
