import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/custom_toast.dart';
import '../utils/design_constants.dart';
import 's3_image.dart';

class ItemCard extends StatefulWidget {
  final String itemId;
  final String? sellerId;
  final String imageUrl;
  final String title;
  final String description;
  final List<String> categories;
  final List<String> itemTypes;
  final String price;
  final int quantity;
  final Timestamp? timestamp;
  final VoidCallback? onCartUpdated;
  final String status;
  final String city;
  final ValueNotifier<int>? refreshTrigger;

  const ItemCard({
    super.key,
    required this.itemId,
    required this.sellerId,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.categories,
    required this.itemTypes,
    required this.price,
    required this.city,
    this.quantity = 1,
    this.timestamp,
    this.onCartUpdated,
    this.status = 'active',
    this.refreshTrigger,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  int _selectedQuantity = 1;
  int? _availableQuantity;
  bool _isLoadingQuantity = true;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = 1;
    _loadAvailableQuantity();
    widget.refreshTrigger?.addListener(_onRefresh);
  }

  void _onRefresh() {
    _loadAvailableQuantity();
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefresh);
    super.dispose();
  }

  Future<void> _loadAvailableQuantity() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || widget.sellerId == null) {
      setState(() {
        _availableQuantity = widget.quantity;
        _isLoadingQuantity = false;
      });
      return;
    }

    try {
      // Get total quantity already in cart for this item
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .where('itemId', isEqualTo: widget.itemId)
          .where('sellerId', isEqualTo: widget.sellerId)
          .get();

      int quantityInCart = 0;
      for (var doc in cartSnapshot.docs) {
        quantityInCart += (doc.data()['quantity'] ?? 0) as int;
      }

      setState(() {
        _availableQuantity = widget.quantity - quantityInCart;
        _isLoadingQuantity = false;
      });
    } catch (e) {
      setState(() {
        _availableQuantity = widget.quantity;
        _isLoadingQuantity = false;
      });
    }
  }

  Future<void> _addToCart(
      BuildContext context, String sellerId, String itemId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isAddingToCart = true;
    });

    // Check available quantity
    if (_availableQuantity != null && _availableQuantity! <= 0) {
      if (context.mounted) {
        CustomToast.showError(context, 'This item is out of stock!');
      }
      return;
    }

    // Check if trying to add more than available
    if (_availableQuantity != null && _selectedQuantity > _availableQuantity!) {
      if (context.mounted) {
        CustomToast.showWarning(
            context, 'Only $_availableQuantity item(s) available!');
      }
      return;
    }

    // Check if item already exists in cart
    final existingCartItems = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .where('itemId', isEqualTo: itemId)
        .where('sellerId', isEqualTo: sellerId)
        .get();

    if (existingCartItems.docs.isNotEmpty) {
      // Item already exists, update quantity
      final existingDoc = existingCartItems.docs.first;
      final existingQuantity = existingDoc.data()['quantity'] ?? 0;
      final newQuantity = existingQuantity + _selectedQuantity;

      // Check if new quantity exceeds available quantity
      if (newQuantity > widget.quantity) {
        if (context.mounted) {
          CustomToast.showError(
              context, 'Cannot add more than ${widget.quantity} items!');
        }
        return;
      }

      await existingDoc.reference.update({
        'quantity': newQuantity,
        'timestamp': Timestamp.now(),
      });

      if (context.mounted) {
        CustomToast.showSuccess(
            context, 'Updated cart! Now you have $newQuantity item(s)');

        // Reload available quantity and notify parent
        _loadAvailableQuantity();
        widget.onCartUpdated?.call();
      }
    } else {
      // Add new item to cart
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .add({
        'sellerId': sellerId,
        'itemId': itemId,
        'timestamp': Timestamp.now(),
        'title': widget.title,
        'description': widget.description,
        'imageUrl': widget.imageUrl,
        'categories': widget.categories,
        'itemTypes': widget.itemTypes,
        'price': widget.price,
        'quantity': _selectedQuantity,
        'status': widget.status,
      });

      if (context.mounted) {
        CustomToast.showSuccess(
            context, 'Added $_selectedQuantity item(s) to cart!');

        // Reload available quantity and notify parent
        _loadAvailableQuantity();
        widget.onCartUpdated?.call();
      }
    }

    // Reset selected quantity
    setState(() {
      _selectedQuantity = 1;
      _isAddingToCart = false;
    });
  }

  void _updateQuantity(int amount) {
    setState(() {
      final maxQuantity = _availableQuantity ?? widget.quantity;
      _selectedQuantity = (_selectedQuantity + amount).clamp(1, maxQuantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFFFFFFF);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showImageDialog(context, widget.imageUrl),
                child: Hero(
                  tag: 'image-${widget.itemId}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorders.radiusLG),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: S3Image(
                        imageKey: widget.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.quantity > 1)
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoadingQuantity
                          ? AppColors.primary.withValues(alpha: 0.9)
                          : (_availableQuantity != null &&
                                  _availableQuantity! <= 0
                              ? Colors.red.withValues(alpha: 0.9)
                              : AppColors.primary.withValues(alpha: 0.9)),
                      borderRadius: AppBorders.borderRadiusMD,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _availableQuantity != null && _availableQuantity! <= 0
                              ? Icons.cancel
                              : Icons.inventory_2,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _isLoadingQuantity
                              ? 'Loading...'
                              : (_availableQuantity != null &&
                                      _availableQuantity! <= 0
                                  ? 'Out of Stock'
                                  : '${_availableQuantity ?? widget.quantity} available'),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: AppTypography.bold,
                            fontSize: AppTypography.fontSizeSM,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: AppTypography.bold,
                              fontSize: AppTypography.fontSizeXL,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Price: ₹${widget.price}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppTypography.fontSizeMD,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Location: ${widget.city}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppTypography.fontSizeMD,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => _showDetailsDialog(
                          context,
                          widget.title,
                          widget.description,
                          widget.categories,
                          widget.itemTypes,
                          widget.price,
                          widget.quantity),
                      tooltip: 'View Details',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (widget.categories.isNotEmpty) ...[
                  const Text(
                    'Categories:',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeSM,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Chip(
                            label: Text(category),
                            backgroundColor: _getCategoryColor(category),
                            labelStyle: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: AppTypography.bold,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (widget.itemTypes.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Item Types:',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeSM,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.itemTypes.map((type) {
                      return Chip(
                        label: Text(type),
                        backgroundColor: AppColors.greyDark,
                        labelStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: AppTypography.bold,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeSM,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppTypography.fontSizeMD,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity selector
                    if (widget.quantity > 1 &&
                        !_isLoadingQuantity &&
                        (_availableQuantity == null || _availableQuantity! > 0))
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppBorders.borderRadiusMD,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _selectedQuantity > 1
                                  ? () => _updateQuantity(-1)
                                  : null,
                              color: AppColors.primary,
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Text(
                                '$_selectedQuantity',
                                style: const TextStyle(
                                  fontWeight: AppTypography.bold,
                                  color: AppColors.primary,
                                  fontSize: AppTypography.fontSizeLG,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _selectedQuantity <
                                      (_availableQuantity ?? widget.quantity)
                                  ? () => _updateQuantity(1)
                                  : null,
                              color: AppColors.primary,
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              constraints: const BoxConstraints(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(),
                    ElevatedButton.icon(
                      onPressed: (_isLoadingQuantity ||
                              _isAddingToCart ||
                              (_availableQuantity != null &&
                                  _availableQuantity! <= 0))
                          ? null
                          : () {
                              if (widget.sellerId == null) return;
                              _addToCart(
                                  context, widget.sellerId!, widget.itemId);
                            },
                      icon: _isAddingToCart
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : Icon(
                              (_availableQuantity != null &&
                                      _availableQuantity! <= 0)
                                  ? Icons.block
                                  : Icons.add_shopping_cart,
                              size: 18,
                            ),
                      label: Text(
                        _isAddingToCart
                            ? 'Adding...'
                            : (_isLoadingQuantity
                                ? 'Loading...'
                                : (_availableQuantity != null &&
                                        _availableQuantity! <= 0
                                    ? 'Out of Stock'
                                    : 'Add to Cart')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_availableQuantity != null &&
                                _availableQuantity! <= 0)
                            ? Colors.grey
                            : AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppBorders.borderRadiusMD,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Hero(
                  tag: 'fullscreen-${widget.itemId}',
                  child: S3Image(
                    imageKey: imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: Container(
                      width: 300,
                      height: 300,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    String title,
    String description,
    List<String> categories,
    List<String> itemTypes,
    String price,
    int quantity,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXL,
          ),
          backgroundColor: const Color(0xFFFFFFFF), // White - matches card
          child: Container(
            width: double.infinity,
            padding: AppSpacing.paddingLG,
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: AppTypography.fontSize3XL,
                                fontWeight: AppTypography.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(
                                  'Price: ₹$price',
                                  style: const TextStyle(
                                    fontSize: AppTypography.fontSizeXL,
                                    color: AppColors.info,
                                    fontWeight: AppTypography.semiBold,
                                  ),
                                ),
                                if (quantity > 1) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: AppBorders.borderRadiusSM,
                                    ),
                                    child: Text(
                                      'Quantity: $quantity',
                                      style: const TextStyle(
                                        fontSize: AppTypography.fontSizeMD,
                                        color: AppColors.primary,
                                        fontWeight: AppTypography.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeLG,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: _getCategoryColor(category),
                        labelStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.fontSizeMD,
                          fontWeight: AppTypography.medium,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Item Types',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeLG,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itemTypes.map((type) {
                      return Chip(
                        label: Text(type),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.7),
                        labelStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.fontSizeMD,
                          fontWeight: AppTypography.medium,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeLG,
                      fontWeight: AppTypography.medium,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description.isEmpty
                        ? 'No description provided'
                        : description,
                    style: const TextStyle(
                      fontSize: AppTypography.fontSizeLG,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'donate':
        return AppColors.donate;
      case 'recyclable':
        return AppColors.recyclable;
      case 'non-recyclable':
        return AppColors.nonRecyclable;
      default:
        return AppColors.grey;
    }
  }
}
