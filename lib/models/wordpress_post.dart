class WordpressPost {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String link;
  final String? imageUrl;

  WordpressPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    this.imageUrl,
  });

  factory WordpressPost.fromJson(Map<String, dynamic> json) {
    return WordpressPost(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      link: json['link'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?, // optional
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'link': link,
      'imageUrl': imageUrl,
    };
  }
}
