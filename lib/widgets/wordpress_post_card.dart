import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class WordpressPostCard extends StatelessWidget {
  final int id;
  final String title;
  final String? excerpt;
  final String? content;
  final String? imageUrl;
  final String link;

  const WordpressPostCard({
    super.key,
    required this.id,
    required this.title,
    this.excerpt,
    this.content,
    this.imageUrl,
    required this.link,
  });

  void _openLink() async {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cardWidth = 250;
    const double imageHeight = 120;
    const double contentHeight = 150;

    return GestureDetector(
      onTap: _openLink,
      child: Card(
        color: Colors.grey.shade100,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SizedBox(
          width: cardWidth,
          child: Column(
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: cardWidth,
                        height: imageHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _placeholderImage(cardWidth, imageHeight);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: cardWidth,
                            height: imageHeight,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : _placeholderImage(cardWidth, imageHeight),
              ),

              // Content Section
              SizedBox(
                width: cardWidth,
                height: contentHeight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Html(
                          data: title,
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              fontWeight: FontWeight.bold,
                              fontSize: FontSize(16),
                              maxLines: 2,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          },
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Html(
                          data: excerpt ?? content ?? "",
                          style: {
                            "body": Style(
                              margin: Margins.zero,
                              fontSize: FontSize(12),
                              maxLines: 3,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Image.asset('assets/icon/logo.png', fit: BoxFit.cover),
    );
  }
}
