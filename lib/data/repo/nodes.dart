// lib/data/repo/nodes.dart (обновленный с обработкой String для lastHeard)
import 'dart:async';

import 'package:tostore/tostore.dart';

import '../../data/models/node.dart'; // Импорт модели Node (предполагаем путь)

const TableSchema nodesSchema = TableSchema(
  name: 'nodes',
  primaryKeyConfig: PrimaryKeyConfig(
    name: 'id',
    type: PrimaryKeyType.sequential,
    sequentialConfig: SequentialIdConfig(
      initialValue: 0,
      increment: 1,
      useRandomIncrement: false,
    ),
  ),
  fields: [
    FieldSchema(name: 'nodeNum', type: DataType.integer, nullable: true),
    FieldSchema(name: 'longName', type: DataType.text, nullable: true),
    FieldSchema(name: 'shortName', type: DataType.text, nullable: true),
    FieldSchema(name: 'hwModel', type: DataType.integer, nullable: true),
    FieldSchema(name: 'isLicensed', type: DataType.boolean, nullable: false),
    FieldSchema(name: 'role', type: DataType.integer, nullable: true),
    FieldSchema(name: 'latitude', type: DataType.double, nullable: true),
    FieldSchema(name: 'longitude', type: DataType.double, nullable: true),
    FieldSchema(name: 'altitude', type: DataType.integer, nullable: true),
    FieldSchema(name: 'batteryLevel', type: DataType.integer, nullable: true),
    FieldSchema(name: 'voltage', type: DataType.double, nullable: true),
    FieldSchema(
      name: 'channelUtilization',
      type: DataType.double,
      nullable: true,
    ),
    FieldSchema(name: 'airUtilTx', type: DataType.double, nullable: true),
    FieldSchema(name: 'channel', type: DataType.integer, nullable: false),
    FieldSchema(name: 'lastHeard', type: DataType.datetime, nullable: true),
    FieldSchema(name: 'snr', type: DataType.double, nullable: false),
  ],
  indexes: [
    IndexSchema(fields: ['nodeNum'], unique: true),
  ],
);

class NodeRepository {
  static late ToStore _db;

  static void setDb(ToStore db) {
    _db = db;
  }

  // Метод для преобразования Map из JSON-формата в формат для БД (конверт lastHeard в DateTime)
  static Map<String, dynamic> _toDbMap(Map<String, dynamic> jsonMap) {
    final dbMap = Map<String, dynamic>.from(jsonMap);
    if (dbMap['lastHeard'] != null) {
      final unixSeconds = dbMap['lastHeard'] as int;
      dbMap['lastHeard'] = DateTime.fromMillisecondsSinceEpoch(
        unixSeconds * 1000,
      );
    }
    return dbMap;
  }

  // Метод для преобразования Map из БД в JSON-формат (конверт lastHeard в unix seconds)
  static Map<String, dynamic> _toJsonMap(Map<String, dynamic> dbMap) {
    final jsonMap = Map<String, dynamic>.from(dbMap);
    if (jsonMap['lastHeard'] != null) {
      DateTime dateTime;
      if (jsonMap['lastHeard'] is String) {
        dateTime = DateTime.parse(jsonMap['lastHeard'] as String);
      } else {
        dateTime = jsonMap['lastHeard'] as DateTime;
      }
      jsonMap['lastHeard'] = dateTime.millisecondsSinceEpoch ~/ 1000;
    }
    return jsonMap;
  }

  // Добавление/обновление ноды (автоматически обновит, если существует)
  static Future<void> add(Node node) async {
    final map = _toDbMap(node.toJson());
    final query = _db.query('nodes').where('nodeNum', '=', node.nodeNum);
    final count = await query.count();
    if (count > 0) {
      await _db.update('nodes', map).where('nodeNum', '=', node.nodeNum);
    } else {
      await _db.insert('nodes', map);
    }
  }

  // Обновление существующей ноды (если не существует, ничего не сделает)
  static Future<void> update(Node node) async {
    final map = _toDbMap(node.toJson());
    await _db.update('nodes', map).where('nodeNum', '=', node.nodeNum);
  }

  // Удаление ноды по nodeNum
  static Future<void> remove(int nodeNum) async {
    await _db.delete('nodes').where('nodeNum', '=', nodeNum);
  }

  // Получение ноды по nodeNum (возвращает null, если не найдена)
  static Future<Node?> get(int nodeNum) async {
    final query = _db.query('nodes').where('nodeNum', '=', nodeNum).limit(1);
    final result = await query;
    if (result.data.isEmpty) {
      return null;
    }
    final dbMap = result.data.first;
    final jsonMap = _toJsonMap(dbMap);
    return Node.fromJson(jsonMap);
  }

  // Получение всех нод
  static Future<List<Node>> getAll() async {
    final query = _db.query('nodes');
    final result = await query;
    return result.data.map((dbMap) {
      final jsonMap = _toJsonMap(dbMap);
      return Node.fromJson(jsonMap);
    }).toList();
  }

  static Future<List<Node>> getByName(String name) async {
    final allNodes = await getAll();
    if (name.isEmpty) return allNodes;
    final lowerName = name.toLowerCase();
    return allNodes
        .where(
          (node) =>
              (node.longName?.toLowerCase().contains(lowerName) ?? false) ||
              (node.shortName?.toLowerCase().contains(lowerName) ?? false),
        )
        .toList();
  }
}
