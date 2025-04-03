import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:surwa/data/models/product.dart';
import 'package:surwa/services/image_picker_service.dart';
import 'package:surwa/services/product_service.dart';

import '../lib/services/product_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  ImagePickerService
])
void main() {
  late ProductService productService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockImagePickerService mockImagePickerService;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockImagePickerService = MockImagePickerService();

    when(mockFirestore.collection('Product')).thenReturn(mockCollection);
    productService = ProductService();
    productService.productCollection = mockCollection;
    productService.imagePickerService = mockImagePickerService;
  });

  group('addProduct', () {
    test('should add a product with an image', () async {
      final product = Product(
        ownerId: 'owner123',
        productId: 'product123',
        name: 'Test Product',
        price: 100.0,
        category: Category(name: 'Test Category'),
        description: 'Test Description',
        inStock: 10,
        imageUrl: '',
      );
      final imageFile = File('path/to/image.jpg');
      const imageUrl = 'https://example.com/image.jpg';

      when(mockImagePickerService.uploadProductImage(
              imageFile, 'products/owner123/product123'))
          .thenAnswer((_) async => imageUrl);
      when(mockCollection.add(any)).thenAnswer((_) async => mockDocument);

      await productService.addProduct(product, imageFile);

      verify(mockImagePickerService.uploadProductImage(
              imageFile, 'products/owner123/product123'))
          .called(1);
      verify(mockCollection.add(argThat(predicate<Map<String, dynamic>>(
        (data) =>
            data['ownerId'] == 'owner123' &&
            data['name'] == 'Test Product' &&
            data['price'] == 100.0 &&
            data['category'] == 'Test Category' &&
            data['description'] == 'Test Description' &&
            data['imageUrl'] == imageUrl &&
            data['inStock'] == 10,
      )))).called(1);
    });

    test('should add a product without an image', () async {
      final product = Product(
        ownerId: 'owner123',
        productId: 'product123',
        name: 'Test Product',
        price: 100.0,
        category: Category(name: 'Test Category'),
        description: 'Test Description',
        inStock: 10,
        imageUrl: '',
      );

      when(mockCollection.add(any)).thenAnswer((_) async => mockDocument);

      await productService.addProduct(product, null);

      verifyNever(mockImagePickerService.uploadProductImage(any, any));
      verify(mockCollection.add(argThat(predicate<Map<String, dynamic>>(
        (data) =>
            data['ownerId'] == 'owner123' &&
            data['name'] == 'Test Product' &&
            data['price'] == 100.0 &&
            data['category'] == 'Test Category' &&
            data['description'] == 'Test Description' &&
            data['imageUrl'] == '' &&
            data['inStock'] == 10,
      )))).called(1);
    });
  });
}
