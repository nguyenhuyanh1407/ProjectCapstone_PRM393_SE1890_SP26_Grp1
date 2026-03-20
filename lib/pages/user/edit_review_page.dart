import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/rating_input.dart';
import '../../widgets/image_gallery_preview.dart';

class EditReviewPage extends StatefulWidget {
  final Review review;
  final String tourName;

  const EditReviewPage({
    super.key,
    required this.review,
    required this.tourName,
  });

  @override
  State<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends State<EditReviewPage> {
  final ReviewService _reviewService = ReviewService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _commentController;

  late double _rating;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  bool _removeExistingImages = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating.toDouble();
    _commentController = TextEditingController(text: widget.review.comment);
    _existingImageUrls = List.from(widget.review.reviewImages);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    final fromCamera = choice == 'camera';
    final image = await _cloudinaryService.pickImage(fromCamera: fromCamera);

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting review update...');

      // Upload new images to Cloudinary
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('Uploading ${_selectedImages.length} new images to Cloudinary...');
        try {
          newImageUrls = await _cloudinaryService.uploadMultipleImages(
            imageFiles: _selectedImages,
            folder: 'review-images',
          );
          print('New images uploaded: ${newImageUrls.length}');
        } catch (uploadError) {
          print('New image upload failed: $uploadError - continuing without new images');
        }
      }

      // Combine existing and new images
      List<String> finalImageUrls = [];
      if (!_removeExistingImages) {
        finalImageUrls.addAll(_existingImageUrls);
      }
      finalImageUrls.addAll(newImageUrls);

      print('Updating review with ${finalImageUrls.length} images...');

      // Update review in Firestore
      await _reviewService.updateReview(
        reviewId: widget.review.id,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
        reviewImages: finalImageUrls,
      );

      print('Review updated successfully!');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review updated successfully! Waiting for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error updating review: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Review'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tour info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewing:',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tourName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rating
            RatingInput(
              initialRating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
              size: 40,
              label: 'Your Rating *',
            ),

            const SizedBox(height: 24),

            // Comment
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Your Review *',
                hintText: 'Share your experience with this tour...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write your review';
                }
                if (value.trim().length < 10) {
                  return 'Review must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Existing images
            if (_existingImageUrls.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Existing Photos (${_existingImageUrls.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _removeExistingImages,
                        onChanged: (value) {
                          setState(() {
                            _removeExistingImages = value ?? false;
                          });
                        },
                      ),
                      const Text('Remove all'),
                    ],
                  ),
                ],
              ),
              if (!_removeExistingImages)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _existingImageUrls[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],

            // New images preview
            ImageGalleryPreview(
              images: _selectedImages,
              onRemove: _removeNewImage,
              onAddImage: _pickImages,
              maxImages: 10,
            ),

            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Submit Edited Review',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}