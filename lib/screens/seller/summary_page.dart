import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_bar.dart';

class SummaryPage extends StatelessWidget {
  final String? imageUrl;
  final List<String>? selectedCategories;
  final String? description;
  final List<String>? itemTypes;
  final String? price;
  final String? quantity;
  final bool isViewMode;
  final String? title;

  // Custom color palette
  static const Color primaryColor = Color(0xFF371F97);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF000000);
  static const Color greyColor = Color(0xFFF5F5F5);

  const SummaryPage.viewAll({super.key})
      : imageUrl = null,
        selectedCategories = null,
        description = null,
        itemTypes = null,
        price = null,
        quantity = null,
        title = null,
        isViewMode = true;

  const SummaryPage({
    super.key,
    required this.imageUrl,
    required this.selectedCategories,
    required this.description,
    required this.itemTypes,
    required this.price,
    required this.title,
    this.quantity = "1",
  })  : isViewMode = false;


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
      backgroundColor: whiteColor,
      appBar: AppBarWidget(
        title: 'Your Items',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
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
      body: Container(
        decoration: BoxDecoration(
          color: whiteColor,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAllItemsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllItemsList(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text('Not logged in'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .collection('items')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: primaryColor.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You have not listed any items yet.',
                    style: TextStyle(color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final List<DocumentSnapshot> activeItems = [];
        final List<DocumentSnapshot> soldItems = [];

        // Separate active and sold items
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'sold') {
            soldItems.add(doc);
          } else {
            activeItems.add(doc);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeItems.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          color: primaryColor, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Active Listings (${activeItems.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: activeItems.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(context, activeItems[index]);
                },
              ),
            ],
            if (soldItems.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green[700], size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sold Items (${soldItems.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: soldItems.length,
                itemBuilder: (context, index) {
                  return _buildItemCard(context, soldItems[index]);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemTitle = data['title'] ?? 'Untitled Item';
    final itemDescription = data['description'] ?? '';
    final itemImageUrl = data['imageUrl'] ?? '';
    final itemCategories = List<String>.from(data['categories'] ?? []);
    final itemPrice = data['price']?.toString() ?? '0';
    final itemQuantity = data['quantity']?.toString() ?? '1';
    final isItemSold = data['status'] == 'sold';
    final soldTimestamp = data['soldTimestamp'] as Timestamp?;

    // Format the sold timestamp
    String soldDate = '';
    if (soldTimestamp != null) {
      final dateTime = soldTimestamp.toDate();
      soldDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    itemImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: greyColor,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isItemSold)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'SOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(16),
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
                            itemTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isItemSold ? Colors.grey[700] : primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 16,
                                color: isItemSold
                                    ? Colors.grey
                                    : Colors.green[700],
                              ),
                              SizedBox(width: 4),
                              Text(
                                '₹$itemPrice',
                                style: TextStyle(
                                  color: isItemSold
                                      ? Colors.grey[600]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (itemQuantity != "1" && !isItemSold) ...[
                                SizedBox(width: 16),
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Qty: $itemQuantity',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (isItemSold && soldDate.isNotEmpty) ...[
                                SizedBox(width: 16),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sold: $soldDate',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!isItemSold)
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteItem(context, doc.id),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  itemDescription,
                  style: TextStyle(
                    color: isItemSold ? Colors.grey[600] : Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: itemCategories.map((category) {
                    return isItemSold
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : _buildCategoryChip(category);
                  }).toList(),
                ),
                if (!isItemSold) ...[
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Add edit functionality
                        },
                        icon: Icon(Icons.edit, color: primaryColor),
                        label:
                            Text('Edit', style: TextStyle(color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    // Icons and colors based on category type
    IconData categoryIcon;
    Color categoryColor;

    switch (category.toLowerCase()) {
      case 'donate':
        categoryIcon = Icons.volunteer_activism;
        categoryColor = Colors.green[600]!;
        break;
      case 'recyclable':
        categoryIcon = Icons.recycling;
        categoryColor = Colors.blue[600]!;
        break;
      case 'non-recyclable':
        categoryIcon = Icons.delete_outline;
        categoryColor = Colors.orange[600]!;
        break;
      default:
        categoryIcon = Icons.category;
        categoryColor = Colors.grey[600]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryIcon,
            color: categoryColor,
            size: 14,
          ),
          SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: categoryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


}
