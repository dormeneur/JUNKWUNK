import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/image_uploader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'summary_page.dart';

class SellerDashboard extends StatefulWidget {
  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  String? _imageUrl;
  bool _isUploading = false;
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _customTypeController = TextEditingController();

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

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _customTypeController.dispose();
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
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active'
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
          ),
        ),
      );

      _resetForm();
    } catch (e) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List Your Item',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF381F97),
        elevation: 12,
        shadowColor: Colors.black87,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.inventory, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SummaryPage.viewAll(),
                ),
              );
            },
            tooltip: 'View Your Items',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF381F97).withOpacity(0.1),
              Color(0xFF512CB0).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                SizedBox(height: 24),
                if (_imageUrl != null) ...[
                  _buildFormSection(),
                ],
              ],
            ),
          ),
        ),
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
            color: Color(0xFF381F97).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF381F97).withOpacity(0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _isUploading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF381F97),
                          ),
                        ),
                      )
                    : _imageUrl != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(_imageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Color(0xFF381F97),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Upload your item image',
                                style: TextStyle(
                                  color: Color(0xFF381F97),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          if (_imageUrl == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: Icon(Icons.photo_library),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF381F97),
                  iconColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Color(0xFF381F97).withOpacity(0.3),
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
            color: Color(0xFF381F97).withOpacity(0.1),
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
          _buildPriceField(),
          SizedBox(height: 30),
          _buildItemTypeSelection(),
          SizedBox(height: 30),
          Text(
            'Select Categories:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF381F97),
            ),
          ),
          SizedBox(height: 16),
          _buildCategories(),
          SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title',
        labelStyle: TextStyle(color: Color(0xFF512CB0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF381F97).withOpacity(0.05),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: TextStyle(color: Color(0xFF512CB0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF381F97).withOpacity(0.05),
      ),
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: _priceController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Price Quote (₹)',
        labelStyle: TextStyle(color: Color(0xFF512CB0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF381F97), width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF381F97).withOpacity(0.05),
      ),
    );
  }

  Widget _buildItemTypeSelection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        border: Border.all(color: Color(0xFF381F97).withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Types (Select all that apply):',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF381F97),
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _itemTypes.map((type) {
              final isSelected = _selectedItemTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (_) {
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
                backgroundColor: Color(0xFF381F97).withOpacity(0.1),
                selectedColor: Color(0xFF512CB0).withOpacity(0.2),
                checkmarkColor: Color(0xFF381F97),
                labelStyle: TextStyle(
                  color: isSelected ? Color(0xFF381F97) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          if (_selectedItemTypes.contains('Other')) ...[
            SizedBox(height: 16),
            TextField(
              controller: _customTypeController,
              decoration: InputDecoration(
                labelText: 'Specify Additional Item Type',
                labelStyle: TextStyle(color: Color(0xFF512CB0)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF381F97)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF381F97), width: 2),
                ),
                filled: true,
                fillColor: Color(0xFF381F97).withOpacity(0.05),
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
        border: Border.all(color: Color(0xFF381F97).withOpacity(0.2)),
      ),
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _availableCategories.map((category) {
          final isSelected = _selectedCategories.contains(category);
          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (_) => _toggleCategory(category),
            backgroundColor: Color(0xFF381F97).withOpacity(0.1),
            selectedColor: Color(0xFF512CB0).withOpacity(0.2),
            checkmarkColor: Color(0xFF381F97),
            labelStyle: TextStyle(
              color: isSelected ? Color(0xFF381F97) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
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
        onPressed: _saveToFirebase,
        child: Row(
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
      ),
    );
  }
}
