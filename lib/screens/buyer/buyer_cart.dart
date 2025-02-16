import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerCart extends StatefulWidget {
  const BuyerCart({super.key});

  @override
  State<BuyerCart> createState() => _BuyerCartState();
}

class _BuyerCartState extends State<BuyerCart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  Set<String> selectedItems = {};
  bool isSelectionMode = false;
  Set<String> checkoutItems = {};

  // Define the new colors
  final Color primaryColor = const Color(0xFF371F97); // #371f97
  final Color lightPurple = const Color(0xFFEEE8F6); // #eee8f6
  final Color whiteColor = const Color(0xFFFFFFFF); // #ffffff
  final Color blackColor = const Color(0xFF000000); // #000000

  Map<String, int> categoryCounts = {
    'Donate': 0,
    'Recyclable': 0,
    'Non-Recyclable': 0,
  };

  @override
  void initState() {
    super.initState();
    _updateCategoryCounts();
  }

  Future<void> _updateCategoryCounts() async {
    if (userId == null) return;

    final cartItems = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    Map<String, int> newCounts = {
      'Donate': 0,
      'Recyclable': 0,
      'Non-Recyclable': 0,
    };

    for (var doc in cartItems.docs) {
      List<String> categories =
          List<String>.from(doc.data()['categories'] ?? []);
      for (var category in categories) {
        if (newCounts.containsKey(category)) {
          newCounts[category] = newCounts[category]! + 1;
        }
      }
    }

    if (mounted) {
      setState(() {
        categoryCounts = newCounts;
      });
    }
  }

  Future<void> _deleteSelectedItems() async {
    if (userId == null) return;

    final batch = _firestore.batch();

    for (var itemId in selectedItems) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId);
      batch.delete(docRef);
    }

    await batch.commit();

    if (mounted) {
      setState(() {
        selectedItems.clear();
        isSelectionMode = false;
      });
    }

    _updateCategoryCounts();
  }

  Future<void> _processCheckout() async {
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      // Get current cart items
      final cartSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      // Check if any items are selected for checkout
      if (checkoutItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select items for checkout'),
            backgroundColor: primaryColor,
          ),
        );
        return;
      }

      // Process only selected items
      for (var doc in cartSnapshot.docs) {
        // Skip if item is not selected for checkout
        if (!checkoutItems.contains(doc.id)) continue;

        final data = doc.data();

        // Create purchase record
        final purchaseRef = _firestore.collection('purchases').doc();
        batch.set(purchaseRef, {
          'userId': userId,
          'sellerId': data['sellerId'],
          'itemId': data['itemId'],
          'timestamp': Timestamp.now(),
          'status': 'pending',
          'title': data['title'],
          'description': data['description'],
          'categories': data['categories'],
          'imageUrl': data['imageUrl'],
        });

        // Delete the item from cart
        final cartItemRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(doc.id);
        batch.delete(cartItemRef);
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          checkoutItems.clear(); // Clear selected items after checkout
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order placed successfully!'),
            backgroundColor: _getCategoryColor('Donate'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing checkout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'JunkWunk',
          style: TextStyle(color: blackColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: whiteColor,
        elevation: 1,
        iconTheme: IconThemeData(color: blackColor),
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: selectedItems.isNotEmpty ? _deleteSelectedItems : null,
            ),
            IconButton(
              icon: Icon(Icons.close, color: blackColor),
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedItems.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('Donate', _getCategoryColor('Donate')),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                      'Recyclable', _getCategoryColor('Recyclable')),
                  const SizedBox(width: 8),
                  _buildCategoryChip(
                      'Non-Recyclable', _getCategoryColor('Non-Recyclable')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: lightPurple),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: primaryColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildCartItem(
                      doc.id,
                      data['title'] ?? 'Untitled',
                      data['description'] ?? 'No description',
                      data['imageUrl'] ?? '',
                      List<String>.from(data['categories'] ?? []),
                    );
                  },
                );
              },
            ),
          ),
          _buildCheckoutBar(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${categoryCounts[category]}',
              style: TextStyle(
                color: whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    String itemId,
    String title,
    String description,
    String imageUrl,
    List<String> categories,
  ) {
    bool isSelected = selectedItems.contains(itemId);
    bool isSelectedForCheckout = checkoutItems.contains(itemId);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onLongPress: () {
          setState(() {
            if (!isSelectionMode) {
              isSelectionMode = true;
              selectedItems.add(itemId);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.1)
                : isSelectedForCheckout
                    ? _getCategoryColor('Donate').withOpacity(0.1)
                    : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: lightPurple,
                    child: Icon(Icons.image_not_supported, color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: blackColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: categories.map((category) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: _getCategoryColor(category),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode)
                Checkbox(
                  value: isSelectedForCheckout,
                  activeColor: primaryColor,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value ?? false) {
                        checkoutItems.add(itemId);
                      } else {
                        checkoutItems.remove(itemId);
                      }
                    });
                  },
                ),
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  activeColor: primaryColor,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value ?? false) {
                        selectedItems.add(itemId);
                      } else {
                        selectedItems.remove(itemId);
                        if (selectedItems.isEmpty) {
                          isSelectionMode = false;
                        }
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // Made transparent as requested
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Align(
        // Using Align instead of Row
        alignment: Alignment.centerRight, // Right alignment
        child: ElevatedButton.icon(
          onPressed: checkoutItems.isNotEmpty ? _processCheckout : null,
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('Checkout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: whiteColor,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'donate':
        return const Color(0xFF371F97); // Use primary color for donate
      case 'recyclable':
        return const Color(0xFF371F97); // Use primary color for recyclable
      case 'non-recyclable':
        return const Color(0xFF371F97); // Use primary color for non-recyclable
      default:
        return const Color(0xFF371F97); // Default to primary color
    }
  }
}
