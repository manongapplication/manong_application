import 'dart:io';
import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';

class ImageDialog extends StatelessWidget {
  final File? image;
  final String? imageString;

  const ImageDialog({this.image, super.key, this.imageString});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColorScheme.backgroundGrey,
      insetPadding: EdgeInsets.all(8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageString != null
                ? Image.network(imageString!)
                : Image.file(image!),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
