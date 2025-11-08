import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/colors.dart' as colors;
import '../../utils/custom_toast.dart';
import '../../utils/design_constants.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/s3_image.dart';
import '../../services/api_service.dart';
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
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveToFirebase() async {
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
      backgroundColor: colors.AppColors.scaffoldBackground,
      appBar: AppBarWidget(
        title: 'List Your Item',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryPage.viewAll(),
                ),
              );
            },
            icon: const Icon(Icons.inventory, color: AppColors.white),
            label: const Text(
              'My Items',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: AppTypography.bold,
                fontSize: AppTypography.fontSizeMD,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorders.borderRadiusXL,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: colors.AppColors.scaffoldBackground,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Upload Item Image', Icons.image),
                const SizedBox(height: AppSpacing.md),
                _buildImageSection(),
                const SizedBox(height: AppSpacing.lg),
                if (_imageUrl != null) ...[
                  _buildSectionTitle('Item Details', Icons.info_outline),
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppBorders.borderRadiusMD,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: AppBorders.borderWidthThin,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTypography.fontSizeXL,
              fontWeight: AppTypography.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // Keep cards white for contrast
        borderRadius: AppBorders.borderRadiusXL,
        boxShadow: AppShadows.shadow2,
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
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppBorders.radiusXL),
                    ),
                  ),
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      : _imageUrl != null
                          ? GestureDetector(
                              onTap: _previewImage,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppBorders.radiusXL),
                                ),
                                child: S3Image(
                                  imageKey: _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'Upload your item image',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: AppTypography.fontSizeLG,
                                    fontWeight: AppTypography.medium,
                                  ),
                                ),
                              ],
                            ),
                ),
                if (_imageUrl != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.white,
                          size: 20,
                        ),
                        onPressed: _isSubmitting ? null : _pickAndUploadImage,
                        tooltip: 'Change Image',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_imageUrl == null)
            Padding(
              padding: AppSpacing.paddingMD,
              child: ElevatedButton.icon(
                onPressed: (_isUploading || _isSubmitting)
                    ? null
                    : _pickAndUploadImage,
                icon: const Icon(Icons.photo_library),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Choose from Gallery',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: AppTypography.fontSizeLG,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  iconColor: AppColors.white,
                  minimumSize: const Size(double.infinity, AppButtons.heightLG),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.borderRadiusMD,
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Keep form cards white for contrast
        borderRadius: AppBorders.borderRadiusXL,
        boxShadow: AppShadows.shadow2,
      ),
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleField(),
          const SizedBox(height: AppSpacing.lg),
          _buildDescriptionField(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPriceField()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildQuantityField()),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildItemTypeSelection(),
          const SizedBox(height: AppSpacing.xl),
          _buildCategoryTitle(),
          const SizedBox(height: AppSpacing.md),
          _buildCategories(),
          const SizedBox(height: AppSpacing.xl),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Row(
      children: [
        const Icon(
          Icons.category,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'Select Categories:',
          style: TextStyle(
            fontSize: AppTypography.fontSizeXL,
            fontWeight: AppTypography.bold,
            color: AppColors.primary,
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
        borderRadius: AppBorders.borderRadiusLG,
        color: AppColors.white,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: AppBorders.borderWidthThin,
        ),
        boxShadow: AppShadows.shadow1,
      ),
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.style,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'Item Types:',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXL,
                  fontWeight: AppTypography.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _itemTypes.map((type) {
              final isSelected = _selectedItemTypes.contains(type);
              return InkWell(
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
                borderRadius: AppBorders.borderRadiusXL,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
                    borderRadius: AppBorders.borderRadiusXL,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.3),
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
                          Icons.check_circle,
                          color: AppColors.white,
                          size: 16,
                        ),
                      if (isSelected) const SizedBox(width: AppSpacing.xs),
                      Text(
                        type,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? AppTypography.bold
                              : AppTypography.regular,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedItemTypes.contains('Other')) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _customTypeController,
              enabled: !_isSubmitting,
              decoration: AppInputs.inputDecoration(
                label: 'Specify Additional Item Type',
                prefixIcon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorders.borderRadiusLG,
        color: AppColors.white,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: AppBorders.borderWidthThin,
        ),
        boxShadow: AppShadows.shadow1,
      ),
      padding: AppSpacing.paddingMD,
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: _availableCategories.map((category) {
          final isSelected = _selectedCategories.contains(category);

          // Choose appropriate icons and colors based on category
          IconData categoryIcon;
          Color categoryColor;

          switch (category) {
            case 'Donate':
              categoryIcon = Icons.volunteer_activism;
              categoryColor = AppColors.donate;
              break;
            case 'Recyclable':
              categoryIcon = Icons.recycling;
              categoryColor = AppColors.recyclable;
              break;
            case 'Non-Recyclable':
              categoryIcon = Icons.delete_outline;
              categoryColor = AppColors.nonRecyclable;
              break;
            default:
              categoryIcon = Icons.category;
              categoryColor = AppColors.primary;
          }

          return InkWell(
            onTap: _isSubmitting ? null : () => _toggleCategory(category),
            borderRadius: AppBorders.borderRadiusXL,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? categoryColor : AppColors.white,
                borderRadius: AppBorders.borderRadiusXL,
                border: Border.all(
                  color: isSelected
                      ? categoryColor
                      : AppColors.grey.withValues(alpha: 0.5),
                  width: isSelected
                      ? AppBorders.borderWidthMedium
                      : AppBorders.borderWidthThin,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    categoryIcon,
                    size: 18,
                    color: isSelected ? AppColors.white : categoryColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    category,
                    style: TextStyle(
                      color:
                          isSelected ? AppColors.white : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? AppTypography.bold
                          : AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: AppButtons.heightLG,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveToFirebase,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusLG,
          ),
          elevation: 2,
          shadowColor: AppColors.success.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    'Submitting...',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeXL,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeXL,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
