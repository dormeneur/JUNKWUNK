import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          backgroundColor: Color(0xFF371f97),
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
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF371f97)),
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
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF371f97).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF371f97),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price: ₹${widget.price}',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
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
                const SizedBox(height: 8),
                if (widget.categories.isNotEmpty) ...[
                  const Text(
                    'Categories:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.categories.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: _getCategoryColor(category),
                        labelStyle:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
                if (widget.itemTypes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Item Types:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.itemTypes.map((type) {
                      return Chip(
                        label: Text(type),
                        backgroundColor: Colors.purple[300],
                        labelStyle:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  widget.description,
                  style: TextStyle(color: Colors.grey[800]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity selector
                    if (widget.quantity > 1)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFEEE8F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: 18),
                              onPressed: _selectedQuantity > 1
                                  ? () => _updateQuantity(-1)
                                  : null,
                              color: Color(0xFF371f97),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
                              splashRadius: 20,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '$_selectedQuantity',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF371f97),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 18),
                              onPressed: _selectedQuantity < widget.quantity
                                  ? () => _updateQuantity(1)
                                  : null,
                              color: Color(0xFF371f97),
                              padding: EdgeInsets.all(4),
                              constraints: BoxConstraints(),
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
                        backgroundColor: Color(0xFF371f97),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                  color: Colors.black.withOpacity(0.5),
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF371f97),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Price: ₹$price',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (quantity > 1) ...[
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF371f97).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Quantity: $quantity',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF371f97),
                                        fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 16),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return Chip(
                        label: Text(category),
                        backgroundColor: _getCategoryColor(category),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Item Types',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itemTypes.map((type) {
                      return Chip(
                        label: Text(type),
                        backgroundColor: Colors.purple[300],
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? 'No description provided'
                        : description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
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
        return Colors.green[600]!;
      case 'recyclable':
        return Colors.blue[600]!;
      case 'non-recyclable':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
