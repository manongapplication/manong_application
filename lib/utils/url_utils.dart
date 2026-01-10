import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

final Logger logger = Logger('url_utils');

Future<void> launchInBrowser(String? url) async {
  if (url == null) {
    throw Exception('Url is required!');
  }
  final uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

Future<void> launchUrlScreen(BuildContext context, String link) async {
  if (link.isEmpty) {
    logger.info('URL is empty');
    return;
  }

  // Ensure URL has proper scheme
  String formattedUrl = link;
  if (!link.startsWith('http://') && !link.startsWith('https://')) {
    formattedUrl = 'https://$link';
  }

  final uri = Uri.tryParse(formattedUrl);
  if (uri == null) {
    logger.info('Failed to parse URI from: $formattedUrl');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid URL format'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // Use platformView mode which usually has less issues
    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
        enableDomStorage: true,
        headers: <String, String>{}, // Empty headers to avoid issues
      ),
    );
  } catch (e) {
    logger.info('Error launching URL: $e');

    // Fallback to external browser
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e2) {
      logger.info('Fallback also failed: $e2');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
