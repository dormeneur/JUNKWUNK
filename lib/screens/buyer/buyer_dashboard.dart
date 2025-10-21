import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';
import '../../widgets/app_bar.dart';
import '../../utils/design_constants.dart';
import 'buyer_cart.dart';
import '../profile/profile_page.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => BuyerDashboardState();
}

class BuyerDashboardState extends State<BuyerDashboard>
    with SingleTickerProviderStateMixin {
  String? selectedFilter;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int cartItemCount = 0;
  late TabController _tabController;
  // Using design system colors
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
        setState(() {
          switch (_tabController.index) {
            case 0:
              selectedFilter = null;
              break;
            case 1:
              selectedFilter = 'Donate';
              break;
            case 2:
              selectedFilter = 'Recyclable';
              break;
            case 3:
              selectedFilter = 'Non-Recyclable';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    _tabController.animateTo(page);
    setState(() {
      switch (page) {
        case 0:
          selectedFilter = null;
          break;
        case 1:
          selectedFilter = 'Donate';
          break;
        case 2:
          selectedFilter = 'Recyclable';
          break;
        case 3:
          selectedFilter = 'Non-Recyclable';
          break;
      }
    });
  }

  Future<void> loadCartItemCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      setState(() {
        cartItemCount = cartSnapshot.docs.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
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
                    MaterialPageRoute(builder: (context) => BuyerCart()),
                  ).then((_) => loadCartItemCount());
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
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
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: AppTypography.fontSizeXS,
                        fontWeight: AppTypography.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
        backgroundColor: AppColors.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorders.borderRadiusLG,
        ),
        child: const Icon(
          Icons.refresh_rounded,
          color: AppColors.white,
        ),
      ),
    );
  }

  Widget _buildItemsView(String? filterValue) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorders.radiusXL),
          topRight: Radius.circular(AppBorders.radiusXL),
        ),
        boxShadow: AppShadows.shadow2,
      ),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      padding: AppSpacing.paddingVerticalMD,
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
            return Center(
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

