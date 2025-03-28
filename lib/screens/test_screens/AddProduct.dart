import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:surwa/data/models/product.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:surwa/services/product_service.dart';


class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService productService = ProductService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  File? _selectedImage;

  final String _ownerId = "HhC52h2IN9UBWnwb5FGxWywfzyT2"; // Replace with actual user ID

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProduct(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String productId = Uuid().v4();
    Product product = Product(
      productId: productId,
      ownerId: _ownerId,
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      category: _categoryController.text.trim(),
      inStock: int.parse(_stockController.text.trim()),
      imageUrl: "url"
    );
    _categoryController.clear();
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();

    try {
      DocumentReference productRef = await productService.addProduct(product, _selectedImage);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product Added Successfully!")));
    } catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Enter product name' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Category'),
                validator: (value) => value!.isEmpty ? 'Enter category' : null,
              ),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter stock quantity' : null,
              ),
              SizedBox(height: 10),
              _selectedImage != null
                  ? Image.file(_selectedImage!, height: 100)
                  : Text("No image selected"),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pick Image"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: ()=> _uploadProduct(context),
                child: Text("Add Product"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
