import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../utils/custom_toast.dart';
import '../../utils/design_constants.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/s3_image.dart';
import 'summary_page.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  SellerDashboardState createState() => SellerDashboardState();
}

class SellerDashboardState extends State<SellerDashboard> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _quantityController = TextEditingController(text: "1");

  final List<String> _availableCategories = [
    'Donate',
    'Recyclable',
    'Non-Recyclable'
  ];

  final List<String> _itemTypes = [
    'Newspaper',
    'Plastics',
    'Glass',
    'Metal',
    'Electronics',
    'Cardboard',
    'Textiles',
    'Other'
  ];

  final List<String> _selectedItemTypes = [];
  final List<String> _selectedCategories = [];

  // Using design system colors

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _customTypeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String? uploadedUrl = await ImageUploader.pickAndUploadImage(context);
      if (uploadedUrl != null) {
        setState(() {
          _imageUrl = uploadedUrl;
        });
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _previewImage() {
    if (_imageUrl == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: S3Image(
                    imageKey: _imageUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.white, // White on dark background
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveItem() async {
    if (_imageUrl == null) {
      CustomToast.showError(context, 'Please upload an image first');
      return;
    }

    if (_selectedCategories.isEmpty) {
      CustomToast.showError(context, 'Please select at least one category');
      return;
    }

    if (_selectedItemTypes.isEmpty) {
      CustomToast.showError(context, 'Please select an item type');
      return;
    }

    if (_priceController.text.isEmpty) {
      CustomToast.showError(context, 'Please enter a price quote');
      return;
    }

    // Validate quantity
    if (_quantityController.text.isEmpty ||
        int.tryParse(_quantityController.text) == null ||
        int.parse(_quantityController.text) < 1) {
      CustomToast.showError(
          context, 'Please enter a valid quantity (minimum 1)');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user ID from SharedPreferences (Cognito user)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('cognito_user_id');

      if (userId == null) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          CustomToast.showError(context, 'You must be logged in to save data');
        }
        return;
      }

      // Fetch user's coordinates and name from API
      final userData = await ApiService.getUser(userId);

      String? cityName;

      if (userData != null && userData['coordinates'] != null) {
        final coordinates = userData['coordinates'];
        final lat = coordinates['lat'];
        final lng = coordinates['lng'];

        try {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            cityName = placemarks.first.locality;
          }
        } catch (e) {
          debugPrint('Error getting city name: $e');
        }
      }

      // Create item via API
      final itemData = {
        'imageUrl': _imageUrl,
        'categories': _selectedCategories,
        'itemTypes': [
          ..._selectedItemTypes,
          if (_selectedItemTypes.contains('Other')) _customTypeController.text
        ],
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'quantity': int.parse(_quantityController.text),
        'status': 'active',
        'city': cityName ?? 'Unknown',
      };

      final createdItem = await ApiService.createItem(itemData);

      if (createdItem == null) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          CustomToast.showError(context, 'Failed to create item');
        }
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryPage(
            imageUrl: _imageUrl!,
            selectedCategories: List<String>.from(_selectedCategories),
            title: _titleController.text,
            description: _descriptionController.text,
            itemTypes: _selectedItemTypes.contains('Other')
                ? [..._selectedItemTypes, _customTypeController.text]
                : List<String>.from(_selectedItemTypes),
            price: _priceController.text,
            quantity: _quantityController.text,
          ),
        ),
      );

      _resetForm();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        CustomToast.showError(context, 'Error saving item: $e');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _imageUrl = null;
      _selectedCategories.clear();
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _customTypeController.clear();
      _selectedItemTypes.clear();
      _quantityController.text = "1";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBarWidget(
        title: 'List Your Item',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white, // White on colored background
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.scaffoldBackground,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Upload Item Image', Icons.image_rounded),
                const SizedBox(height: AppSpacing.md),
                _buildImageSection(),
                const SizedBox(height: AppSpacing.xl),
                if (_imageUrl != null) ...[
                  _buildSectionHeader('Item Details', Icons.info_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildFormSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorders.radiusLG),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _imageUrl == null
                        ? AppColors.primaryLightest
                        : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: _isUploading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Uploading...',
                                style: TextStyle(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _imageUrl != null
                          ? GestureDetector(
                              onTap: _previewImage,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: S3Image(
                                  imageKey: _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: (_isUploading || _isSubmitting)
                                  ? null
                                  : _pickAndUploadImage,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_photo_alternate_rounded,
                                        size: 40,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tap to upload image',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                ),
                if (_imageUrl != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _isSubmitting ? null : _pickAndUploadImage,
                        customBorder: const CircleBorder(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorders.radiusLG),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleField(),
          const SizedBox(height: AppSpacing.md),
          _buildDescriptionField(),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPriceField()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildQuantityField()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildItemTypeSelection(),
          const SizedBox(height: AppSpacing.lg),
          _buildCategoryTitle(),
          const SizedBox(height: AppSpacing.sm),
          _buildCategories(),
          const SizedBox(height: AppSpacing.lg),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.category_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Select Categories',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      enabled: !_isSubmitting,
      decoration: AppInputs.inputDecoration(
        label: 'Title',
        prefixIcon: Icon(
          Icons.title,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      enabled: !_isSubmitting,
      maxLines: 4,
      decoration: AppInputs.inputDecoration(
        label: 'Description',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Icon(
            Icons.description,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      enabled: !_isSubmitting,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: AppInputs.inputDecoration(
        label: 'Price',
        prefixIcon: const Icon(
          Icons.currency_rupee,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.number,
      decoration: AppInputs.inputDecoration(
        label: 'Quantity',
        hint: 'Enter quantity',
        prefixIcon: const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildItemTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorders.radiusMD),
        color: AppColors.primaryLightest,
        border: Border.all(
          color: AppColors.borderLight,
          width: AppBorders.borderWidthThin,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Item Types',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _itemTypes.map((type) {
              final isSelected = _selectedItemTypes.contains(type);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _selectedItemTypes.remove(type);
                              if (type == 'Other') {
                                _customTypeController.clear();
                              }
                            } else {
                              _selectedItemTypes.add(type);
                            }
                          });
                        },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.borderLight,
                        width: isSelected
                            ? AppBorders.borderWidthMedium
                            : AppBorders.borderWidthThin,
                      ),
                      boxShadow: isSelected ? AppShadows.shadowPrimary : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        if (isSelected) const SizedBox(width: 6),
                        Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedItemTypes.contains('Other')) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _customTypeController,
              enabled: !_isSubmitting,
              decoration: AppInputs.inputDecoration(
                label: 'Specify Item Type',
                prefixIcon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _availableCategories.map((category) {
        final isSelected = _selectedCategories.contains(category);

        // Choose appropriate icons and colors based on category
        IconData categoryIcon;
        Color categoryColor;

        switch (category) {
          case 'Donate':
            categoryIcon = Icons.favorite_rounded;
            categoryColor = AppColors.donate;
            break;
          case 'Recyclable':
            categoryIcon = Icons.eco_rounded;
            categoryColor = AppColors.recyclable;
            break;
          case 'Non-Recyclable':
            categoryIcon = Icons.delete_sweep_rounded;
            categoryColor = AppColors.nonRecyclable;
            break;
          default:
            categoryIcon = Icons.category_rounded;
            categoryColor = AppColors.primary;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSubmitting ? null : () => _toggleCategory(category),
            borderRadius: BorderRadius.circular(AppBorders.radiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? categoryColor : AppColors.white,
                borderRadius: BorderRadius.circular(AppBorders.radiusMD),
                border: Border.all(
                  color: isSelected ? categoryColor : AppColors.borderLight,
                  width: isSelected
                      ? AppBorders.borderWidthMedium
                      : AppBorders.borderWidthThin,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcon,
                    size: 20,
                    color: isSelected ? AppColors.white : categoryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBorders.radiusMD),
        boxShadow: _isSubmitting
            ? null
            : [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          disabledBackgroundColor:
              AppColors.grey.withValues(alpha: AppButtons.disabledOpacity),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorders.radiusMD),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Submitting...',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Submit Item',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
