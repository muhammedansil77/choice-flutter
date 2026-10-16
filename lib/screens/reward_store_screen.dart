import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'product_detail_screen.dart';
import 'order_history_screen.dart';

class RewardStoreScreen extends StatefulWidget {
  final String? initialCategory;

  const RewardStoreScreen({super.key, this.initialCategory});

  @override
  State<RewardStoreScreen> createState() => _RewardStoreScreenState();
}

class _RewardStoreScreenState extends State<RewardStoreScreen> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  String? _selectedCategoryFilter;
  String _sortOrder = 'default'; // 'default', 'low_to_high', 'high_to_low'
  bool _isLoading = true;

  // Design Tokens (Loyalty Red Accent & Clean Enterprise Styling)
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color bgSurface = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _selectedCategoryFilter = widget.initialCategory;
    _fetchData();
  }

  Future<void> _fetchData() async {
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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Group products by their categories and apply sorting
  Map<String, List<dynamic>> get _categoryGroupedProducts {
    final Map<String, List<dynamic>> groups = {};

    final list = List<dynamic>.from(_products);

    // Apply Low to High or High to Low Points Sorting
    num getPoints(dynamic p) {
      if (p == null) return 0;
      final val = p['priceInCoins'] ?? p['coinPrice'] ?? p['price'] ?? 0;
      if (val is num) return val;
      if (val is String) {
        return num.tryParse(val) ?? 0;
      }
      return 0;
    }

    if (_sortOrder == 'low_to_high') {
      list.sort((a, b) => getPoints(a).compareTo(getPoints(b)));
    } else if (_sortOrder == 'high_to_low') {
      list.sort((a, b) => getPoints(b).compareTo(getPoints(a)));
    }

    // If a specific category filter is chosen via "View More"
    if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'All') {
      final filtered = list.where((p) => p['category'] == _selectedCategoryFilter).toList();
      groups[_selectedCategoryFilter!] = filtered;
      return groups;
    }

    // When sorting is active (Low to High or High to Low),
    // display all products globally across the store in true sorted order
    if (_sortOrder == 'low_to_high') {
      groups['POINTS: LOW TO HIGH'] = list;
      return groups;
    } else if (_sortOrder == 'high_to_low') {
      groups['POINTS: HIGH TO LOW'] = list;
      return groups;
    }

    // Default view: Group by defined categories from server
    for (final cat in _categories) {
      final catName = (cat['name'] ?? '').toString().trim();
      if (catName.isNotEmpty) {
        final matching = list.where((p) => p['category'] == catName).toList();
        if (matching.isNotEmpty) {
          groups[catName] = matching;
        }
      }
    }

    // Add any remaining products under categories not in the category list
    for (final p in list) {
      final catName = (p['category'] ?? 'General Products').toString().trim();
      final key = catName.isEmpty ? 'General Products' : catName;
      if (!groups.containsKey(key)) {
        groups[key] = [p];
      } else if (!groups[key]!.contains(p)) {
        groups[key]!.add(p);
      }
    }

    return groups;
  }

  Widget _buildProductThumbnail(dynamic images) {
    String? imgStr;
    if (images is List && images.isNotEmpty) {
      imgStr = images.first?.toString().trim();
    } else if (images is String && images.trim().isNotEmpty) {
      imgStr = images.trim();
    }

    if (imgStr != null && imgStr.isNotEmpty) {
      if (imgStr.startsWith('data:image')) {
        try {
          final base64String = imgStr.split(',')[1];
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildFallbackIcon(),
          );
        } catch (_) {
          return _buildFallbackIcon();
        }
      } else if (imgStr.startsWith('http://') || imgStr.startsWith('https://')) {
        return Image.network(
          imgStr,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        );
      }
    }

    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF94A3B8),
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _categoryGroupedProducts;

    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
          onPressed: () {
            if (_selectedCategoryFilter != null) {
              setState(() => _selectedCategoryFilter = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _selectedCategoryFilter != null
              ? _selectedCategoryFilter!.toUpperCase()
              : 'Reward Store',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Redeem Orders',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: textDark, size: 24),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: primaryRed,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryRed),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Sort Filter Bar at Top (Low to High / High to Low)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildSortChip('Default', 'default', Icons.grid_view_rounded),
                            const SizedBox(width: 8),
                            _buildSortChip('Low to High', 'low_to_high', Icons.arrow_upward_rounded),
                            const SizedBox(width: 8),
                            _buildSortChip('High to Low', 'high_to_low', Icons.arrow_downward_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // If filtering by a single category, show active filter indicator
                  if (_selectedCategoryFilter != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              'Showing: $_selectedCategoryFilter',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategoryFilter = null),
                              child: const Text(
                                'Clear Filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Empty State Check
                  if (grouped.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No reward products available yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categorized Sections
                  for (final entry in grouped.entries)
                    SliverToBoxAdapter(
                      child: _buildCategorySection(
                        categoryName: entry.key,
                        products: entry.value,
                        isFilteredView: _selectedCategoryFilter != null || _sortOrder != 'default',
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
      ),
    );
  }

  Widget _buildSortChip(String label, String sortKey, IconData icon) {
    final isSelected = _sortOrder == sortKey;
    return InkWell(
      onTap: () {
        setState(() {
          _sortOrder = sortKey;
          if (sortKey != 'default') {
            _selectedCategoryFilter = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryRed : cardBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryRed.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : textDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required String categoryName,
    required List<dynamic> products,
    required bool isFilteredView,
  }) {
    // Show top 3 in overview mode, or all in filtered view
    final displayProducts = isFilteredView ? products : products.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header with "View More" (matches Screenshot 2)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  categoryName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isFilteredView && products.length > 3)
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryFilter = categoryName);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View\nMore',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: primaryRed,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Product Cards List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: displayProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = displayProducts[index];
            return _buildHorizontalProductCard(product);
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalProductCard(dynamic product) {
    final title = (product['name'] ?? 'Electrical Product').toString();
    final description = (product['description'] ?? '').toString();
    final points = (product['priceInCoins'] ?? product['coinPrice'] ?? 0).toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product as Map<String, dynamic>),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: textDark.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product Image Box (matches Screenshot 2 left container)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                padding: const EdgeInsets.all(6),
                child: _buildProductThumbnail(product['images']),
              ),
              const SizedBox(width: 14),

              // Product Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['category'] != null && product['category'].toString().trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product['category'].toString().trim().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),

                    // Red Points Counter (matches Screenshot 2 bottom-right)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            points,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: primaryRed,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primaryRed,
                              height: 1.0,
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
    );
  }
}
