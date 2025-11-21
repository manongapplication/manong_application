import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manong_application/theme/colors.dart';

final storage = FlutterSecureStorage();

Future<void> showDisclaimerDialog(
  BuildContext context, {
  String? title,
  required String message,
  VoidCallback? onAgree,
  bool? hasCancel,
  String? dontShowAgainKey,
}) async {
  bool checked = false;

  // If user already chose "Don't show again", skip dialog
  if (dontShowAgainKey != null) {
    String? dontShowAgain = await storage.read(key: dontShowAgainKey);
    if (dontShowAgain == 'true') return;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title ?? 'Disclaimer',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 14)),
              if (dontShowAgainKey != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      activeColor: AppColorScheme.primaryDark,
                      value: checked,
                      onChanged: (value) {
                        setState(() => checked = value!);
                        storage.write(
                          key: dontShowAgainKey,
                          value: checked.toString(),
                        );
                      },
                    ),
                    const Text("Don't show this again"),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (hasCancel == true) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onAgree?.call();
              },
              child: Text(
                'Agree',
                style: TextStyle(color: AppColorScheme.primaryColor),
              ),
            ),
          ],
        );
      },
    ),
  );
}
