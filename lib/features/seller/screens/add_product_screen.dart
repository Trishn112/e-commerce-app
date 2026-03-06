import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:premium_store/core/constants/colors.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productData; // Existing product data for editing
  final String? productId; // Firestore Document ID

  const AddProductScreen({super.key, this.productData, this.productId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  late TextEditingController _stockController;
  final TextEditingController _variantController = TextEditingController();

  String _selectedCategory = 'Electronics';
  final List<String> _categories = [
    'Electronics', 'Fashion', 'Gadgets', 'Home', 'Beauty', 'Accessories'
  ];
  List<String> _variants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.productData;
    _titleController = TextEditingController(text: p?['title'] ?? "");
    _brandController = TextEditingController(text: p?['brand'] ?? "");
    _priceController = TextEditingController(text: p?['price']?.toString() ?? "");
    _descController = TextEditingController(text: p?['description'] ?? "");
    _imageController = TextEditingController(text: p?['imageUrl'] ?? "");
    _stockController = TextEditingController(text: p?['stock']?.toString() ?? "1");
    _selectedCategory = p?['category'] ?? 'Electronics';
    _variants = List<String>.from(p?['variants'] ?? []);

    // Updates preview when text is pasted
    _imageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _stockController.dispose();
    _variantController.dispose();
    super.dispose();
  }

  void _addVariant() {
    if (_variantController.text.isNotEmpty) {
      setState(() {
        _variants.add(_variantController.text.trim());
        _variantController.clear();
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final data = {
        'sellerId': user?.uid,
        'title': _titleController.text.trim(),
        'brand': _brandController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'description': _descController.text.trim(),
        'imageUrl': _imageController.text.trim(),
        'category': _selectedCategory,
        'variants': _variants,
        'stock': int.tryParse(_stockController.text.trim()) ?? 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // CRITICAL FIX: Ensure ID is not empty for updates
      if (widget.productId != null && widget.productId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(data);
      } else {
        data['rating'] = 5.0;
        data['reviews'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId != null ? "Product updated!" : "Product listed!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.productId != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? "Edit Product" : "New Listing",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),
                    _sectionTitle("Product Details"),
                    _buildTextField(_titleController, "Title", "e.g. iPhone 15 Pro"),
                    _buildTextField(_brandController, "Brand", "e.g. Apple"),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_priceController, "Price (\$)", "0.00", isNumber: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildTextField(_stockController, "Stock", "1", isNumber: true)),
                      ],
                    ),

                    _sectionTitle("Category"),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputStyle(""),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),

                    _sectionTitle("Description"),
                    _buildTextField(_descController, "Description", "Details...", maxLines: 4),

                    _sectionTitle("Media"),
                    _buildTextField(_imageController, "Image URL", "Link to product image"),

                    _sectionTitle("Variants"),
                    _buildVariantSection(),

                    const SizedBox(height: 40),
                    _buildSubmitButton(isEditing),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _imageController.text.isEmpty
          ? const Icon(Icons.image_outlined, size: 50, color: Colors.grey)
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(_imageController.text, fit: BoxFit.contain, 
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.red)),
              ),
            ),
    );
  }

  Widget _buildVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _variantController,
                decoration: _inputStyle("e.g. 128GB, Blue"),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: _addVariant,
              style: IconButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: _variants.map((v) => Chip(
            label: Text(v, style: const TextStyle(fontSize: 12)),
            onDeleted: () => setState(() => _variants.remove(v)),
            deleteIconColor: Colors.red,
            backgroundColor: AppColors.primary.withOpacity(0.05),
            // FIXED: Using 'side' instead of 'borderSide'
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), 
              side: BorderSide(color: AppColors.primary.withOpacity(0.1)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(isEditing ? "Update Product" : "Publish Listing",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: _inputStyle(hint).copyWith(labelText: label),
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }
}