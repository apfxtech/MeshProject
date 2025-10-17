import 'dart:async';

import 'package:tostore/tostore.dart';

import '../../data/models/chat.dart';
import '../../data/models/message.dart';

const TableSchema chatsSchema = TableSchema(
  name: 'chats',
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
    FieldSchema(name: 'ti', type: DataType.text, nullable: false),
    FieldSchema(name: 'sk', type: DataType.text, nullable: true),
    FieldSchema(name: 'as', type: DataType.text, nullable: true),
    FieldSchema(name: 'sc', type: DataType.text, nullable: true),
    FieldSchema(name: 'tm', type: DataType.double, nullable: false),
    FieldSchema(name: 'tp', type: DataType.double, nullable: false),
    FieldSchema(name: 'mt', type: DataType.integer, nullable: false),
    FieldSchema(name: 'sm', type: DataType.text, nullable: true),
    FieldSchema(name: 'om', type: DataType.text, nullable: true),
  ],
  indexes: [
    IndexSchema(fields: ['id'], unique: true),
  ],
);

const TableSchema messagesSchema = TableSchema(
  name: 'messages',
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
    FieldSchema(name: 'ci', type: DataType.integer, nullable: false),
    FieldSchema(name: 'rl', type: DataType.text, nullable: false),
    FieldSchema(name: 'ct', type: DataType.text, nullable: false),
    FieldSchema(name: 'fm', type: DataType.text, nullable: true),
    FieldSchema(name: 'hp', type: DataType.integer, nullable: false),
    FieldSchema(name: 'to', type: DataType.text, nullable: true),
    FieldSchema(name: 'dt', type: DataType.datetime, nullable: true),
  ],
  indexes: [
    IndexSchema(fields: ['id'], unique: true),
    IndexSchema(fields: ['ci']),
  ],
);

class ChatsRepository {
  static late ToStore _db;

  static void setDb(ToStore db) {
    _db = db;
  }

  static Map<String, dynamic> _messageToDbMap(Map<String, dynamic> jsonMap) {
    final dbMap = Map<String, dynamic>.from(jsonMap);
    if (dbMap['dt'] != null) {
      dbMap['dt'] = DateTime.parse(dbMap['dt'] as String);
    }
    return dbMap;
  }

  static Map<String, dynamic> _messageToJsonMap(Map<String, dynamic> dbMap) {
    final jsonMap = Map<String, dynamic>.from(dbMap);
    if (jsonMap['dt'] != null) {
      final dateTime = jsonMap['dt'] is String
          ? DateTime.parse(jsonMap['dt'])
          : jsonMap['dt'] as DateTime;
      jsonMap['dt'] = dateTime.toIso8601String();
    }
    return jsonMap;
  }

  static Future<List<Chat>> get() async {
    final result = await _db.query('chats');
    return result.data.map((dbMap) => Chat.fromJson(dbMap)).toList();
  }

  static Future<int> add(Chat chat) async {
    var map = chat.toJson();
    if (chat.id != 0) {
      final count = await _db.query('chats').where('id', '=', chat.id).count();
      if (count > 0) {
        await _db.update('chats', map).where('id', '=', chat.id);
        return chat.id;
      }
    }
    map.remove('id');
    await _db.insert('chats', map);
    final result = await _db.query('chats').orderByDesc('id').limit(1);
    if (result.data.isEmpty) {
      throw Exception('Failed to get inserted chat id');
    }
    // Фикс ошибки: парсим 'id' как строку и конвертируем в int
    return int.parse(result.data.first['id'].toString());
  }

  static Future<void> update(Chat chat) async {
    await _db.update('chats', chat.toJson()).where('id', '=', chat.id);
  }

  static Future<void> rename(int id, String newTitle) async {
    await _db.update('chats', {'ti': newTitle}).where('id', '=', id);
  }

  static Future<void> remove(int id) async {
    await _db.delete('messages').where('ci', '=', id);
    await _db.delete('chats').where('id', '=', id);
  }

  static Future<Chat?> getChat(int id) async {
    final result = await _db.query('chats').where('id', '=', id).limit(1);
    if (result.data.isEmpty) {
      return null;
    }
    return Chat.fromJson(result.data.first);
  }

  static Future<Chat?> getBySource(String source) async {
    final result = await _db.query('chats').where('sc', '=', source).limit(1);
    if (result.data.isEmpty) {
      return null;
    }
    return Chat.fromJson(result.data.first);
  }

  static Future<Chat?> getBySourceAndAssistant(
    String source,
    String assistant,
  ) async {
    final result = await _db
        .query('chats')
        .where('sc', '=', source)
        .where('as', '=', assistant)
        .limit(1);
    if (result.data.isEmpty) {
      return null;
    }
    return Chat.fromJson(result.data.first);
  }

  static Messages messages(int chatId) => Messages(chatId);
}

class Messages {
  final int chatId;

  Messages(this.chatId);

  Future<List<Message>> get() async {
    final result = await ChatsRepository._db
        .query('messages')
        .where('ci', '=', chatId);
    return result.data.map((dbMap) {
      final jsonMap = ChatsRepository._messageToJsonMap(dbMap);
      jsonMap.remove('ci');
      return Message.fromJson(jsonMap);
    }).toList();
  }

  Future<int> add(Message message) async {
    var map = ChatsRepository._messageToDbMap(message.toJson());
    map['ci'] = chatId;
    if (message.id != 0) {
      final count = await ChatsRepository._db
          .query('messages')
          .where('id', '=', message.id)
          .count();
      if (count > 0) {
        await ChatsRepository._db
            .update('messages', map)
            .where('id', '=', message.id);
        return message.id;
      }
    }
    map.remove('id');
    await ChatsRepository._db.insert('messages', map);
    final result = await ChatsRepository._db
        .query('messages')
        .orderByDesc('id')
        .limit(1);
    if (result.data.isEmpty) {
      throw Exception('Failed to get inserted message id');
    }
    return int.parse(result.data.first['id'].toString());
  }

  Future<void> edit(int id, String newContent) async {
    await ChatsRepository._db
        .update('messages', {'ct': newContent})
        .where('id', '=', id);
  }

  Future<void> remove(int id) async {
    await ChatsRepository._db.delete('messages').where('id', '=', id);
  }
}
