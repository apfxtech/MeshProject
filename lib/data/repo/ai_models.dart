// lib/repositories/ai_model_repository.dart
import 'dart:async';
import '../models/contact.dart';

class AiModelRepository {
  Future<List<Contact>> getAllContacts() async {
    final contactsData = [
      {
        'name': 'Claude',
        'type': 'claude',
      },
      {
        'name': 'DeepSeek',
        'type': 'deepseek',
      },
      {
        'name': 'Gemini',
        'type': 'gemini',
      },
      {
        'name': 'Grok',
        'type': 'grok',
      },
      {
        'name': 'OpenAI',
        'type': 'openai',
      },
      {
        'name': 'OpenRouter',
        'type': 'openrouter',
      },
    ];
    final List<Contact> loadedContacts = [];
    for (final data in contactsData) {
      final lastModel = '';
      loadedContacts.add(
        Contact(
          name: data['name'] as String,
          type: data['type'] as String,
          imagePath: 'assets/avatars/ai/${data['type']}.png',
          subtitle: 'm/$lastModel',
        ),
      );
    }
    return loadedContacts;
  }
}