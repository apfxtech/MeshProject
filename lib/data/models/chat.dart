// lib/data/models/chat.dart 
class Chat {
  static const String newChatTitle = 'New chat';

  Chat({
    this.id = 0,
    this.title = newChatTitle,
    this.key = '',            // ключ шифрования для каналов
    this.assistant = '',       // индификатор пользовотеля или модели
    this.source = '',         // модель, бот, пользователь
    this.temperature = 0.7,   // температура модели
    this.top_p = 1.0,         // top_p модели
    this.max_tokens = 1024,  // максимальная длинна сообщения
    this.system = '',         // системное сообщение 
    this.opening = '',        // первое сообщение 
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: int.tryParse(json['id'].toString()) ?? 0,
        title: json['ti'] as String? ?? newChatTitle,
        key: json['sk'] as String? ?? '',
        assistant: json['as'] as String? ?? '',
        source: json['sc'] as String? ?? '',
        system: json['sm'] as String? ?? '',
        opening: json['om'] as String? ?? '',
        temperature: (json['tm'] as num?)?.toDouble() ?? 0.7,
        top_p: (json['tp'] as num?)?.toDouble() ?? 1.0,
        max_tokens: (json['mt'] as num?)?.toInt() ?? 1024,
      );

  final int id;
  final String title;
  final String key;
  final String assistant;
  final double temperature;
  final double top_p;
  final int max_tokens;
  final String source; 
  final String system;
  final String opening;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ti': title,
        'sk': key,
        'as': assistant,
        'sc': source,
        'sm': system,
        'om': opening,
        'tm': temperature,
        'tp': top_p,
        'mt': max_tokens,
      };
}