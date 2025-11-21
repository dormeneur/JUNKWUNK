import 'package:flutter/material.dart';

import '../services/s3_service.dart';
import '../utils/colors.dart';

/// Widget to display S3 images with presigned URLs
class S3Image extends StatefulWidget {
  final String? imageKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const S3Image({
    super.key,
    required this.imageKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<S3Image> createState() => _S3ImageState();
}

class _S3ImageState extends State<S3Image> {
  final S3Service _s3Service = S3Service();
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(S3Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageKey != widget.imageKey) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageKey == null || widget.imageKey!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final url = await _s3Service.getImageUrl(widget.imageKey!);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading S3 image: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
    }

    if (_hasError || _imageUrl == null) {
      return widget.errorWidget ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: Icon(Icons.error_outline, color: AppColors.grey),
            ),
          );
    }

    return Image.network(
      _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error displaying image: $error');
        return widget.errorWidget ??
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: Icon(Icons.error_outline, color: AppColors.grey),
              ),
            );
      },
    );
  }
}
