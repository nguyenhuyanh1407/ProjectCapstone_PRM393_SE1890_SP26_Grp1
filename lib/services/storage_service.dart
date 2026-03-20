import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  /// Pick single image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      print('Error picking images: $e');
    }
    return [];
  }

  /// Compress image file
  Future<File?> compressImage(File file) async {
    try {
      final filePath = file.path;
      final outFile = filePath.replaceAll(
        filePath.substring(filePath.lastIndexOf('/') + 1),
        'compressed_${_uuid.v4()}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outFile,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (e) {
      print('Error compressing image: $e');
    }
    return file;
  }

  /// Upload single image to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
    Function(double)? onProgress,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      fileName ??= '${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child('$folder/$fileName');
      
      print('Starting upload to $folder/$fileName');
      
      // Upload the file with timeout
      final uploadTask = storageRef.putFile(imageFile).timeout(
        timeout,
        onTimeout: () {
          print('Upload timeout for $fileName');
          throw TimeoutException('Upload timeout after ${timeout.inSeconds}s');
        },
      );
      
      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => {});
      
      print('Upload complete, getting download URL');
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload successful: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Exception uploading image: ${e.code} - ${e.message}');
      return null;
    } on TimeoutException catch (e) {
      print('Timeout uploading image: $e');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images to Firebase Storage
  /// Returns list of download URLs
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
    Function(String, double)? onProgress,
  }) async {
    List<String> urls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = '${_uuid.v4()}.jpg';
      
      final url = await uploadImage(
        imageFile: file,
        folder: folder,
        fileName: fileName,
        onProgress: (progress) {
          if (onProgress != null) {
            onProgress(fileName, progress);
          }
        },
      );
      
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}