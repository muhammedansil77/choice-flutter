import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'order_history_screen.dart';
import 'order_success_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  bool _isRequested = false;
  bool _isBuying = false;
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  int _quantity = 1;
  int _currentImageIndex = 0;
  int? _liveBalance;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _favoriteController;
  late Animation<double> _favoriteScaleAnim;

  // Choice Electricals Brand Design System Tokens
  static const Color darkNavy = AppColors.textPrimary;
  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color secondaryGray = AppColors.textSecondary;
  static const Color borderSubtle = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color emeraldSuccess = AppColors.successGreen;
  static const Color roseRed = Color(0xFFEF4444);
  static const Color lightTeal = AppColors.lightTeal;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();

    _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _favoriteScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailableBalance();
    });
  }

  Future<void> _fetchAvailableBalance() async {
    try {
      final api = context.read<ApiService>();
      final wallet = await api.getMyWallet(forceRefresh: true);
      if (mounted) {
        setState(() {
          _liveBalance = (wallet['coinBalance'] ?? wallet['balance'] as num?)?.toInt();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _favoriteController.forward(from: 0.0);
  }

  Future<bool> _showConfirmationDialog() async {
    final unitPrice = (widget.product['priceInCoins'] as num?)?.toInt() ?? 0;
    final totalCoins = unitPrice * _quantity;
    final images = (widget.product['images'] is List &&
            (widget.product['images'] as List).isNotEmpty)
        ? (widget.product['images'] as List)
        : [];
    final dynamic firstImage = images.isNotEmpty ? images.first : null;

    final user = context.read<ApiService>().currentUser;
    final int userCoinBalance = _liveBalance ?? (user?['coinBalance'] as num?)?.toInt() ?? 0;

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confirm Order',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: darkNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx, false),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: secondaryGray),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review your purchase details below:',
                  style: TextStyle(fontSize: 13, color: secondaryGray),
                ),

                const SizedBox(height: 16),

                // Product Card with Image (Clean standard layout, no awkward category tags)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Product Image Thumbnail
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderSubtle),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: firstImage != null
                              ? _buildImageItem(firstImage)
                              : const Center(
                                  child: Icon(Icons.electrical_services_rounded,
                                      size: 28, color: Color(0xFFCBD5E1)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product Title & Unit details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product['name'] ?? '',
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
                              '$_quantity ${_quantity == 1 ? 'unit' : 'units'} · $unitPrice coins/unit',
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

                const SizedBox(height: 16),

                // Order breakdown rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quantity', style: TextStyle(fontSize: 13, color: secondaryGray)),
                    Text('$_quantity',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkNavy)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unit Price', style: TextStyle(fontSize: 13, color: secondaryGray)),
                    Text('$unitPrice Coins',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkNavy)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Available Balance', style: TextStyle(fontSize: 13, color: secondaryGray)),
                    Text(
                      '$userCoinBalance Coins',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: (userCoinBalance >= totalCoins)
                            ? emeraldSuccess
                            : roseRed,
                      ),
                    ),
                  ],
                ),
                if (userCoinBalance >= totalCoins) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Balance', style: TextStyle(fontSize: 13, color: secondaryGray)),
                      Text(
                        '${userCoinBalance - totalCoins} Coins',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: darkNavy,
                        ),
                      ),
                    ],
                  ),
                ],
                if (userCoinBalance < totalCoins) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: roseRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Insufficient balance. Need ${totalCoins - userCoinBalance} more coins.',
                            style: const TextStyle(
                              color: roseRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: borderSubtle),
                ),

                // Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: darkNavy,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: lightTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: secondaryTeal.withValues(alpha: 0.4)),
                          ),
                          child: const Center(
                            child: Text('🪙', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$totalCoins',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: darkNavy,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Coins',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: secondaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: secondaryGray, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryNavy,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryNavy.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(ctx, true),
                              borderRadius: BorderRadius.circular(14),
                              child: const Center(
                                child: Text(
                                  'Confirm Order',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<void> _buyProduct() async {
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;
    if (!mounted) return;

    setState(() {
      _isBuying = true;
    });

    try {
      final orderRes = await context.read<ApiService>().buyProduct(
            widget.product['_id'],
            quantity: _quantity,
          );
      if (mounted) {
        setState(() {
          _isRequested = true;
          _isBuying = false;
        });

        final unitPrice = (widget.product['priceInCoins'] as num?)?.toInt() ?? 0;
        final totalCoins = unitPrice * _quantity;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessScreen(
              product: widget.product,
              quantity: _quantity,
              totalCoins: totalCoins,
              orderData: orderRes?['order'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: roseRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildImageItem(dynamic imgUrl) {
    final str = imgUrl.toString();
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
          child: Icon(Icons.broken_image_outlined, size: 64, color: Color(0xFFCBD5E1)),
        );
      }
    } else if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined, size: 64, color: Color(0xFFCBD5E1)),
        ),
      );
    } else {
      return const Center(
        child: Icon(Icons.electrical_services_rounded, size: 64, color: Color(0xFFCBD5E1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = (product['images'] is List && (product['images'] as List).isNotEmpty)
        ? (product['images'] as List)
        : [];
    final maxStock = (product['stock'] as num?)?.toInt() ?? 0;
    final inStock = maxStock > 0;
    final unitPrice = (product['priceInCoins'] as num?)?.toInt() ?? 0;
    final totalCoins = unitPrice * _quantity;

    final user = context.watch<ApiService>().currentUser;
    final int userCoinBalance = _liveBalance ?? (user?['coinBalance'] as num?)?.toInt() ?? 0;

    final descriptionText =
        product['description']?.toString().trim() ?? 'Genuine high quality electrical appliance from Choice Electricals.';

    final screenWidth = MediaQuery.of(context).size.width;
    final topSafeArea = MediaQuery.of(context).padding.top;
    final heroHeight = (screenWidth * 1.02).clamp(350.0, 450.0);

    return Scaffold(
      backgroundColor: bgSurface,
      body: Stack(
        children: [
          // MAIN SCROLLABLE CONTENT
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. FULL WIDTH EDGE-TO-EDGE HERO IMAGE CONTAINER
                    Container(
                      width: double.infinity,
                      height: heroHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                        border: const Border(
                          bottom: BorderSide(color: borderSubtle, width: 1.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: darkNavy.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(28),
                        ),
                        child: Stack(
                          children: [
                            // Product image
                            Positioned.fill(
                              child: images.isNotEmpty
                                  ? PageView.builder(
                                      itemCount: images.length,
                                      onPageChanged: (idx) =>
                                          setState(() => _currentImageIndex = idx),
                                      itemBuilder: (context, idx) {
                                        return _buildImageItem(images[idx]);
                                      },
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.electrical_services_rounded,
                                        size: 80,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                            ),

                            // Overlay Header Buttons (Back & Favorite)
                            Positioned(
                              top: (topSafeArea > 0 ? topSafeArea : 12) + 6,
                              left: 16,
                              right: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back Button
                                  InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.94),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: borderSubtle),
                                        boxShadow: [
                                          BoxShadow(
                                            color: darkNavy.withValues(alpha: 0.08),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: darkNavy,
                                          size: 17,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Favorite Button
                                  ScaleTransition(
                                    scale: _favoriteScaleAnim,
                                    child: InkWell(
                                      onTap: _toggleFavorite,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.94),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: borderSubtle),
                                          boxShadow: [
                                            BoxShadow(
                                              color: darkNavy.withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: _isFavorite
                                                ? roseRed
                                                : darkNavy,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Pagination Dots
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (idx) {
                                    final isSelected = idx == _currentImageIndex;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: isSelected ? 18 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? secondaryTeal
                                            : const Color(0xFFCBD5E1),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. PRODUCT DETAILS BODY
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // BRAND TRUST TAG & RATING ROW (Standardized without awkward category pill)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lightTeal,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: secondaryTeal.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded, size: 13, color: secondaryTeal),
                                    SizedBox(width: 5),
                                    Text(
                                      'CHOICE ELECTRICALS',
                                      style: TextStyle(
                                        color: darkNavy,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF59E0B),
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.8 (Verified)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                        color: darkNavy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // PRODUCT TITLE
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: darkNavy,
                              letterSpacing: -0.4,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 3. COMPACT LUXURY PRICE & BALANCE CARD
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: darkNavy.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left: Price
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'PRICE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: secondaryGray,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: lightTeal,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: secondaryTeal.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Center(
                                            child: Text('🪙', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$unitPrice',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: darkNavy,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Coins',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: secondaryTeal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Right: Available Wallet balance status
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 13,
                                          color: secondaryGray,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Available Balance',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: secondaryGray,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (userCoinBalance >= totalCoins)
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: (userCoinBalance >= totalCoins)
                                              ? const Color(0xFFA7F3D0)
                                              : const Color(0xFFFECACA),
                                        ),
                                      ),
                                      child: Text(
                                        '$userCoinBalance Coins',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: (userCoinBalance >= totalCoins)
                                              ? emeraldSuccess
                                              : roseRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // 4. TRUST BADGES ROW (Matches Store theme)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildDetailTrustItem(Icons.verified_user_outlined, '100% Genuine'),
                                Container(width: 1, height: 16, color: borderSubtle),
                                _buildDetailTrustItem(Icons.local_shipping_outlined, 'Fast Pickup'),
                                Container(width: 1, height: 16, color: borderSubtle),
                                _buildDetailTrustItem(Icons.shield_outlined, 'Store Warranty'),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 5. DESCRIPTION (Expandable)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 200),
                                  crossFadeState: _isDescriptionExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  firstChild: Text(
                                    descriptionText,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: secondaryGray,
                                      height: 1.5,
                                    ),
                                  ),
                                  secondChild: Text(
                                    descriptionText,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: secondaryGray,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                if (descriptionText.length > 90) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () => setState(() =>
                                        _isDescriptionExpanded = !_isDescriptionExpanded),
                                    child: Text(
                                      _isDescriptionExpanded
                                          ? 'Read less ←'
                                          : 'Read more →',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: secondaryTeal,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 6. QUANTITY & STOCK SELECTOR
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Quantity Selector Controls
                                    Container(
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: borderSubtle, width: 1.2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: (_quantity > 1 && !_isBuying)
                                                ? () => setState(() => _quantity--)
                                                : null,
                                            borderRadius: const BorderRadius.horizontal(
                                                left: Radius.circular(13)),
                                            child: SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: Center(
                                                child: Icon(
                                                  Icons.remove_rounded,
                                                  size: 18,
                                                  color: (_quantity > 1 && !_isBuying)
                                                      ? darkNavy
                                                      : const Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            constraints: const BoxConstraints(minWidth: 42),
                                            alignment: Alignment.center,
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 180),
                                              transitionBuilder: (child, anim) =>
                                                  ScaleTransition(scale: anim, child: child),
                                              child: Text(
                                                '$_quantity',
                                                key: ValueKey<int>(_quantity),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: darkNavy,
                                                ),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: (_quantity < maxStock && !_isBuying)
                                                ? () => setState(() => _quantity++)
                                                : null,
                                            borderRadius: const BorderRadius.horizontal(
                                                right: Radius.circular(13)),
                                            child: SizedBox(
                                              width: 44,
                                              height: 44,
                                              child: Center(
                                                child: Icon(
                                                  Icons.add_rounded,
                                                  size: 18,
                                                  color: (_quantity < maxStock && !_isBuying)
                                                      ? darkNavy
                                                      : const Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stock Indicator Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: inStock
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: inStock ? emeraldSuccess : roseRed,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            inStock
                                                ? 'In Stock ($maxStock)'
                                                : 'Out of Stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: inStock
                                                  ? const Color(0xFF065F46)
                                                  : const Color(0xFF991B1B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7. STICKY PURCHASE BAR (Fixed at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: borderSubtle, width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: darkNavy.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Left: Total Price + Available Balance
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: secondaryGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$totalCoins',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '🪙 Coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: secondaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 11,
                                color: (userCoinBalance >= totalCoins) ? secondaryGray : roseRed,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Bal: $userCoinBalance Coins',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: (userCoinBalance >= totalCoins) ? secondaryGray : roseRed,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Action Button
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: (inStock && !_isRequested)
                                ? const LinearGradient(
                                    colors: [primaryNavy, Color(0xFF0F2B48)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _isRequested
                                ? primaryNavy
                                : (!inStock ? const Color(0xFFE2E8F0) : null),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: (inStock && !_isRequested)
                                ? [
                                    BoxShadow(
                                      color: primaryNavy.withValues(alpha: 0.28),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isBuying
                                  ? null
                                  : (_isRequested
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OrderHistoryScreen(),
                                            ),
                                          )
                                      : (inStock ? _buyProduct : null)),
                              child: Center(
                                child: _isBuying
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isRequested
                                            ? 'VIEW ORDERS →'
                                            : (inStock
                                                ? 'CONFIRM PURCHASE'
                                                : 'OUT OF STOCK'),
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          color: _isRequested
                                              ? Colors.white
                                              : (inStock
                                                  ? Colors.white
                                                  : const Color(0xFF94A3B8)),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTrustItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: secondaryTeal),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: darkNavy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
