import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'reward_store_screen.dart';
import 'order_history_screen.dart';
import 'wallet_screen.dart';
import 'transfer_wallet_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const _HomeContent(),
    RewardStoreScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
    const OrderHistoryScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  static const Color darkNavy = AppColors.textPrimary;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color slateGray = AppColors.textSecondary;
  static const Color inactiveGray = AppColors.inactiveIcon;
  static const Color borderSubtle = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color lightTeal = AppColors.lightTeal;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: bgSurface,
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
                color: darkNavy.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'HOME'),
                  _buildNavItem(1, Icons.shopping_bag_outlined, 'REWARDS'),
                  _buildNavItem(2, Icons.receipt_long_rounded, 'ORDERS'),
                  _buildNavItem(3, Icons.account_balance_wallet_rounded, 'WALLET'),
                  _buildNavItem(4, Icons.person_rounded, 'PROFILE'),
                ],
              ),
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
          splashColor: secondaryTeal.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? lightTeal
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? secondaryTeal : inactiveGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isSelected ? secondaryTeal : slateGray,
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
  bool _isLoading = false;

  static const Color primaryNavy = AppColors.primaryNavy;
  static const Color secondaryTeal = AppColors.secondaryTeal;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color cardBorder = AppColors.border;
  static const Color bgSurface = AppColors.background;
  static const Color lightTeal = AppColors.lightTeal;
  static const Color successGreen = AppColors.successGreen;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      await Future.wait([
        api.getMyWallet(forceRefresh: true).catchError((_) => <String, dynamic>{}),
        api.getProducts(forceRefresh: true).catchError((_) => []),
        api.getCategories(forceRefresh: true).catchError((_) => []),
      ]);
    } catch (_) {
      // Graceful error handling
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '25/01/2025';
    try {
      final d = DateTime.parse(dateVal.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return '25/01/2025';
    }
  }

  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: secondaryTeal, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: cardBorder),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: lightTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: secondaryTeal, size: 20),
              ),
              title: const Text('Welcome to Choice Electricals Loyalty!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
              subtitle: const Text('Earn points with every purchase and redeem them at the Reward Store.', style: TextStyle(fontSize: 12, color: textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  void _showScanModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final couponCtrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Icon(Icons.qr_code_scanner_rounded, size: 48, color: secondaryTeal),
              const SizedBox(height: 10),
              const Text(
                'Scan or Enter Coupon Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Redeem your Choice Electricals scratch coupon to earn instant points.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: couponCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter Coupon Code (e.g. CHOICE500)',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: secondaryTeal),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: secondaryTeal, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coupon verification feature active. Please contact counter staff to validate.'),
                        backgroundColor: primaryNavy,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: const Text('Redeem Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSchemeModal(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: secondaryTeal),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          ],
        ),
        content: Text(description, style: const TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final user = api.currentUser ?? {};
    final userName = (user['name'] ?? 'Choice Electricals & Plumbing').toString();
    final userPhone = (user['phoneNumber'] ?? '9656077404').toString();
    final rawId = (user['id'] ?? user['_id'] ?? '696081097798').toString();
    final memberId = rawId.replaceAll('-', '').substring(0, rawId.length >= 10 ? 10 : rawId.length).toUpperCase();
    final regDate = _formatDate(user['createdAt']);
    final coinBalance = (user['coinBalance'] ?? 0).toString();

    return Scaffold(
      backgroundColor: bgSurface,
      drawer: _buildAppDrawer(userName, userPhone, memberId, api),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: primaryNavy, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'C',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choice Electricals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: primaryNavy,
                  ),
                ),
                Text(
                  'LOYALTY & REWARDS PORTAL',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: primaryNavy, size: 26),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: const Text(
                      '1',
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
            onPressed: _showNotificationSheet,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: secondaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. USER PROFILE HEADER CARD
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryNavy.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Profile Image with Approved Checkmark
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: secondaryTeal, width: 2),
                            color: bgSurface,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 42,
                              color: AppColors.inactiveIcon,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: successGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mem ID $memberId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Mobile No $userPhone',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Reg Date $regDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Approved',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. REWARDS RIBBON
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    const Text(
                      'Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _loadData,
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3. DUAL TOP METRIC CARDS
              Row(
                children: [
                  // Card 1: Solid Navy Blue Wallet Card
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransferWalletScreen()),
                        );
                      },
                      child: Container(
                        height: 84,
                        decoration: BoxDecoration(
                          color: primaryNavy,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Wallet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹ $coinBalance',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Card 2: White Card with Teal Border for Coins/Points
                  Expanded(
                    child: Container(
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: secondaryTeal, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNavy.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.toll_rounded,
                            color: secondaryTeal,
                            size: 38,
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Points',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                coinBalance,
                                style: const TextStyle(
                                  color: secondaryTeal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
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

              const SizedBox(height: 16),

              // 4. ACTION GRID (2 COLUMNS)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _buildActionTile(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Transfer Wallet Amount',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransferWalletScreen()),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.center_focus_strong_rounded,
                    title: 'Scan',
                    onTap: _showScanModal,
                  ),
                  _buildActionTile(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Reward Store',
                    isHighlight: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RewardStoreScreen()),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.groups_rounded,
                    title: 'Electrician Meet',
                    onTap: () => _showSchemeModal(
                      'Electrician Meet',
                      'Exclusive Choice Electricals contractor and electrician meetups with technical product workshops and special point bonuses.',
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Coupon Redeem',
                    onTap: _showScanModal,
                  ),
                  _buildActionTile(
                    icon: Icons.hub_outlined,
                    title: 'Airwire Scheme',
                    onTap: () => _showSchemeModal(
                      'Airwire Scheme',
                      'Purchase Choice Electricals wiring bundles and earn up to 2x loyalty bonus points directly credited to your member account.',
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.person_pin_circle_outlined,
                    title: 'Counter Boy',
                    onTap: () => _showSchemeModal(
                      'Counter Boy Assist',
                      'Show your Member ID ($memberId) to our counter staff at Choice Electricals store for instant in-person invoice verification.',
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Coupon List',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.stacked_bar_chart_rounded,
                    title: 'Slabwise Scheme',
                    onTap: () => _showSchemeModal(
                      'Slabwise Scheme Tiers',
                      '• Silver: 0 - 5,000 Points\n• Gold: 5,001 - 25,000 Points (5% Bonus)\n• Platinum: 25,000+ Points (10% Bonus + Gift Rewards)',
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.share_rounded,
                    title: 'Referral Code',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Your Referral Code', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: lightTeal,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: secondaryTeal, width: 1.2),
                                ),
                                child: Text(
                                  memberId,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: secondaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Share this code with fellow electricians. Earn 100 bonus points when they register!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. BANNER: OPEN REWARD STORE
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RewardStoreScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryNavy.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: secondaryTeal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore Reward Store',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Redeem shavers, kettles, flasks & tools with points',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: secondaryTeal.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight ? secondaryTeal.withValues(alpha: 0.5) : cardBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryNavy.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isHighlight ? secondaryTeal : primaryNavy,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(String name, String phone, String memId, ApiService api) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: bgSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryNavy,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  Text(
                    'Mem ID: $memId • $phone',
                    style: const TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: cardBorder),

            // Navigation Items
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, color: secondaryTeal),
              title: const Text('Reward Store', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardStoreScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: secondaryTeal),
              title: const Text('Redeemed Orders', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined, color: secondaryTeal),
              title: const Text('Wallet & Points', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: secondaryTeal),
              title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const Spacer(),
            const Divider(height: 1, color: cardBorder),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: primaryNavy),
              title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                await api.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
