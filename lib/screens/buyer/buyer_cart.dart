import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/screens/buyer/item_location.dart';
import '/services/api_service.dart';
import '/utils/colors.dart' as colors;
import '/utils/custom_toast.dart';
import '/utils/map_coordinates.dart';
import '/widgets/s3_image.dart';

class BuyerCart extends StatefulWidget {
  const BuyerCart({super.key});

  @override
  State<BuyerCart> createState() => _BuyerCartState();
}

class _BuyerCartState extends State<BuyerCart> with TickerProviderStateMixin {
  String? userId;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<CartItem> cartItems = [];
  Set<String> selectedItems = {};
  bool isSelectionMode = false;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Animation controllers
  late AnimationController _selectionController;
  final List<AnimationController> _itemControllers = [];

  // Colors from centralized colors.dart - Light Green Theme
  final Color primaryColor = colors.AppColors.primary; // Medium green #81C784
  final Color scaffoldBg =
      colors.AppColors.backgroundLight; // Light green #F1F8F4
  final Color cardBg = colors.AppColors.white; // White
  final Color textColor = colors.AppColors.textPrimary; // Dark gray-green
  final Color borderColor = colors.AppColors.borderLight; // Light green border

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserAndCart();
  }

  Future<void> _loadUserAndCart() async {
    // Load Cognito user ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('cognito_user_id');

    if (mounted) {
      _loadCartItems();
    }
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
      // Get cart items via API
      final cartData = await ApiService.getCart().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );

      final items = cartData
          .map((item) {
            try {
              return CartItem(
                id: item['itemId'] ?? '',
                sellerId: item['sellerId'] ?? '',
                itemId: item['itemId'] ?? '',
                title: item['title'] ?? 'Unknown Item',
                description: item['description'] ?? '',
                imageUrl: item['imageUrl'] ?? '',
                categories: List<String>.from(item['categories'] ?? []),
                price: ((item['price'] ?? 0).toDouble()),
                quantity: ((item['quantity'] ?? 1) is int
                    ? item['quantity']
                    : (item['quantity'] as num).toInt()),
                sellerName: item['sellerName'] ?? 'Unknown Seller',
                city: item['city'] ?? 'Unknown City',
                coordinates: item['coordinates'] != null
                    ? MapCoordinates(
                        latitude: ((item['coordinates']['lat'] ?? 0) as num)
                            .toDouble(),
                        longitude: ((item['coordinates']['lng'] ?? 0) as num)
                            .toDouble(),
                      )
                    : MapCoordinates(latitude: 0.0, longitude: 0.0),
              );
            } catch (e) {
              debugPrint('Error parsing cart item: $e');
              return null;
            }
          })
          .whereType<CartItem>()
          .toList();

      if (mounted) {
        setState(() {
          cartItems = items;
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

      // Remove from cart via API
      final success = await ApiService.removeFromCart(item.itemId);

      if (success) {
        // Update local state
        setState(() {
          cartItems.removeAt(index);
          if (_itemControllers.length > index) {
            _itemControllers[index].dispose();
            _itemControllers.removeAt(index);
          }
        });
      } else {
        _showErrorSnackbar('Failed to remove item');
      }
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
      // Get item IDs for checkout
      final itemIdsToCheckout = selectedItems.toList();

      // Call checkout API
      final result = await ApiService.checkout(itemIdsToCheckout);

      if (result != null) {
        // Update UI
        setState(() {
          cartItems.removeWhere((item) => selectedItems.contains(item.itemId));
          selectedItems.clear();
          isSelectionMode = false;
        });

        _showSuccessSnackbar('Checkout successful!');
      } else {
        _showErrorSnackbar('Checkout failed. Please try again.');
      }
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
      backgroundColor: scaffoldBg, // Light green background #F1F8F4
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor, // Light green #81C784
        elevation: 2, // Reduced elevation for subtle shadow
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
        icon: const Icon(Icons.close),
        color: Colors.white, // White on colored background
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
      color: cardBg, // White background
      elevation: isSelected ? 4 : 2, // Subtle elevation
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14), // 12-16px radius
        side: BorderSide(
          color: isSelected
              ? colors.AppColors.primaryMedium // Medium green when selected
              : borderColor, // Light green border
          width: isSelected ? 2.0 : 1.0,
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
                color:
                    isSelected ? primaryColor.withValues(alpha: 0.1) : cardBg,
                borderRadius: BorderRadius.circular(14),
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
                    color: colors.AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colors.AppColors.error,
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
      child: S3Image(
        imageKey: imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorWidget: Container(
          width: 80,
          height: 80,
          color: colors.AppColors.primaryLightest, // Very light green
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
            color: textColor, // Dark gray-green
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
                color: colors.AppColors.textSecondary, // Medium green
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
                color: colors.AppColors.textSecondary, // Medium green
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
                color: colors.AppColors.textSecondary, // Medium green
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.currency_rupee, size: 16, color: primaryColor),
            Text(
              '₹${item.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: colors.AppColors.textSecondary, // Medium green
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
            color: colors.AppColors.textHint, // Light gray
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          children: item.categories.map((category) {
            // Use different light green shades for different categories
            Color categoryColor = _getCategoryColor(category);
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: categoryColor,
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

  // Helper method to get category-specific colors
  Color _getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('donate')) {
      return colors.AppColors.donate; // #81C784
    } else if (lowerCategory.contains('recyclable')) {
      return colors.AppColors.recyclable; // #A5D6A7
    } else if (lowerCategory.contains('non-recyclable') ||
        lowerCategory.contains('nonrecyclable')) {
      return colors.AppColors.nonRecyclable; // #66BB6A
    }
    return primaryColor; // Default to primary color
  }

  Widget _buildCheckoutBar() {
    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg, // White background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // Subtle shadow
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Selected: ${selectedItems.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor, // Dark gray-green
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: selectedItems.isNotEmpty ? _processCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  colors.AppColors.primaryMedium, // Medium green #66BB6A
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  colors.AppColors.primaryMedium.withValues(alpha: 0.45),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Request Items',
              style: TextStyle(
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
  final String sellerName;
  final String city;
  final MapCoordinates coordinates;

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
}
