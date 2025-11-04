import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/image_dialog.dart';

final Logger logger = Logger('single_image_picker_card');

class SingleImagePickerCard extends StatefulWidget {
  final Function(File?) onImageSelect;
  final File? image;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  const SingleImagePickerCard({
    super.key,
    required this.onImageSelect,
    this.image,
    this.padding = const EdgeInsets.all(0),
    this.enabled = true,
  });

  @override
  State<SingleImagePickerCard> createState() => _SingleImagePickerCardState();
}

class _SingleImagePickerCardState extends State<SingleImagePickerCard> {
  final ImagePicker picker = ImagePicker();
  File? get _image => widget.image;

  Future<bool> _isValidImage(File file) async {
    try {
      final decodedImage = await decodeImageFromList(await file.readAsBytes());
      return decodedImage.width > 0 && decodedImage.height > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      if (await _isValidImage(file)) {
        setState(() {
          widget.onImageSelect(file);
        });
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Invalid image. Please choose another.',
        );
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
    if (!widget.enabled) return;

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
    final bool isEnabled = widget.enabled;

    return Material(
      color: AppColorScheme.primaryLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isEnabled
            ? () async {
                if (_image != null) {
                  _showImageDialog(_image!);
                } else {
                  await _onSelectImageSource();
                }
              }
            : null,
        child: SizedBox(
          width: double.infinity,
          height: 160,
          child: _image != null
              ? Padding(
                  padding: widget.padding,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isEnabled)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.onImageSelect(null);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 32,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: const Radius.circular(12),
                    dashPattern: [10, 5],
                    strokeWidth: 2,
                    color: isEnabled
                        ? AppColorScheme.primaryDark
                        : Colors.grey.shade400, // subtle disabled look
                    padding: const EdgeInsets.all(32),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 36,
                          color: isEnabled
                              ? Colors.black
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload a valid ID or selfie',
                          style: TextStyle(
                            color: isEnabled
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
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
