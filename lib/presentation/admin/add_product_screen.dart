import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:premium_store/core/constants/colors.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? productData; // For editing existing product
  final String? productId; // Firestore Document ID

  const AddProductScreen({super.key, this.productData, this.productId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    final p = widget.productData;
    // Pre-fill controllers if editing, else empty
    _titleController = TextEditingController(text: p?['title'] ?? "");
    _brandController = TextEditingController(text: p?['brand'] ?? "");
    _priceController = TextEditingController(text: p?['price']?.toString() ?? "");
    _descController = TextEditingController(text: p?['description'] ?? "");
    _imageController = TextEditingController(text: p?['imageUrl'] ?? "");
    _stockController = TextEditingController(text: p?['stock']?.toString() ?? "1");

    // Listen to image URL changes to update preview box
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
    super.dispose();
  }

  Future<void> _submitData() async {
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
        'stock': int.tryParse(_stockController.text.trim()) ?? 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.productId != null && widget.productId!.isNotEmpty) {
        // UPDATE MODE
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update(data);
      } else {
        // CREATE MODE
        data['rating'] = 5.0;
        data['reviews'] = 0;
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.productId != null ? "Product Updated!" : "Product Added!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
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
        title: Text(isEditing ? "Edit Listing" : "Add New Product", 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 20),
                    _buildField(_titleController, "Product Title", "e.g. Sony WH-1000XM5"),
                    _buildField(_brandController, "Brand", "e.g. Sony"),
                    Row(
                      children: [
                        Expanded(child: _buildField(_priceController, "Price (\$)", "0.00", isNumber: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField(_stockController, "Stock", "1", isNumber: true)),
                      ],
                    ),
                    _buildField(_descController, "Description", "Tell buyers about your product...", maxLines: 3),
                    _buildField(_imageController, "Image URL", "Paste direct image link"),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _submitData,
                        child: Text(isEditing ? "Save Changes" : "Upload Product to Store",
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _imageController.text.isEmpty
          ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey))
          : ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                _imageController.text,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.red),
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, String hint, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        validator: (val) => val == null || val.isEmpty ? "Required" : null,
      ),
    );
  }
}