import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'order_history_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int quantity;
  final int totalCoins;
  final Map<String, dynamic>? orderData;

  const OrderSuccessScreen({
    super.key,
    required this.product,
    required this.quantity,
    required this.totalCoins,
    this.orderData,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Choice Electricals Brand Luxury Palette
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldAccentDark = Color(0xFFC59A27);
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color secondaryGray = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color bgSurface = Color(0xFFF8FAFC);
  static const Color emeraldSuccess = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getOrderRef() {
    if (widget.orderData != null) {
      final rawId = widget.orderData!['_id'] ?? widget.orderData!['id'];
      if (rawId != null && rawId.toString().length >= 6) {
        final str = rawId.toString();
        return '#CE-${str.substring(str.length - 6).toUpperCase()}';
      }
    }
    // Fallback pseudo-ref based on epoch timestamp
    final hash = DateTime.now().millisecondsSinceEpoch.toString();
    return '#CE-${hash.substring(hash.length - 6)}';
  }

  Widget _buildProductThumbnail(dynamic imgData) {
    if (imgData == null) {
      return const Center(
        child: Icon(Icons.electrical_services_rounded, size: 28, color: Color(0xFF94A3B8)),
      );
    }

    final str = imgData.toString();
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
        child: Icon(Icons.electrical_services_rounded, size: 28, color: Color(0xFF94A3B8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = (widget.product['images'] is List &&
            (widget.product['images'] as List).isNotEmpty)
        ? (widget.product['images'] as List)
        : [];
    final dynamic firstImage = images.isNotEmpty ? images.first : null;
    final categoryName = widget.product['category']?.toString();
    final unitPrice = (widget.product['priceInCoins'] as num?)?.toInt() ?? 0;
    final orderRef = _getOrderRef();
    final orderTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: goldLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: goldAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.verified_rounded, size: 16, color: goldAccentDark),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CHOICE ELECTRICALS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: darkNavy,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderSubtle),
                        boxShadow: [
                          BoxShadow(
                            color: darkNavy.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: secondaryGray),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Celebratory Animated Badge
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ambient pulse glow ring
                          Container(
                            width: 108,
                            height: 108,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: goldAccent.withValues(alpha: 0.12),
                            ),
                          ),
                          // Mid decorative border ring
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: emeraldSuccess.withValues(alpha: 0.12),
                              border: Border.all(
                                color: goldAccent.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Center Badge with gradient
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: emeraldSuccess.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          // Decorative gold star sparkles
                          Positioned(
                            top: 4,
                            right: 12,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: goldAccentDark.withValues(alpha: 0.85),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 10,
                            child: Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: goldAccent.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Heading and Subtitle
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'ORDER CONFIRMED!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: darkNavy,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your reward order has been submitted successfully.\nChoice Electricals is processing your request.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryGray,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Luxury Receipt Card (The Golden Ticket)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderSubtle),
                            boxShadow: [
                              BoxShadow(
                                color: darkNavy.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ticket Header: Order Ref & Status
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'ORDER REFERENCE',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: secondaryGray,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          orderRef,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: darkNavy,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: goldAccentDark.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: goldAccentDark,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'PENDING VERIFICATION',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF92400E),
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Ticket Perforation (Notches on both sides + Dashed Line)
                              Row(
                                children: [
                                  // Left semi-circle notch
                                  Transform.translate(
                                    offset: const Offset(-8, 0),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: bgSurface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderSubtle),
                                      ),
                                    ),
                                  ),
                                  // Dashed Divider line
                                  Expanded(
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(color: const Color(0xFFCBD5E1)),
                                      size: const Size(double.infinity, 1),
                                    ),
                                  ),
                                  // Right semi-circle notch
                                  Transform.translate(
                                    offset: const Offset(8, 0),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: bgSurface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderSubtle),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Ticket Body: Product info
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Item Card
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Thumbnail
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: borderSubtle),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(13),
                                            child: _buildProductThumbnail(firstImage),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        // Product Title & Specs
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (categoryName != null &&
                                                  categoryName.trim().isNotEmpty) ...[
                                                Text(
                                                  categoryName.toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: goldAccentDark,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                              ],
                                              Text(
                                                widget.product['name'] ?? 'Product',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: darkNavy,
                                                  height: 1.25,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${widget.quantity} ${widget.quantity == 1 ? 'unit' : 'units'} × $unitPrice coins',
                                                style: const TextStyle(
                                                  color: secondaryGray,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 16),

                                    // Breakdown Rows
                                    _buildReceiptRow('Date & Time', orderTime),
                                    const SizedBox(height: 10),
                                    _buildReceiptRow('Quantity', '${widget.quantity}'),
                                    const SizedBox(height: 10),
                                    _buildReceiptRow('Unit Price', '$unitPrice Coins'),
                                    const SizedBox(height: 10),
                                    _buildReceiptRow(
                                      'Store Pickup & Service',
                                      'COMPLIMENTARY',
                                      valueColor: emeraldSuccess,
                                      isBoldValue: true,
                                    ),

                                    const SizedBox(height: 18),

                                    // Grand Total Banner
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: goldAccent.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'TOTAL REDEEMED',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF92400E),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'From Choice Coins Wallet',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFB45309),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${widget.totalCoins}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: goldAccentDark,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Text(
                                                '🪙 COINS',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: darkNavy,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Choice Electricals Assurance Banner
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderSubtle),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.shield_outlined,
                                            size: 18,
                                            color: goldAccentDark,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Your order has been queued for verification. The Choice Electricals team will prepare your item for fulfillment.',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: secondaryGray,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA Buttons (Sticky Bottom)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: borderSubtle)),
                boxShadow: [
                  BoxShadow(
                    color: darkNavy.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Gold Button: View Order History
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5BE4A), goldAccentDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: goldAccent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OrderHistoryScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, color: darkNavy, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'VIEW ORDER HISTORY',
                                  style: TextStyle(
                                    color: darkNavy,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, color: darkNavy, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Button: Continue Shopping
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.storefront_outlined, size: 18, color: secondaryGray),
                      label: const Text(
                        'CONTINUE SHOPPING',
                        style: TextStyle(
                          color: darkNavy,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBoldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: secondaryGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? darkNavy,
            fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({this.color = const Color(0xFFCBD5E1)});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
