import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

/// Cloudinary Service for image upload
///
/// Setup instructions:
/// 1. Create free account at https://cloudinary.com
/// 2. Get your Cloud Name, API Key, and API Secret from Dashboard
/// 3. Update _cloudName, _apiKey, _apiSecret below
class CloudinaryService {
  final Uuid _uuid = const Uuid();
  final ImagePicker _imagePicker = ImagePicker();

  // Get these from https://cloudinary.com/console
  static const String _cloudName = 'db8sy6nay';
  static const String _apiKey = '838672483989936';
  static const String _apiSecret = 'H2X1UFEw8gIngTAKT8QTqYnk15E';

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

  /// Upload single image to Cloudinary
  /// Returns the download URL
  Future<String?> uploadImage({
    required File imageFile,
    String folder = 'review-images',
    Function(double)? onProgress,
  }) async {
    try {
      print('Starting Cloudinary upload...');

      // Prepare the upload request
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final randomId = _uuid.v4();
      final publicId = 'review-images/$randomId';

      // Create signature for authentication
      // Must include ALL parameters in signature (in alphabetical order)
      final signature = _generateSignature(timestamp, publicId, folder);

      // Create multipart request
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url);

      // Add fields (in alphabetical order for consistency)
      request.fields['api_key'] = _apiKey;
      request.fields['folder'] = folder;
      request.fields['public_id'] = publicId;
      request.fields['signature'] = signature;
      request.fields['timestamp'] = timestamp.toString();

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      print('Uploading to Cloudinary...');
      print('Public ID: $publicId');
      print('Folder: $folder');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final imageUrl = jsonData['secure_url'] as String?;
        print('Upload successful: $imageUrl');
        return imageUrl;
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple images to Cloudinary
  /// Returns list of download URLs
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    String folder = 'review-images',
  }) async {
    List<String> urls = [];
    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      print('Uploading image ${i + 1}/${imageFiles.length}...');

      final url = await uploadImage(imageFile: file, folder: folder);

      if (url != null) {
        urls.add(url);
      }
    }
    print('Uploaded ${urls.length} images to Cloudinary');
    return urls;
  }

  /// Generate signature for Cloudinary API
  /// See: https://cloudinary.com/documentation/upload_images#generating_signatures
  String _generateSignature(int timestamp, String publicId, String folder) {
    // Create the string to sign (parameters in alphabetical order)
    // DO NOT include api_key in the signature
    // Include ALL other parameters that will be sent in the request
    final stringToSign = 'folder=$folder&public_id=$publicId&timestamp=$timestamp$_apiSecret';

    // Generate SHA1 hash
    final bytes = utf8.encode(stringToSign);
    final digest = sha1.convert(bytes);

    print('String to sign: $stringToSign');
    print('Generated signature: ${digest.toString()}');

    return digest.toString();
  }

  /// Delete image from Cloudinary (requires admin API)
  Future<void> deleteImage(String imageUrl) async {
    print(
      'Note: Delete functionality requires Cloudinary Admin API with signature',
    );
    // Implementation requires extracting public_id from URL and signing the request
  }

  /// Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }
}