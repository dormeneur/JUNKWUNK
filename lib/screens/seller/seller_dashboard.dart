import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/image_uploader.dart';
import '../../widgets/app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'summary_page.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
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

  // Color palette
  final Color primaryColor = Color(0xFF371f97);
  final Color secondaryColor = Color(0xFFf5f5f5);

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
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    if (_selectedItemTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an item type')),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a price quote')),
      );
      return;
    }

    // Validate quantity
    if (_quantityController.text.isEmpty ||
        int.tryParse(_quantityController.text) == null ||
        int.parse(_quantityController.text) < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid quantity (minimum 1)')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to save data')),
        );
        return;
      }

      final sellerDoc =
          FirebaseFirestore.instance.collection('sellers').doc(user.uid);

      // Save seller info
      await sellerDoc.set({
        'name': user.displayName ?? "Unknown Seller",
        'email': user.email ?? "No contact info",
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Save item with additional details
      await sellerDoc.collection('items').add({
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
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active'
      });

      setState(() {
        _isSubmitting = false;
      });

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving item: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'List Your Item',
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
            icon: Icon(Icons.inventory, color: Colors.white),
            label: Text(
              'My Items',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: primaryColor.withOpacity(0.3),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Upload Item Image', Icons.image),
                SizedBox(height: 12),
                _buildImageSection(),
                SizedBox(height: 24),
                if (_imageUrl != null) ...[
                  _buildSectionTitle('Item Details', Icons.info_outline),
                  SizedBox(height: 12),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 24,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
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
                    color: primaryColor.withOpacity(0.05),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: _isUploading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryColor,
                            ),
                          ),
                        )
                      : _imageUrl != null
                          ? GestureDetector(
                              onTap: _previewImage,
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                                child: Image.network(_imageUrl!,
                                    fit: BoxFit.cover),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: primaryColor,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Upload your item image',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                ),
                if (_imageUrl != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.white, size: 20),
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
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: (_isUploading || _isSubmitting)
                    ? null
                    : _pickAndUploadImage,
                icon: Icon(Icons.photo_library),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  iconColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleField(),
          SizedBox(height: 20),
          _buildDescriptionField(),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPriceField()),
              SizedBox(width: 16),
              Expanded(child: _buildQuantityField()),
            ],
          ),
          SizedBox(height: 30),
          _buildItemTypeSelection(),
          SizedBox(height: 30),
          _buildCategoryTitle(),
          SizedBox(height: 16),
          _buildCategories(),
          SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Row(
      children: [
        Icon(Icons.category, color: primaryColor, size: 22),
        SizedBox(width: 8),
        Text(
          'Select Categories:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      enabled: !_isSubmitting,
      decoration: InputDecoration(
        labelText: 'Title',
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIcon: Icon(Icons.title, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      enabled: !_isSubmitting,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 64),
          child: Icon(Icons.description, color: primaryColor.withOpacity(0.7)),
        ),
        filled: true,
        fillColor: primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Price(₹)',
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIcon:
            Icon(Icons.currency_rupee, color: primaryColor.withOpacity(0.7)),
        filled: true,
        fillColor: primaryColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity',
        labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: primaryColor.withOpacity(0.05),
        prefixIcon: Icon(Icons.inventory_2_outlined,
            color: primaryColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildItemTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style, color: primaryColor, size: 22),
              SizedBox(width: 8),
              Text(
                'Item Types:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : primaryColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      if (isSelected) SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedItemTypes.contains('Other')) ...[
            SizedBox(height: 16),
            TextField(
              controller: _customTypeController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'Specify Additional Item Type',
                labelStyle: TextStyle(color: primaryColor.withOpacity(0.8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                filled: true,
                prefixIcon: Icon(Icons.add_circle_outline,
                    color: primaryColor.withOpacity(0.7)),
                fillColor: Colors.white,
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
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _availableCategories.map((category) {
          final isSelected = _selectedCategories.contains(category);

          // Choose appropriate icons and colors based on category
          IconData categoryIcon;
          Color categoryColor;

          switch (category) {
            case 'Donate':
              categoryIcon = Icons.volunteer_activism;
              categoryColor = Colors.green[600]!;
              break;
            case 'Recyclable':
              categoryIcon = Icons.recycling;
              categoryColor = Colors.blue[600]!;
              break;
            case 'Non-Recyclable':
              categoryIcon = Icons.delete_outline;
              categoryColor = Colors.orange[600]!;
              break;
            default:
              categoryIcon = Icons.category;
              categoryColor = primaryColor;
          }

          return InkWell(
            onTap: _isSubmitting ? null : () => _toggleCategory(category),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? categoryColor : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isSelected ? categoryColor : Colors.grey.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 5,
                          offset: Offset(0, 2),
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
                    color: isSelected ? Colors.white : categoryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
    return Container(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _saveToFirebase,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          shadowColor: Colors.green.withOpacity(0.5),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Submitting...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
