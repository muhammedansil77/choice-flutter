import 'dart:convert';
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

  // Choice Electricals Brand Design System
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color goldAccentDark = Color(0xFFC59A27);
  static const Color slateGray = Color(0xFF94A3B8);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderSubtle, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: darkNavy.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(0, Icons.storefront_rounded, 'STORE'),
                _buildNavItem(1, Icons.receipt_long_rounded, 'ORDERS'),
                _buildNavItem(2, Icons.account_balance_wallet_rounded, 'WALLET'),
                _buildNavItem(3, Icons.person_rounded, 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          splashColor: goldAccentDark.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? darkNavy.withValues(alpha: 0.06)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? darkNavy : slateGray,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isSelected ? goldAccentDark : slateGray,
                ),
              ),
            ],
          ),
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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'featured'; // 'featured', 'price_asc', 'price_desc', 'name_asc'
  bool _isLoading = true;
  final Set<String> _favoriteProductIds = {};

  // Brand Design Tokens
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldAccentDark = Color(0xFFC59A27);
  static const Color goldLight = Color(0xFFFEF3C7);
  static const Color secondaryGray = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final results = await Future.wait([
        api.getProducts(forceRefresh: true),
        api.getCategories(forceRefresh: true),
        api.getMyWallet(forceRefresh: true).catchError((_) => <String, dynamic>{}),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0] as List<dynamic>;
          _categories = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredProducts {
    List<dynamic> list = _products;

    // Filter by Category
    if (_selectedCategory != 'All') {
      list = list.where((p) => p['category'] == _selectedCategory).toList();
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final cat = (p['category'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        return name.contains(q) || cat.contains(q) || desc.contains(q);
      }).toList();
    }

    // Sort products
    if (_sortBy == 'price_asc') {
      list = List.from(list)
        ..sort((a, b) => ((a['priceInCoins'] as num?) ?? 0)
            .compareTo((b['priceInCoins'] as num?) ?? 0));
    } else if (_sortBy == 'price_desc') {
      list = List.from(list)
        ..sort((a, b) => ((b['priceInCoins'] as num?) ?? 0)
            .compareTo((a['priceInCoins'] as num?) ?? 0));
    } else if (_sortBy == 'name_asc') {
      list = List.from(list)
        ..sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    }

    return list;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _searchQuery = '';
      _searchController.clear();
      _sortBy = 'featured';
    });
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_asc':
        return 'Price: Low';
      case 'price_desc':
        return 'Price: High';
      case 'name_asc':
        return 'Name: A-Z';
      default:
        return 'Sort';
    }
  }

  Widget _buildCategoryImage(dynamic img) {
    if (img == null) return const SizedBox.shrink();
    final str = img.toString().trim();
    if (str.isEmpty) return const SizedBox.shrink();

    if (str.startsWith('data:image')) {
      try {
        final base64String = str.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
          fit: BoxFit.contain,
          width: 32,
          height: 32,
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else if (str.startsWith('http://') || str.startsWith('https://')) {
      return Image.network(
        str,
        fit: BoxFit.contain,
        width: 32,
        height: 32,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  IconData _getCategoryFallbackIcon(String catName) {
    final lower = catName.toLowerCase();
    if (lower.contains('fan')) return Icons.toys_outlined;
    if (lower.contains('light') || lower.contains('bulb') || lower.contains('led')) {
      return Icons.lightbulb_outline_rounded;
    }
    if (lower.contains('switch')) return Icons.toggle_on_outlined;
    if (lower.contains('wire') || lower.contains('cable')) return Icons.cable_rounded;
    if (lower.contains('appliance') || lower.contains('home')) return Icons.kitchen_outlined;
    if (lower.contains('car') || lower.contains('motor')) return Icons.electric_car_rounded;
    return Icons.electrical_services_rounded;
  }

  Widget _buildProductThumbnail(dynamic imgData) {
    if (imgData == null) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.electrical_services_rounded, size: 42, color: Color(0xFFCBD5E1)),
        ),
      );
    }

    final str = imgData.toString().trim();
    if (str.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.electrical_services_rounded, size: 42, color: Color(0xFFCBD5E1)),
        ),
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
        return Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 36, color: Color(0xFFCBD5E1)),
          ),
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
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, size: 36, color: Color(0xFFCBD5E1)),
          ),
        ),
      );
    }

    return Image.asset(
      str,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: Icon(Icons.electrical_services_rounded, size: 42, color: Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ApiService>().currentUser;
    final userName = user?['name'] ?? 'Ansil';
    final topPadding = MediaQuery.of(context).padding.top;
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: bgSurface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: goldAccentDark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. HERO / HEADER SECTION (Compact 220-250px)
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: darkNavy.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                  child: Stack(
                    children: [
                      // Shop Background Photo
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/shop_bg.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Smooth Dark Navy Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF0B1120).withValues(alpha: 0.88),
                                const Color(0xFF0F172A).withValues(alpha: 0.94),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Hero Content
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Greeting + Available Balance Chip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, $userName 👋',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: goldAccent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🪙', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(user?['coinBalance'] as num?)?.toInt() ?? 0} Coins',
                                        style: const TextStyle(
                                          color: goldAccent,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Brand Row (Logo + Title + Slogan)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Existing Choice Logo
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0B132B),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: goldAccent.withValues(alpha: 0.4),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Choice Electricals Title & Subtitle
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Choice',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        'Electricals',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'TRUSTED QUALITY · SINCE 2024',
                                        style: TextStyle(
                                          color: goldAccent,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Cursive Brand Motto
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Brighten',
                                      style: TextStyle(
                                        color: const Color(0xFFE5BE4A),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Your World',
                                      style: TextStyle(
                                        color: const Color(0xFFE5BE4A),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // Trust Badges Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildTrustBadge(Icons.verified_user_outlined, 'Quality Products'),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildTrustBadge(Icons.local_shipping_outlined, 'Fast Delivery'),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                  _buildTrustBadge(Icons.headset_mic_outlined, 'Trusted Support'),
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

            // Vertical Spacer (Hero -> Search: 16px)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // 2. SEARCH BAR COMPONENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: darkNavy.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded, color: goldAccentDark, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(
                            fontSize: 14,
                            color: darkNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search for products...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18, color: secondaryGray),
                          splashRadius: 18,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderSubtle),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 18, color: darkNavy),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Vertical Spacer (Search -> Category Header: 24px)
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // 3. CATEGORY SECTION HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shop by Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: darkNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: goldAccentDark,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: goldAccentDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Vertical Spacer (Category Header -> Cards: 12px)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // 4. HORIZONTAL CATEGORY CARDS LIST
            SliverToBoxAdapter(
              child: SizedBox(
                height: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final catName = isAll ? 'All' : _categories[index - 1]['name'].toString();
                    final dynamic catImage = isAll ? null : _categories[index - 1]['image'];
                    final isSelected = _selectedCategory == catName;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = catName),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 82,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                        decoration: BoxDecoration(
                          color: isSelected ? darkNavy : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? goldAccent : borderSubtle,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: darkNavy.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: darkNavy.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Thumbnail / Icon container
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: goldAccent.withValues(alpha: 0.35))
                                    : Border.all(color: borderSubtle),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(21),
                                child: isAll
                                    ? Center(
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          size: 20,
                                          color: isSelected ? goldAccent : darkNavy,
                                        ),
                                      )
                                    : (catImage != null && catImage.toString().trim().isNotEmpty
                                        ? Center(child: _buildCategoryImage(catImage))
                                        : Center(
                                            child: Icon(
                                              _getCategoryFallbackIcon(catName),
                                              size: 20,
                                              color: isSelected ? goldAccent : darkNavy,
                                            ),
                                          )),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Category Label
                            Text(
                              catName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                color: isSelected ? Colors.white : darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Vertical Spacer (Category Cards -> Products Header: 26px)
            const SliverToBoxAdapter(child: SizedBox(height: 26)),

            // 5. ALL PRODUCTS SECTION HEADER + SORT ACTION
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Section Title + Item Count (Flexible to prevent any overflow)
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _selectedCategory == 'All'
                                  ? 'All Products'
                                  : '$_selectedCategory Products',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: darkNavy,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${filtered.length}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: secondaryGray,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Compact Sort Filter Action
                    PopupMenuButton<String>(
                          onSelected: (val) => setState(() => _sortBy = val),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'featured',
                              child: Text('Featured / Default'),
                            ),
                            const PopupMenuItem(
                              value: 'price_asc',
                              child: Text('Price: Low to High'),
                            ),
                            const PopupMenuItem(
                              value: 'price_desc',
                              child: Text('Price: High to Low'),
                            ),
                            const PopupMenuItem(
                              value: 'name_asc',
                              child: Text('Name: A to Z'),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: darkNavy.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_vert_rounded, size: 14, color: darkNavy),
                                const SizedBox(width: 3),
                                Text(
                                  _getSortLabel(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: darkNavy,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: secondaryGray),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            // Vertical Spacer (Products Header -> Grid: 14px)
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // 6. PRODUCT GRID / SKELETON / EMPTY STATE
            if (_isLoading)
              _buildSkeletonGrid()
            else if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderSubtle),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: darkNavy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try another category or search for a different product.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: secondaryGray,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.refresh_rounded, size: 16, color: darkNavy),
                          label: const Text(
                            'Clear Filters',
                            style: TextStyle(
                              color: darkNavy,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = filtered[index];
                      return _buildProductCard(product);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: goldAccent),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic product) {
    final images = (product['images'] is List && (product['images'] as List).isNotEmpty)
        ? (product['images'] as List)
        : [];
    final dynamic firstImage = images.isNotEmpty ? images.first : null;
    final productId = product['_id']?.toString() ?? '';
    final isFavorite = _favoriteProductIds.contains(productId);
    final price = (product['priceInCoins'] as num?)?.toInt() ?? 0;
    final isBlocked = product['status'] == 'blocked';

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Area with Rounded Top (Proportional Flexible Height)
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        child: Hero(
                          tag: 'product-$productId',
                          child: _buildProductThumbnail(firstImage),
                        ),
                      ),
                    ),

                    // Floating Favorite Button (Top-Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isFavorite) {
                              _favoriteProductIds.remove(productId);
                            } else {
                              _favoriteProductIds.add(productId);
                            }
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: darkNavy.withValues(alpha: 0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorite ? const Color(0xFFEF4444) : secondaryGray,
                          ),
                        ),
                      ),
                    ),

                    // Out of Stock Overlay
                    if (isBlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                          child: const Center(
                            child: Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info & Price
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product Name (Supports 2 lines without overflowing)
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: darkNavy,
                          height: 1.22,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Price Row & Cart Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                                  child: Text(
                                    '🪙',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$price',
                                style: const TextStyle(
                                  color: darkNavy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'Coins',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: secondaryGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Quick View/Cart Action Button
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: goldAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 15,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 32),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 11,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 60,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: 4,
        ),
      ),
    );
  }
}
