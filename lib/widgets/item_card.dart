import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/design_constants.dart';

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
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  int _selectedQuantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedQuantity = 1;
  }

  Future<void> _addToCart(
      BuildContext context, String sellerId, String itemId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_selectedQuantity item(s) to cart!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusMD,
          ),
        ),
      );
      widget.onCartUpdated?.call();
    }
  }

  void _updateQuantity(int amount) {
    setState(() {
      _selectedQuantity =
          (_selectedQuantity + amount).clamp(1, widget.quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              strokeWidth: 3,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                size: 50, color: Colors.grey),
                          );
                        },
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
                      color: AppColors.primary.withValues(alpha: 0.9),
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
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${widget.quantity} available',
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
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.categories.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: _getCategoryColor(category),
                        labelStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.fontSizeSM,
                          fontWeight: AppTypography.medium,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.7),
                        labelStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.fontSizeSM,
                          fontWeight: AppTypography.medium,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
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
                    if (widget.quantity > 1)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: AppBorders.borderRadiusMD,
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
                                horizontal: AppSpacing.xs,
                              ),
                              child: Text(
                                '$_selectedQuantity',
                                style: const TextStyle(
                                  fontWeight: AppTypography.bold,
                                  color: AppColors.primary,
                                  fontSize: AppTypography.fontSizeMD,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _selectedQuantity < widget.quantity
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
                      onPressed: () {
                        if (widget.sellerId == null) return;
                        _addToCart(context, widget.sellerId!, widget.itemId);
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported,
                            size: 50, color: Colors.grey),
                      );
                    },
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
                                      color: AppColors.primary.withValues(alpha: 0.1),
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.7),
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
