import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/rating_input.dart';
import '../../widgets/image_gallery_preview.dart';

class WriteReviewPage extends StatefulWidget {
  final String tourId;
  final String tourName;
  final String bookingId;
  final String userId;

  const WriteReviewPage({
    super.key,
    required this.tourId,
    required this.tourName,
    required this.bookingId,
    required this.userId,
  });

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  final ReviewService _reviewService = ReviewService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _rating = 0;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReviewed();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    final hasReviewed = await _reviewService.hasUserReviewedBooking(
      widget.bookingId,
    );
    if (hasReviewed && mounted) {
      setState(() {
        _hasSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reviewed this booking')),
      );
    }
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting review submission...');

      // Upload images to Cloudinary (if fails, continue without images)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('Uploading ${_selectedImages.length} images to Cloudinary...');
        try {
          imageUrls = await _cloudinaryService.uploadMultipleImages(
            imageFiles: _selectedImages,
            folder: 'review-images',
          );
          print('Images uploaded: ${imageUrls.length}');
        } catch (uploadError) {
          print(
            'Image upload failed: $uploadError - continuing without images',
          );
          // Continue with empty imageUrls - review can be submitted without images
        }
      }

      print('Creating review with ${imageUrls.length} images...');

      // Create review
      final review = Review(
        id: const Uuid().v4(),
        bookingId: widget.bookingId,
        userId: widget.userId,
        tourId: widget.tourId,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
        reviewImages: imageUrls,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      print('Submitting review to Firestore...');
      await _reviewService.createReview(review);
      print('Review submitted successfully!');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasSubmitted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Review submitted successfully! It will be reviewed by admin.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSubmitted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Write a Review')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green[400]),
              const SizedBox(height: 24),
              const Text(
                'Review Submitted!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Thank you for your feedback. Your review will be published after admin approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Tours'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
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

            // Images
            ImageGalleryPreview(
              images: _selectedImages,
              onRemove: _removeImage,
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
                  : const Text('Submit Review', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
