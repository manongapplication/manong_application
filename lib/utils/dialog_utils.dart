import 'package:flutter/material.dart';
import 'package:manong_application/widgets/image_dialog.dart';

void showImageDialog(BuildContext context, String image) {
  showDialog(
    context: context,
    builder: (_) => ImageDialog(imageString: image),
  );
}
