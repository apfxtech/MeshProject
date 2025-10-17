import 'dart:async';
import 'package:tostore/tostore.dart';
import '../models/openai.dart';

const TableSchema settingsSchema = TableSchema(
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
    FieldSchema(name: 'base_url', type: DataType.text, nullable: true),
    FieldSchema(name: 'api_key', type: DataType.text, nullable: true),
  ],
  indexes: [
    IndexSchema(fields: ['id'], unique: true),
  ],
);

class SettingsRepository {
  static late ToStore _db;

  static void setDb(ToStore db) {
    _db = db;
  }

  static Future<OpenAI?> getOpenAI() async {
    final result = await _db.query('settings').limit(1);
    if (result.data.isEmpty) return null;
    return OpenAI.fromJson(result.data.first);
  }

  static Future<void> setOpenAI({
    required String baseUrl,
    required String apiKey,
  }) async {
    final data = OpenAI(baseUrl: baseUrl, apiKey: apiKey).toJson();
    await _db.insert('settings', data);
  }
}
