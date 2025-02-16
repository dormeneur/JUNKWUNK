import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SummaryPage extends StatelessWidget {
  final String? imageUrl;
  final List<String>? selectedCategories;
  final String? description;
  final List<String>? itemTypes;
  final String? price;
  final bool isViewMode;
  final String? title;

  // Custom color palette
  static const Color primaryColor = Color(0xFF371F97);
  static const Color secondaryColor = Color(0xFFEEE8F6);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);

  SummaryPage.viewAll()
      : imageUrl = null,
        selectedCategories = null,
        description = null,
        itemTypes = null,
        price = null,
        title = null,
        isViewMode = true;

  const SummaryPage({
    Key? key,
    required this.imageUrl,
    required this.selectedCategories,
    required this.description,
    required this.itemTypes,
    required this.price,
    required this.title,
  })  : isViewMode = false,
        super(key: key);

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
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: whiteColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .collection('items')
          .doc(itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item deleted successfully'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: Text(
          isViewMode ? 'Your Items' : 'Item Summary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.5),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: isViewMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              label: Text(
                'Add More Items',
                style: TextStyle(color: Colors.white),
              ),
              icon: Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
              ),
              backgroundColor: primaryColor,
            ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isViewMode && imageUrl != null) _buildItemPreview(context),
            _buildAllItemsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreview(BuildContext context) {
    if (imageUrl == null || selectedCategories == null) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: blackColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showImageDialog(context, imageUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'preview-$imageUrl',
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recently Added Item',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (title != null && title!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: blackColor,
                    ),
                  ),
                ],
                if (itemTypes != null && itemTypes!.isNotEmpty) ...[
                  Text(
                    'Types: ${itemTypes!.join(", ")}',
                    style: TextStyle(
                      fontSize: 16,
                      color: blackColor.withOpacity(0.8),
                    ),
                  ),
                ],
                if (price != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Price: ₹$price',
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: 12),
                Text(
                  'Categories:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: blackColor.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedCategories!.map((category) {
                    return Chip(
                      label: Text(category),
                      backgroundColor: _getCategoryColor(category),
                      labelStyle: TextStyle(color: whiteColor),
                    );
                  }).toList(),
                ),
                if (description?.isNotEmpty ?? false) ...[
                  SizedBox(height: 12),
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: blackColor.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description!,
                    style: TextStyle(
                      color: blackColor.withOpacity(0.8),
                    ),
                  ),
                ],
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 16, color: blackColor.withOpacity(0.6)),
                    SizedBox(width: 4),
                    Text(
                      'Added ${_getFormattedDate()}',
                      style: TextStyle(
                        color: blackColor.withOpacity(0.6),
                        fontSize: 14,
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

  Widget _buildAllItemsList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Your Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sellers')
              .doc(user.uid)
              .collection('items')
              .orderBy('timestamp', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final items = snapshot.data?.docs ?? [];
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No items found',
                    style: TextStyle(color: blackColor.withOpacity(0.7)),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index].data() as Map<String, dynamic>;
                final itemId = items[index].id;
                final categories = List<String>.from(item['categories'] ?? []);
                final itemImageUrl = item['imageUrl'] as String;
                final itemTypes = List<String>.from(item['itemTypes'] ?? []);
                final itemDescription = item['description'] as String? ?? '';
                final itemPrice = item['price']?.toString() ?? '';
                final itemTitle = item['title'] as String? ?? '';

                return Dismissible(
                  key: Key(itemId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: Icon(Icons.delete, color: whiteColor),
                  ),
                  onDismissed: (direction) {
                    _deleteItem(context, itemId);
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: blackColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageDialog(context, itemImageUrl),
                          child: Hero(
                            tag: 'item-$itemImageUrl',
                            child: ClipRRect(
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                              child: Image.network(
                                itemImageUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (itemTitle.isNotEmpty) ...[
                                  Text(
                                    itemTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                ],
                                Text(
                                  'Type: $itemTypes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: blackColor,
                                  ),
                                ),
                                if (itemPrice.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'Price: ₹$itemPrice',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: categories.map((category) {
                                    return Chip(
                                      label: Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: whiteColor,
                                        ),
                                      ),
                                      backgroundColor:
                                          _getCategoryColor(category),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                                if (itemDescription.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    itemDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: blackColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                                if (item['timestamp'] != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    _getFormattedDate(
                                        item['timestamp'] as Timestamp),
                                    style: TextStyle(
                                      color: blackColor.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        SizedBox(height: 80),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'donate':
        return primaryColor.withOpacity(0.8);
      case 'recyclable':
        return primaryColor;
      case 'non-recyclable':
        return primaryColor.withOpacity(0.6);
      default:
        return blackColor.withOpacity(0.6);
    }
  }

  String _getFormattedDate([Timestamp? timestamp]) {
    final date = timestamp?.toDate() ?? DateTime.now();
    return '${date.day}/${date.month}/${date.year}';
  }
}
