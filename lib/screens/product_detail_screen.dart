import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'order_history_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  bool _isRequested = false;
  bool _isBuying = false;
  List<dynamic> _relatedProducts = [];
  bool _isLoadingRelated = true;
  int _quantity = 1;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fetchRelatedProducts();

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchRelatedProducts() async {
    try {
      final products = await context.read<ApiService>().getProducts();
      if (mounted) {
        setState(() {
          _relatedProducts = products.where((p) => p['_id'] != widget.product['_id']).take(6).toList();
          _isLoadingRelated = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    final totalCoins = widget.product['priceInCoins'] * _quantity;
    return await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              title: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Complete your purchase for:'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        Text(widget.product['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('$_quantity units', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$totalCoins COINS', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue, fontSize: 18)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }

  Future<void> _buyProduct() async {
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isBuying = true;
    });

    try {
      await context.read<ApiService>().buyProduct(
        widget.product['_id'],
        quantity: _quantity,
      );
      if (mounted) {
        setState(() {
          _isRequested = true;
          _isBuying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Order Placed Successfully!'),
            backgroundColor: Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBuying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasImage = product['images'] != null && (product['images'] as List).isNotEmpty;
    final accentColor = const Color(0xFF6366F1);
    final maxStock = product['stock'] ?? 0;
    final inStock = maxStock > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 450,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: Hero(
                      tag: 'product-${product['_id']}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          hasImage
                              ? (product['images'][0].toString().startsWith('data:image')
                                  ? Image.memory(base64Decode(product['images'][0].toString().split(',')[1]), fit: BoxFit.cover)
                                  : Image.network(product['images'][0], fit: BoxFit.cover))
                              : Container(color: Colors.grey.shade100, child: const Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey)),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.white.withOpacity(0.1), Colors.white],
                                  stops: const [0.7, 0.9, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(product['category']?.toUpperCase() ?? 'GENERAL', style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                            const Spacer(),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            const Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product['name'],
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black, height: 1.1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Price', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                Text(
                                  '${product['priceInCoins'] * _quantity}',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: accentColor),
                                ),
                                const Text('COINS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        Text(
                          product['description'] ?? 'No description available.',
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                        ),

                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Quantity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('In Stock: $maxStock', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  IconButton(icon: const Icon(Icons.remove), onPressed: _isBuying ? null : () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1)),
                                  SizedBox(width: 30, child: Center(child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
                                  IconButton(icon: const Icon(Icons.add), onPressed: _isBuying ? null : () => setState(() => _quantity = _quantity < maxStock ? _quantity + 1 : maxStock)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withOpacity(0), Colors.white],
                    stops: const [0, 0.4],
                  ),
                ),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F00),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF9F00).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: InkWell(
                    onTap: _isBuying
                      ? null
                      : (_isRequested 
                        ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderHistoryScreen()))
                        : (inStock ? _buyProduct : null)),
                    child: Center(
                      child: _isBuying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            _isRequested ? 'VIEW HISTORY' : (inStock ? 'CONFIRM PURCHASE' : 'OUT OF STOCK'),
                            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
