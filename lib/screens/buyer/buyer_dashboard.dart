import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';
import '../../widgets/app_bar.dart';
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
  final Color primaryColor = const Color(0xFF371f97);
  final Color secondaryColor = const Color(0xFFEEE8F6);
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
      backgroundColor: secondaryColor,
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
                          color: Colors.black.withOpacity(0.2),
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
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
              color: primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: [
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
        backgroundColor: primaryColor,
        child: const Icon(Icons.refresh_rounded, color: Colors.white),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildItemsView(String? filterValue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: _buildItemsStreamFiltered(filterValue),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF371f97)),
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
                  Icon(Icons.inventory_2_outlined,
                      size: 80, color: const Color(0xFFEEE8F6)),
                  const SizedBox(height: 16),
                  const Text(
                    'No items available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF371f97),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new products',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                onCartUpdated: loadCartItemCount,
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
