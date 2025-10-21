import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/screens/buyer/item_location.dart';
import '/utils/custom_toast.dart';

class BuyerCart extends StatefulWidget {
  const BuyerCart({super.key});

  @override
  State<BuyerCart> createState() => _BuyerCartState();
}

class _BuyerCartState extends State<BuyerCart> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<CartItem> cartItems = [];
  Set<String> selectedItems = {};
  bool isSelectionMode = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Animation controllers
  late AnimationController _selectionController;
  final List<AnimationController> _itemControllers = [];

  // Colors
  final Color primaryColor = const Color(0xFF371F97);
  final Color lightPurple = const Color(0xFFEEE8F6);
  final Color whiteColor = const Color(0xFFFFFFFF);
  final Color blackColor = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCartItems();
  }

  void _initializeAnimations() {
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _loadCartItems() async {
    if (userId == null) {
      _showErrorSnackbar('User not logged in');
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Connection timeout'),
          );

      final items = await Future.wait(
        snapshot.docs.map((doc) async {
          try {
            final sellerId = doc.get('sellerId');
            final itemId = doc.get('itemId');

            // Get seller document first
            final sellerDoc =
                await _firestore.collection('sellers').doc(sellerId).get();

            if (!sellerDoc.exists) {
              debugPrint('Seller document not found for ID: $sellerId');
              return null;
            }

            // Get item document
            final itemData = await _firestore
                .collection('sellers')
                .doc(sellerId)
                .collection('items')
                .doc(itemId)
                .get();

            if (!itemData.exists) {
              debugPrint('Item document not found for ID: $itemId');
              return null;
            }

            final sellerData = sellerDoc.data()!;
            final originalItemData = itemData.data()!;

            // Handle coordinates - check both separate fields and GeoPoint
            GeoPoint? coordinates;
            if (sellerData['coordinates'] is GeoPoint) {
              coordinates = sellerData['coordinates'] as GeoPoint;
            } else if (sellerData['latitude'] != null &&
                sellerData['longitude'] != null) {
              coordinates = GeoPoint(
                (sellerData['latitude'] as num).toDouble(),
                (sellerData['longitude'] as num).toDouble(),
              );
            }

            debugPrint(
                'Fetched coordinates for seller $sellerId: ${coordinates?.latitude}, ${coordinates?.longitude}');

            return CartItem(
              id: doc.id,
              itemId: itemId,
              sellerId: sellerId,
              title: originalItemData['title'] ?? '',
              description: originalItemData['description'] ?? '',
              imageUrl: originalItemData['imageUrl'] ?? '',
              categories:
                  List<String>.from(originalItemData['categories'] ?? []),
              price: (originalItemData['price'] ?? 0.0).toDouble(),
              quantity: doc.get('quantity') ?? 1,
              sellerName: sellerData['name'] ?? 'Unknown Seller',
              city: sellerData['city'] ?? 'Location not available',
              coordinates: coordinates ?? GeoPoint(0.0, 0.0),
            );
          } catch (e) {
            debugPrint('Error loading item ${doc.id}: $e');
            return null;
          }
        }),
      );

      if (mounted) {
        setState(() {
          cartItems = items.whereType<CartItem>().toList();
          _isLoading = false;
        });
        _updateItemControllers();
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(
            'Connection timeout. Please check your internet connection.');
      }
    } catch (e) {
      debugPrint('Error loading cart items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Error loading cart items: ${e.toString()}');
      }
    }
  }

  void _updateItemControllers() {
    // Dispose existing controllers
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();

    // Create new controllers
    for (int i = 0; i < cartItems.length; i++) {
      _itemControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _removeItem(int index) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final item = cartItems[index];

      // Animate the removal
      if (_listKey.currentState != null) {
        _listKey.currentState!.removeItem(
          index,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(
              opacity: animation,
              child: _buildCartItem(item, index),
            ),
          ),
          duration: const Duration(milliseconds: 300),
        );
      }

      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(item.id)
          .delete();

      // Update local state
      setState(() {
        cartItems.removeAt(index);
        if (_itemControllers.length > index) {
          _itemControllers[index].dispose();
          _itemControllers.removeAt(index);
        }
      });
    } catch (e) {
      _showErrorSnackbar('Error removing item');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processCheckout() async {
    if (_isProcessing || selectedItems.isEmpty) return;
    _isProcessing = true;

    try {
      final batch = _firestore.batch();

      for (var itemId in selectedItems) {
        final item = cartItems.firstWhere((item) => item.id == itemId);

        // Get the current item quantity from seller's collection
        final itemRef = _firestore
            .collection('sellers')
            .doc(item.sellerId)
            .collection('items')
            .doc(item.itemId);

        final itemDoc = await itemRef.get();
        if (itemDoc.exists) {
          final currentQuantity = itemDoc.data()?['quantity'] ?? 0;
          final newQuantity = currentQuantity - item.quantity;

          // Update the item quantity or set status to inactive if out of stock
          if (newQuantity <= 0) {
            batch.update(itemRef, {
              'quantity': 0,
              'status': 'inactive', // Mark as inactive when out of stock
            });
          } else {
            batch.update(itemRef, {
              'quantity': newQuantity,
            });
          }
        }

        // Create purchase record
        final purchaseRef = _firestore.collection('purchases').doc();
        batch.set(purchaseRef, item.toPurchaseMap(userId!));

        // Remove from cart
        final cartRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(item.id);
        batch.delete(cartRef);
      }

      await batch.commit();

      // Update UI
      setState(() {
        cartItems.removeWhere((item) => selectedItems.contains(item.id));
        selectedItems.clear();
        isSelectionMode = false;
      });

      _showSuccessSnackbar('Checkout successful!');
    } catch (e) {
      debugPrint('Error processing checkout: $e');
      _showErrorSnackbar('Error processing checkout: ${e.toString()}');
    } finally {
      _isProcessing = false;
    }
  }

  void _showErrorSnackbar(String message) {
    CustomToast.showError(context, message);
  }

  void _showSuccessSnackbar(String message) {
    CustomToast.showSuccess(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPurple,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 4,
        actions: _buildAppBarActions(),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildBody(),
      bottomNavigationBar: _buildCheckoutBar(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!isSelectionMode) return [];

    return [
      IconButton(
        icon: Icon(Icons.close, color: whiteColor),
        onPressed: () {
          setState(() {
            isSelectionMode = false;
            selectedItems.clear();
          });
        },
      ),
    ];
  }

  Widget _buildBody() {
    if (cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: primaryColor),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: cartItems.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index, animation) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
          ),
          child: _buildCartItem(cartItems[index], index),
        );
      },
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    final isSelected = selectedItems.contains(item.id);

    return Card(
      elevation: isSelected ? 8 : 2, // Increase elevation when selected
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? const Color.fromARGB(255, 121, 89, 219)
              : Colors.transparent, // Darker purple
          width: 3.0, // Increased border width
        ),
      ),
      child: InkWell(
        onTap: isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    selectedItems.remove(item.id);
                    if (selectedItems.isEmpty) {
                      isSelectionMode = false;
                    }
                  } else {
                    selectedItems.add(item.id);
                  }
                });
              }
            : null,
        onLongPress: () {
          setState(() {
            isSelectionMode = true;
            selectedItems.add(item.id);
          });
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildItemImage(item.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildItemDetails(item),
                  ),
                ],
              ),
            ),
            // Trash icon
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeItem(index),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Marker button
            Positioned(
              top: 48, // Position it below the trash icon
              right: 8,
              child: GestureDetector(
                onTap: () => {
                  debugPrint(item.coordinates.latitude as String?),
                  debugPrint(item.coordinates.longitude as String?),
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemLocation(
                        coordinates: item
                            .coordinates, // Pass your existing GeoPoint here
                      ),
                    ),
                  )
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(String imageUrl) {
    return ClipRRect(
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
    );
  }

  Widget _buildItemDetails(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: blackColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              item.sellerName,
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.location_on_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              item.city,
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              'Quantity: ${item.quantity}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.currency_rupee, size: 16, color: primaryColor),
            Text(
              '₹${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: blackColor.withValues(alpha: 0.6),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: item.categories.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Selected: ${selectedItems.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: selectedItems.isNotEmpty ? _processCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(
              'Request Items',
              style: TextStyle(
                color: whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class CartItem {
  final String id;
  final String itemId;
  final String sellerId;
  final String title;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final double price;
  final int quantity;
  final String sellerName; // Added missing field
  final String city;
  final GeoPoint coordinates; // Added missing field

  CartItem({
    required this.id,
    required this.itemId,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.price,
    required this.quantity,
    required this.sellerName,
    required this.city,
    required this.coordinates,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartItem(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      categories: List<String>.from(data['categories'] ?? []),
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      city: data['city'] ?? 'Location not available',
      coordinates:
          data['coordinates'] ?? GeoPoint(0.0, 0.0), // Added missing field
    );
  }

  Map<String, dynamic> toPurchaseMap(String userId) {
    return {
      'userId': userId,
      'sellerId': sellerId,
      'itemId': itemId,
      'timestamp': Timestamp.now(),
      'status': 'completed',
      'title': title,
      'description': description,
      'categories': categories,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'price': price,
      'sellerName': sellerName, // Added missing field
      'city': city, // Added missing field
    };
  }
}
