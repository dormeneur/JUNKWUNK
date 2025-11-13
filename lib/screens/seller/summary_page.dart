import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/colors.dart' as colors;
import '../../utils/custom_toast.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/s3_image.dart';
import '../../services/api_service.dart';

class SummaryPage extends StatefulWidget {
  final String? imageUrl;
  final List<String>? selectedCategories;
  final String? description;
  final List<String>? itemTypes;
  final String? price;
  final String? quantity;
  final bool isViewMode;
  final String? title;

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
  }) : isViewMode = false;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  // Use centralized colors from colors.dart
  static const Color primaryColor = colors.AppColors.primaryColor;
  static const Color backgroundColor = colors.AppColors.scaffoldBackground;

  Future<void> _deleteItem(BuildContext context, String itemId) async {
    try {
      await ApiService.deleteItem(itemId);
      if (context.mounted) {
        CustomToast.showSuccess(context, 'Item deleted successfully');
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.showError(context, 'Error deleting item: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('cognito_user_id');
    if (userId == null) return [];

    final items = await ApiService.getItems(sellerId: userId);
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Trigger rebuild to reload items
        },
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAllItemsList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllItemsList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadItems(),
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

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: primaryColor.withValues(alpha: 0.3),
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

        final List<Map<String, dynamic>> activeItems = [];
        final List<Map<String, dynamic>> soldItems = [];

        // Separate active and sold items
        for (var item in items) {
          if (item['status'] == 'sold') {
            soldItems.add(item);
          } else {
            activeItems.add(item);
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
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: 0.2)),
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.2)),
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

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final itemTitle = item['title'] ?? 'Untitled Item';
    final itemDescription = item['description'] ?? '';
    final itemImageUrl = item['imageUrl'] ?? '';
    final itemCategories = List<String>.from(item['categories'] ?? []);
    final itemPrice = item['price']?.toString() ?? '0';
    final itemQuantity = item['quantity']?.toString() ?? '1';
    final isItemSold = item['status'] == 'sold';
    final itemId = item['itemId'] ?? '';

    // Format the sold timestamp if exists
    String soldDate = '';
    if (item['soldTimestamp'] != null) {
      try {
        final dateTime = DateTime.parse(item['soldTimestamp']);
        soldDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        debugPrint('Error parsing soldTimestamp: $e');
      }
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
                  child: S3Image(
                    imageKey: itemImageUrl,
                    fit: BoxFit.cover,
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
                      color: Colors.black.withValues(alpha: 0.5),
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
                              color: Colors.black.withValues(alpha: 0.3),
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
                        onPressed: () => _deleteItem(context, itemId),
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
                        onPressed: () {},
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
        categoryColor = const Color(0xFF4f772d); // Fern green for Donate
        break;
      case 'recyclable':
        categoryIcon = Icons.recycling;
        categoryColor = const Color(0xFF90a955); // Moss green for Recyclable
        break;
      case 'non-recyclable':
        categoryIcon = Icons.delete_outline;
        categoryColor =
            const Color(0xFF31572c); // Hunter green for Non-recyclable
        break;
      default:
        categoryIcon = Icons.category;
        categoryColor = Colors.grey[600]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.5),
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
