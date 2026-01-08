import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/permission_utils.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/image_dialog.dart';

final Logger logger = Logger('image_picker_card');

class ImagePickerCard extends StatefulWidget {
  final Function(List<File> images) onImageSelect;
  final List<File> images;

  const ImagePickerCard({
    super.key,
    required this.onImageSelect,
    required this.images,
  });
  @override
  State<ImagePickerCard> createState() => _ImagePickerState();
}

class _ImagePickerState extends State<ImagePickerCard> {
  List<File> get _images => widget.images;
  final ImagePicker picker = ImagePicker();
  final int maxImages = 3;
  final PermissionUtils _permissionUtils = PermissionUtils();

  Future<bool> _isValidImage(File file) async {
    try {
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      return decodedImage.width > 0 && decodedImage.height > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkAndRequestPermission(ImageSource source) async {
    bool hasPermission;

    if (source == ImageSource.camera) {
      hasPermission = await _permissionUtils.checkCameraPermission();
    } else {
      hasPermission = await _permissionUtils.checkGalleryPermission();
    }

    if (!hasPermission) {
      _showPermissionSettingsDialog(source);
      return false;
    }

    return true;
  }

  // Show settings dialog for permanently denied permissions
  void _showPermissionSettingsDialog(ImageSource source) {
    String permissionType = source == ImageSource.camera ? 'Camera' : 'Gallery';

    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          '$permissionType permission is required to upload photos. '
          'Please enable it in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _permissionUtils.openAppSettings();
            },
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Check permission first
    bool hasPermission = await _checkAndRequestPermission(source);
    if (!hasPermission) {
      logger.info('Permission not granted for ${source.name}');
      return;
    }

    if (source == ImageSource.gallery) {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 80, // compress
        maxWidth: 1024,
      );

      if (pickedFiles.isNotEmpty) {
        int remaining = maxImages - _images.length;

        if (_images.length >= maxImages) {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            'You can upload a maximum of $maxImages images',
          );
          return;
        }

        final acceptedFiles = pickedFiles.take(remaining).toList();

        if (acceptedFiles.length < pickedFiles.length) {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            'Only $remaining more image(s) allowed. Extra images ignored.',
          );
        }

        for (var xfile in acceptedFiles) {
          File file = File(xfile.path);
          if (await _isValidImage(file)) {
            setState(() {
              _images.add(file);
            });
          }
        }
        widget.onImageSelect(_images);
      }
    } else {
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null && _images.length < maxImages) {
        File file = File(pickedFile.path);
        if (await _isValidImage(file)) {
          setState(() {
            _images.add(file);
          });
          widget.onImageSelect(_images);
        } else {
          logger.severe("Invalid image selected, skipping...");
        }
      }
    }
  }

  void _showImageDialog(File image) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (_) => ImageDialog(image: image),
    );
  }

  Future<void> _onSelectImageSource() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColorScheme.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () =>
            _images.length >= maxImages ? null : _onSelectImageSource(),
        child: SizedBox(
          width: double.infinity,
          child: _images.isNotEmpty
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      for (var img in _images)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  _showImageDialog(img);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    img,
                                    height: 150,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _images.remove(img);
                                  });
                                  widget.onImageSelect(_images);
                                },
                                child: Icon(
                                  Icons.close,
                                  size: 32,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                )
              : DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: Radius.circular(12),
                    dashPattern: [10, 5],
                    strokeWidth: 2,
                    color: AppColorScheme.primaryDark,
                    padding: EdgeInsets.all(32),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.image),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to add photos',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
