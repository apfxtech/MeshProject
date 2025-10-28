import 'dart:async';
import 'package:tostore/tostore.dart';
import '../models/openai.dart';
import '../models/contact.dart';

const TableSchema usersSchema = TableSchema(
  name: 'settings',
  primaryKeyConfig: PrimaryKeyConfig(
    name: 'id',
    type: PrimaryKeyType.sequential,
    sequentialConfig: SequentialIdConfig(
      initialValue: 1,
      increment: 1,
      useRandomIncrement: false,
    ),
  ),
  fields: [
    FieldSchema(name: 'type', type: DataType.text, nullable: false),
    FieldSchema(name: 'base_url', type: DataType.text, nullable: true),
    FieldSchema(name: 'api_key', type: DataType.text, nullable: true),
    FieldSchema(name: 'model', type: DataType.text, nullable: true),
  ],
  indexes: [
    IndexSchema(fields: ['type'], unique: true),
  ],
);

class UsersRepository {
  static late ToStore _db;

  static void init(ToStore db) {
    _db = db;
  }

  static const Map<String, String> _defaultModels = {
    'openai': 'gpt-4o',
    'grok': 'x-ai/grok-3',
    'anthropic': 'claude-3-5-haiku-20241022',
    'deepseek': 'deepseek-chat',
    'gemini': 'gemini-2.0-flash-lite',
    'openrouter': 'deepseek/deepseek-chat-v3.1:free',
    'custom': 'gpt-4o',
  };

  static const Map<String, String> _defaultBaseUrls = {
    'openai': 'https://openai.api.proxyapi.ru/v1',
    'grok': 'https://api.proxyapi.ru/openrouter/v1',
    'anthropic': 'https://openai.api.proxyapi.ru/v1',
    'deepseek': 'https://openai.api.proxyapi.ru/v1',
    'gemini': 'https://openai.api.proxyapi.ru/v1',
    'openrouter': 'https://api.proxyapi.ru/openrouter/v1',
    'custom': 'https://api.openai.com/v1',
  };

  static final Map<String, String> _supportedModels = {
    'openai': 'OpenAI',
    'grok': 'Grok',
    'anthropic': 'Anthropic',
    'deepseek': 'DeepSeek',
    'gemini': 'Gemini',
    'openrouter': 'OpenRouter',
    'custom': 'Custom',
  };

  static Future<OpenAI?> getOpenAI({String type = 'openai'}) async {
    type = type.toLowerCase();
    if (!_supportedModels.containsKey(type)) {
      throw ArgumentError('Unsupported model type: $type');
    }
    final result = await _db.query('model_settings').where('type', '=', type).limit(1);
    if (result.data.isEmpty) return null;
    final data = result.data.first;
    return OpenAI(
      name: _supportedModels[type]!,
      type: type,
      baseUrl: data['base_url'] as String? ?? _defaultBaseUrls[type],
      apiKey: data['api_key'] as String?,
      model: data['model'] as String? ?? _defaultModels[type],
      imagePath: 'assets/avatars/ai/$type.png',
    );
  }

  static Future<void> setOpenAI({
    String type = 'openai',
    String? baseUrl,
    String? apiKey,
    String? model,
  }) async {
    type = type.toLowerCase();
    if (!_supportedModels.containsKey(type)) {
      throw ArgumentError('Unsupported model type: $type');
    }
    final data = <String, dynamic>{'type': type};
    if (baseUrl != null) data['base_url'] = baseUrl;
    if (apiKey != null) data['api_key'] = apiKey;
    if (model != null) data['model'] = model;
    final existing = await _db.query('model_settings').where('type', '=', type).limit(1);
    if (existing.data.isNotEmpty) {
      await _db.update('model_settings', data).where('type', '=', type);
    } else {
      await _db.insert('model_settings', data);
    }
  }

  static Future<List<Contact>> getAllContacts() async {
    final List<Contact> loadedContacts = [];
    for (final entry in _supportedModels.entries) {
      final type = entry.key;
      final name = entry.value;
      String lastModel = _defaultModels[type] ?? '';
      final result = await _db.query('model_settings')
          .where('type', '=', type)
          .limit(1);
      if (result.data.isNotEmpty) {
        final data = result.data.first;
        lastModel = data['model'] as String? ?? _defaultModels[type] ?? '';
      }
      loadedContacts.add(
        Contact(
          name: name,
          type: type,
          imagePath: 'assets/avatars/ai/$type.png',
          subtitle: 'm/$lastModel',
        ),
      );
    }
    return loadedContacts;
  }
}