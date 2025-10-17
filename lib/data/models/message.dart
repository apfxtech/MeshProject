class Message {
  Message({
    this.id = 0,
    required this.role,
    required this.content,
    this.origin = '',
    this.hops = 0,
    this.dest = '',
    this.date = null,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: int.tryParse(json['id'].toString()) ?? 0,
    role: json['rl'] as String? ?? '',
    content: json['ct'] as String? ?? '',
    hops: json['hp'] as int? ?? 0,
    date: json['dt'] != null ? DateTime.parse(json['dt'] as String) : null,
    origin: json['fm'] as String? ?? '',
    dest: json['to'] as String? ?? '',
  );

  final int id;
  final String role;
  String content;
  final int hops;
  final DateTime? date;
  final String origin;
  final String dest;

  String get() => content;

  void edit(String text) {
    content = text;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rl': role,
    'ct': content,
    'fm': origin,
    'hp': hops,
    'to': dest,
    'dt': date?.toIso8601String(),
  };
}