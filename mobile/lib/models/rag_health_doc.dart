class RAGHealthDoc {
  final String id;
  final String source;
  final String title;
  final String url;
  final String publicationDate;
  final String topic;
  final String evidenceLevel; // e.g. 'Systematic Review', 'Clinical Trial', 'Public Health Guidance'
  final String summary;
  final String fullText;
  final List<String> tags;

  const RAGHealthDoc({
    required this.id,
    required this.source,
    required this.title,
    required this.url,
    required this.publicationDate,
    required this.topic,
    required this.evidenceLevel,
    required this.summary,
    required this.fullText,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'title': title,
    'url': url,
    'publicationDate': publicationDate,
    'topic': topic,
    'evidenceLevel': evidenceLevel,
    'summary': summary,
    'fullText': fullText,
    'tags': tags,
  };

  factory RAGHealthDoc.fromJson(Map<String, dynamic> json) => RAGHealthDoc(
    id: json['id'] as String,
    source: json['source'] as String,
    title: json['title'] as String,
    url: json['url'] as String,
    publicationDate: json['publicationDate'] as String,
    topic: json['topic'] as String,
    evidenceLevel: json['evidenceLevel'] as String,
    summary: json['summary'] as String,
    fullText: json['fullText'] as String,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}
