import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/item_card.dart';
import '../login_page.dart';
import 'buyer_cart.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => BuyerDashboardState();
}

class BuyerDashboardState extends State<BuyerDashboard> {
  String? selectedFilter;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    loadCartItemCount();
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
      backgroundColor: const Color(0xFFEEE8F6),
      appBar: AppBar(
        title: const Text(
          'JunkWunk',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF371f97),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Color(0xFF371f97),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFF371f97),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All Items', null),
                      const SizedBox(width: 10),
                      _buildFilterButton('Donate', 'Donate'),
                      const SizedBox(width: 10),
                      _buildFilterButton('Recyclable', 'Recyclable'),
                      const SizedBox(width: 10),
                      _buildFilterButton('Non-Recyclable', 'Non-Recyclable'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildItemsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF371f97)),
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
                          Icon(Icons.inbox,
                              size: 64, color: const Color(0xFFEEE8F6)),
                          const SizedBox(height: 16),
                          const Text(
                            'No items available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF371f97),
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
                        timestamp: data['timestamp'] as Timestamp?,
                        onCartUpdated: loadCartItemCount,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
        backgroundColor: const Color(0xFF371f97),
        child: const Icon(Icons.refresh, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilterButton(String label, String? filterValue) {
    final isSelected = selectedFilter == filterValue;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF371f97) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildItemsStream() {
    var query = _firestore
        .collectionGroup('items')
        .where('status', isEqualTo: 'active');

    if (selectedFilter != null) {
      query = query.where('categories', arrayContains: selectedFilter);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }
}
