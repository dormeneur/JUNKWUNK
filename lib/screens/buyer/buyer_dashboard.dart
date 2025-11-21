import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../utils/design_constants.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/item_card.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => BuyerDashboardState();
}

class BuyerDashboardState extends State<BuyerDashboard>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> cartItemCount = ValueNotifier<int>(0);
  final ValueNotifier<int> refreshTrigger = ValueNotifier<int>(0);
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    loadCartItemCount();
  }

  @override
  void dispose() {
    cartItemCount.dispose();
    refreshTrigger.dispose();
    super.dispose();
  }

  Future<void> loadCartItemCount() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('cognito_user_id');
    if (userId != null) {
      final cartItems = await ApiService.getCart();

      // Calculate total items considering quantities
      int totalItems = 0;
      for (var item in cartItems) {
        final quantity = item['quantity'] ?? 1;
        totalItems += (quantity is int ? quantity : (quantity as num).toInt());
      }

      // Update ValueNotifier instead of calling setState
      cartItemCount.value = totalItems;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor:
          AppColors.backgroundLight, // Light green background (#F1F8F4)
      appBar: AppBarWidget(
        title: 'Browse Products',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white, // White on colored background
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter dropdown - compact and clean
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filter:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppTypography.fontSizeMD,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedFilter,
                      isExpanded: true,
                      icon:
                          Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppTypography.fontSizeMD,
                        fontWeight: AppTypography.medium,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Items'),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'Donate',
                          child: Row(
                            children: [
                              Icon(Icons.favorite_rounded,
                                  size: 16, color: AppColors.donate),
                              const SizedBox(width: 8),
                              Text('Donate'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'Recyclable',
                          child: Row(
                            children: [
                              Icon(Icons.eco_rounded,
                                  size: 16, color: AppColors.recyclable),
                              const SizedBox(width: 8),
                              Text('Recyclable'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'Non-Recyclable',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded,
                                  size: 16, color: AppColors.nonRecyclable),
                              const SizedBox(width: 8),
                              Text('Non-Recyclable'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildItemsView(_selectedFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsView(String? filterValue) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh cart count and items
        await loadCartItemCount();
        setState(() {}); // Trigger rebuild
        // Small delay for smooth UX
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: AppColors.primary, // Light green loading indicator (#81C784)
      backgroundColor: AppColors.white,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadItems(filterValue),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary), // Light green (#81C784)
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Text(
                          'No items available',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Check back later for new products',
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ItemCard(
                  key: ValueKey('${item['itemId']}-${refreshTrigger.value}'),
                  itemId: item['itemId'],
                  sellerId: item['sellerId'],
                  imageUrl: item['imageUrl'] ?? '',
                  title: item['title'] ?? 'Untitled Item',
                  description: item['description'] ?? 'No description',
                  categories: List<String>.from(item['categories'] ?? []),
                  itemTypes: List<String>.from(item['itemTypes'] ?? []),
                  price: ((item['price'] ?? 0).toDouble()).toString(),
                  quantity: ((item['quantity'] ?? 1) is int
                      ? item['quantity']
                      : (item['quantity'] as num).toInt()),
                  city: item['city'] ?? 'Unknown Location',
                  onCartUpdated: loadCartItemCount,
                  refreshTrigger: refreshTrigger,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadItems(String? filterValue) async {
    try {
      // Call API to get items with optional category filter
      return await ApiService.getItems(
        category: filterValue,
        status: 'active',
      );
    } catch (e) {
      debugPrint('Error loading items: $e');
      return [];
    }
  }
}
