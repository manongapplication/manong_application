import 'dart:io';
import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class ImageDialog extends StatefulWidget {
  final File? image;
  final String? imageString;

  const ImageDialog({this.image, super.key, this.imageString});

  @override
  State<ImageDialog> createState() => _ImageDialogState();
}

class _ImageDialogState extends State<ImageDialog> {
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _isSaving = false; // Add loading state

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      _isFullScreen = !_isFullScreen;
    });
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_isSaving) return; // Prevent multiple taps

    setState(() {
      _isSaving = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.request();

      if (await Permission.storage.isGranted) {
        if (widget.imageString != null) {
          // Save network image
          var response = await http.get(Uri.parse(widget.imageString!));
          final result = await ImageGallerySaver.saveImage(
            response.bodyBytes,
            quality: 100,
          );

          if (result != null && result['isSuccess'] == true) {
            // Close the dialog
            if (mounted) {
              Navigator.pop(context);
            }

            // Use a post frame callback to show snackbar after dialog is closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image saved to gallery'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          } else {
            throw Exception('Failed to save image');
          }
        } else if (widget.image != null) {
          // Save local image
          final bytes = await widget.image!.readAsBytes();
          final result = await ImageGallerySaver.saveImage(bytes, quality: 100);

          if (result != null && result['isSuccess'] == true) {
            // Close the dialog
            if (mounted) {
              Navigator.pop(context);
            }

            // Use a post frame callback to show snackbar after dialog is closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Image saved to gallery'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            });
          } else {
            throw Exception('Failed to save image');
          }
        }
      } else {
        // Permission denied
        setState(() {
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to save images'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Open app settings
        openAppSettings();
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen image with zoom and tap to toggle
          GestureDetector(
            onTap: _toggleControls,
            child: Container(
              color: Colors.black,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: _isFullScreen
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(40),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: widget.imageString != null
                        ? Image.network(
                            widget.imageString!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColorScheme.primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Image.file(
                            widget.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Messenger-style top bar (appears/disappears on tap)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),

                      // Save button with loading state
                      GestureDetector(
                        onTap: _isSaving ? null : () => _saveImage(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.file_download,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
