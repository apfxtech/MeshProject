// lib/data/repo/nodes.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:tostore/tostore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/node.dart';

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

  static void init(ToStore db) {
    _db = db;
  }

  static Map<String, dynamic> _toBaseMap(Map<String, dynamic> jsonMap) {
    final dbMap = Map<String, dynamic>.from(jsonMap);
    if (dbMap['lastHeard'] != null) {
      final unixSeconds = dbMap['lastHeard'] as int;
      dbMap['lastHeard'] = DateTime.fromMillisecondsSinceEpoch(
        unixSeconds * 1000,
      );
    }
    return dbMap;
  }

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

  static Future<void> add(Node node) async {
    final map = _toBaseMap(node.toJson());
    final query = _db.query('nodes').where('nodeNum', '=', node.nodeNum);
    final count = await query.count();
    if (count > 0) {
      await _db.update('nodes', map).where('nodeNum', '=', node.nodeNum);
    } else {
      await _db.insert('nodes', map);
    }
  }

  static Future<void> update(Node node) async {
    final map = _toBaseMap(node.toJson());
    await _db.update('nodes', map).where('nodeNum', '=', node.nodeNum);
  }

  static Future<void> remove(int nodeNum) async {
    await _db.delete('nodes').where('nodeNum', '=', nodeNum);
  }

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

  static Future<void> fetchLocations({
    required Function(Node) onNodeReceived,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('https://malla.meshworks.ru/api/locations?'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Запрос истёк'),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final locationsList = jsonData['locations'] as List<dynamic>?;

        if (locationsList == null || locationsList.isEmpty) return;

        for (final locationJson in locationsList) {
          try {
            final node = Node.fromStats(locationJson as Map<String, dynamic>);
            await NodeRepository.add(node);
            onNodeReceived(node);
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('Ошибка при обработке локации: $e');
            continue;
          }
        }

        debugPrint('${locationsList.length} локаций успешно сохранено в БД');
      } else {
        debugPrint('Ошибка при выполнении запроса: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка при получении локаций: $e');
      rethrow;
    }
  }
}
