import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/colors.dart' as colors;
import '../../utils/design_constants.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/item_card.dart';
import '../profile/profile_page.dart';
import 'buyer_cart.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => BuyerDashboardState();
}

class BuyerDashboardState extends State<BuyerDashboard>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);
  final ValueNotifier<int> refreshTrigger = ValueNotifier<int>(0);
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    loadCartItemCount();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    cartItemCount.dispose();
    refreshTrigger.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    _tabController.animateTo(page);
  }

  Future<void> loadCartItemCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      // Calculate total items considering quantities
      int totalItems = 0;
      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        totalItems += (data['quantity'] ?? 1) as int;
      }

      // Update ValueNotifier instead of calling setState
      cartItemCount.value = totalItems;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: colors.AppColors.scaffoldBackground,
      appBar: AppBarWidget(
        title: 'Browse Products',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileUI()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          BuyerCart(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  ).then((_) {
                    loadCartItemCount();
                    refreshTrigger.value++; // Trigger refresh of item cards
                  });
                },
              ),
              ValueListenableBuilder<int>(
                valueListenable: cartItemCount,
                builder: (context, itemCount, child) {
                  if (itemCount <= 0) return const SizedBox.shrink();

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        key: ValueKey(itemCount),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            '$itemCount',
                            key: ValueKey(itemCount),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: AppTypography.fontSizeXS,
                              fontWeight: AppTypography.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              boxShadow: AppShadows.shadow2,
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.white,
              indicatorWeight: 3,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
              tabs: const [
                Tab(
                  icon: Icon(Icons.category),
                  text: 'All Items',
                ),
                Tab(
                  icon: Icon(Icons.volunteer_activism),
                  text: 'Donate',
                ),
                Tab(
                  icon: Icon(Icons.recycling),
                  text: 'Recyclable',
                ),
                Tab(
                  icon: Icon(Icons.delete_outline),
                  text: 'Non-Recyclable',
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: List.generate(4, (index) {
                switch (index) {
                  case 0:
                    return _buildItemsView(null);
                  case 1:
                    return _buildItemsView('Donate');
                  case 2:
                    return _buildItemsView('Recyclable');
                  case 3:
                    return _buildItemsView('Non-Recyclable');
                  default:
                    return _buildItemsView(null);
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsView(String? filterValue) {
    const cardColor = colors.AppColors.scaffoldBackground;

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh cart count
        await loadCartItemCount();
        // Small delay for smooth UX
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: AppColors.primary,
      backgroundColor: cardColor,
      child: StreamBuilder<QuerySnapshot>(
        stream: _buildItemsStreamFiltered(filterValue),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'No items available',
                          style: TextStyle(
                            fontSize: AppTypography.fontSizeXL,
                            color: AppColors.primary,
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Check back later for new products',
                          style: TextStyle(
                            fontSize: AppTypography.fontSizeMD,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final sellerId = doc.reference.parent.parent?.id;

              return FutureBuilder<DocumentSnapshot>(
                future: sellerId != null
                    ? _firestore.collection('sellers').doc(sellerId).get()
                    : null,
                builder: (context, sellerSnapshot) {
                  final city = sellerSnapshot.hasData
                      ? sellerSnapshot.data!['city'] ?? 'Unknown Location'
                      : 'Unknown Location';

                  return ItemCard(
                    key: ValueKey('${doc.id}-${refreshTrigger.value}'),
                    itemId: doc.id,
                    sellerId: sellerId,
                    imageUrl: data['imageUrl'] ?? '',
                    title: data['title'] ?? 'Untitled Item',
                    description: data['description'] ?? 'No description',
                    categories: List<String>.from(data['categories'] ?? []),
                    itemTypes: List<String>.from(data['itemTypes'] ?? []),
                    price: (data['price'] ?? 0.0).toString(),
                    quantity: data['quantity'] ?? 1,
                    timestamp: data['timestamp'] as Timestamp?,
                    city: city,
                    onCartUpdated: loadCartItemCount,
                    refreshTrigger: refreshTrigger,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _buildItemsStreamFiltered(String? filterValue) {
    var query = _firestore
        .collectionGroup('items')
        .where('status', isEqualTo: 'active');

    if (filterValue != null) {
      query = query.where('categories', arrayContains: filterValue);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }
}
