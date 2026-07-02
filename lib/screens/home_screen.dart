import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _HomeContent(),
    const OrderHistoryScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF1E3A8A);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'STORE'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'ORDERS'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'WALLET'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getProducts(forceRefresh: true),
        api.getCategories(forceRefresh: true),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0];
          _categories = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedCategory == 'All') return _products;
    return _products.where((p) => p['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().currentUser;
    final userName = user?['name'] ?? 'Guest';

    const Color primaryBlue = Color(0xFF1E3A8A);
    const Color accentBlue = Color(0xFF3B82F6);
    const Color luxuryGold = Color(0xFFEAB308);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accentBlue))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: accentBlue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
              SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                stretch: true,
                backgroundColor: primaryBlue,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Shop Background Image
                      Image.asset(
                        'assets/images/shop_bg.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Premium Brand Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryBlue.withOpacity(0.92),
                              primaryBlue.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),
                      // Ultra-premium glassmorphism blur effect
                      ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // Lightning bolt accent
                      Positioned(
                        right: -30, 
                        top: -20, 
                        child: Icon(
                          Icons.electric_bolt_rounded, 
                          size: 180, 
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      // Brand texts and welcome banner
                      Positioned(
                        left: 24, 
                        bottom: 40, 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello, $userName 👋', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white, 
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/logo.png', 
                                      height: 36, 
                                      width: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Choice\nElectricals', 
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: 32, 
                                    fontWeight: FontWeight.w900, 
                                    height: 1.0,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TRUSTED QUALITY • SINCE 2024', 
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6), 
                                fontSize: 10, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SEARCH BAR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for products...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            icon: Icon(Icons.search_rounded, color: accentBlue),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // CATEGORY FILTER (Better Design)
                      const Text('Filter by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categories.length + 1,
                          itemBuilder: (context, index) {
                            final isAll = index == 0;
                            final catName = isAll ? 'All' : _categories[index - 1]['name'];
                            final isSelected = _selectedCategory == catName;

                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = catName),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryBlue : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: isSelected ? primaryBlue : Colors.grey.shade200),
                                  boxShadow: isSelected ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  catName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$_selectedCategory Products', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          Text('${_filteredProducts.length} items', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 40),
                sliver: _filteredProducts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('No products in this category', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = _filteredProducts[index];
                            final hasImage = product['images'] != null && (product['images'] as List).isNotEmpty;
                            
                            return InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(24),
                                              child: Hero(
                                                tag: 'product-${product['_id']}',
                                                child: hasImage
                                                    ? (product['images'][0].toString().startsWith('data:image')
                                                        ? Image.memory(base64Decode(product['images'][0].toString().split(',')[1]), fit: BoxFit.cover, width: double.infinity)
                                                        : Image.network(product['images'][0], fit: BoxFit.cover, width: double.infinity))
                                                    : Container(color: Colors.blue.shade50, child: const Icon(Icons.electric_bolt_rounded, color: accentBlue, size: 40)),
                                              ),
                                            ),
                                          ),
                                          if (product['status'] == 'blocked')
                                            Positioned.fill(
                                              child: Container(
                                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(28)),
                                                child: const Center(child: Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(product['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.monetization_on_rounded, size: 16, color: luxuryGold),
                                              const SizedBox(width: 4),
                                              Text('${product['priceInCoins']}', style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 18)),
                                              const SizedBox(width: 4),
                                              const Text('Coins', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
    );
  }
}
