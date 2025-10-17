class OpenAI {
  final String baseUrl;
  final String apiKey;

  OpenAI({required this.baseUrl, required this.apiKey});

  factory OpenAI.fromJson(Map<String, dynamic> json) =>
      OpenAI(baseUrl: json['base_url'], apiKey: json['api_key']);

  Map<String, dynamic> toJson() => {
    'base_url': baseUrl,
    'api_key': apiKey,
  };
}
