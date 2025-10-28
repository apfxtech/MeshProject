class OpenAI {
  final String name;
  final String type;
  final String? baseUrl;
  final String? apiKey;
  final String? model;
  final String? imagePath;

  OpenAI({
    required this.name,
    required this.type,
    this.baseUrl,
    this.apiKey,
    this.model,
    this.imagePath,
  });

  factory OpenAI.fromJson(Map<String, dynamic> json) => OpenAI(
        name: json['name'] as String,
        type: json['type'] as String,
        baseUrl: json['base_url'] as String?,
        apiKey: json['api_key'] as String?,
        model: json['model'] as String?,
        imagePath: json['image_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'base_url': baseUrl,
        'api_key': apiKey,
        'model': model,
      };

  @override
  String toString() {
    return 'OpenAI(name: $name, type: $type, baseUrl: $baseUrl, model: $model)';
  }
}