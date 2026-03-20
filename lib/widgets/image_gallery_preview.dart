import 'dart:io';
import 'package:flutter/material.dart';

class ImageGalleryPreview extends StatelessWidget {
  final List<File> images;
  final Function(int)? onRemove;
  final bool showAddButton;
  final VoidCallback? onAddImage;
  final int maxImages;

  const ImageGalleryPreview({
    super.key,
    required this.images,
    this.onRemove,
    this.showAddButton = true,
    this.onAddImage,
    this.maxImages = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photos (${images.length}/$maxImages)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showAddButton && images.length < maxImages && onAddImage != null)
              TextButton.icon(
                onPressed: onAddImage,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text('Add Photo'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No photos yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add photos to share your experience',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: images.length + (showAddButton && images.length < maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == images.length) {
                // Add button cell
                return GestureDetector(
                  onTap: onAddImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: Icon(Icons.add, color: Colors.grey[400], size: 32),
                  ),
                );
              }

              return _ImagePreviewCell(
                image: images[index],
                onRemove: onRemove != null ? () => onRemove!(index) : null,
              );
            },
          ),
      ],
    );
  }
}

class _ImagePreviewCell extends StatelessWidget {
  final File image;
  final VoidCallback? onRemove;

  const _ImagePreviewCell({
    required this.image,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget for showing upload progress
class ImageUploadProgress extends StatelessWidget {
  final Map<String, double> progressMap; // fileName -> progress
  final List<String> completedUrls;

  const ImageUploadProgress({
    super.key,
    required this.progressMap,
    this.completedUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final totalImages = progressMap.length;
    final completedCount = completedUrls.length;
    final isUploading = progressMap.values.any((p) => p < 1.0);

    if (!isUploading && completedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                isUploading ? 'Uploading photos...' : 'Photos uploaded',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isUploading ? Colors.blue[700] : Colors.green[700],
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount/$totalImages',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          if (isUploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completedCount / totalImages,
                backgroundColor: Colors.blue[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet for selecting image source
Future<File?> showImageSourcePicker({
  required BuildContext context,
  bool showCamera = true,
}) async {
  final options = <Widget>[
    ListTile(
      leading: const Icon(Icons.photo_library, color: Colors.blue),
      title: const Text('Choose from Gallery'),
      onTap: () async {
        Navigator.pop(context);
        // This will be handled by the parent widget using StorageService
      },
    ),
    if (showCamera)
      ListTile(
        leading: const Icon(Icons.camera_alt, color: Colors.green),
        title: const Text('Take a Photo'),
        onTap: () async {
          Navigator.pop(context);
          // This will be handled by the parent widget using StorageService
        },
      ),
  ];

  final result = await showModalBottomSheet<File?>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...options,
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  return result;
}