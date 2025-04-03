import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/services/image_picker_service.dart';
import '../lib/services/image_picker_service_test.mocks.dart';

@GenerateMocks([ImagePicker, SupabaseClient])
void main() {
  late ImagePickerService imagePickerService;
  late MockImagePicker mockImagePicker;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockImagePicker = MockImagePicker();
    mockSupabaseClient = MockSupabaseClient();
    imagePickerService = ImagePickerService();
  });

  group('ImagePickerService', () {
    test('pickImage returns a File when an image is picked', () async {
      final mockFile = XFile('path/to/image.jpg');
      when(mockImagePicker.pickImage(
        source: anyNamed('source'),
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      )).thenAnswer((_) async => mockFile);

      final result = await imagePickerService.pickImage(ImageSource.gallery);

      expect(result, isA<File>());
      expect(result?.path, 'path/to/image.jpg');
    });

    test('pickImage returns null when no image is picked', () async {
      when(mockImagePicker.pickImage(
        source: anyNamed('source'),
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      )).thenAnswer((_) async => null);

      final result = await imagePickerService.pickImage(ImageSource.gallery);

      expect(result, isNull);
    });

    test('uploadProfileImage uploads image and returns public URL', () async {
      final mockFile = File('path/to/image.jpg');
      final mockBytes = [1, 2, 3];
      when(mockFile.readAsBytes()).thenAnswer((_) async => mockBytes);
      when(mockSupabaseClient.storage.from('profile-images').uploadBinary(
            any,
            mockBytes,
          )).thenAnswer((_) async => {});
      when(mockSupabaseClient.storage.from('profile-images').getPublicUrl(any))
          .thenReturn('https://example.com/image.jpg');

      final result = await imagePickerService.uploadProfileImage(
        mockFile,
        'storage/path',
      );

      expect(result, 'https://example.com/image.jpg');
    });

    test('uploadProfileImage returns error message on failure', () async {
      final mockFile = File('path/to/image.jpg');
      when(mockFile.readAsBytes()).thenThrow(Exception('Error'));

      final result = await imagePickerService.uploadProfileImage(
        mockFile,
        'storage/path',
      );

      expect(
          result, 'There was an error uploading the image. Please try again.');
    });
  });
}
