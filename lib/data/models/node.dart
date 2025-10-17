import '../../services/meshtastic.dart';

class Node {
  Node({
    required this.nodeNum,
    this.longName,
    this.shortName,
    this.hwModel,
    required this.isLicensed,
    this.role,
    this.latitude,
    this.longitude,
    this.altitude,
    this.batteryLevel,
    this.voltage,
    this.channelUtilization,
    this.airUtilTx,
    required this.channel,
    this.lastHeard,
    required this.snr,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return Node(
      nodeNum: parseInt(json['nodeNum']) ?? 0,
      longName: json['longName'] as String?,
      shortName: json['shortName'] as String?,
      hwModel: parseInt(json['hwModel']) != null ? HardwareModel.valueOf(parseInt(json['hwModel'])!) : null,
      isLicensed: parseBool(json['isLicensed']),
      role: parseInt(json['role']) != null ? Config_DeviceConfig_Role.valueOf(parseInt(json['role'])!) : null,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      altitude: parseInt(json['altitude']),
      batteryLevel: parseInt(json['batteryLevel']),
      voltage: parseDouble(json['voltage']),
      channelUtilization: parseDouble(json['channelUtilization']),
      airUtilTx: parseDouble(json['airUtilTx']),
      channel: parseInt(json['channel']) ?? 0,
      lastHeard: json['lastHeard'] != null
          ? DateTime.fromMillisecondsSinceEpoch((parseInt(json['lastHeard']) ?? 0) * 1000)
          : null,
      snr: parseDouble(json['snr']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'nodeNum': nodeNum,
        'longName': longName,
        'shortName': shortName,
        'hwModel': hwModel?.value,
        'isLicensed': isLicensed,
        'role': role?.value,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'batteryLevel': batteryLevel,
        'voltage': voltage,
        'channelUtilization': channelUtilization,
        'airUtilTx': airUtilTx,
        'channel': channel,
        'lastHeard': lastHeard != null ? (lastHeard!.millisecondsSinceEpoch ~/ 1000) : null,
        'snr': snr,
      };

  final int nodeNum;
  final String? longName;
  final String? shortName;
  final HardwareModel? hwModel;
  final bool isLicensed;
  final Config_DeviceConfig_Role? role;
  final double? latitude;
  final double? longitude;
  final int? altitude;
  final int? batteryLevel;
  final double? voltage;
  final double? channelUtilization;
  final double? airUtilTx;
  final int channel;
  final DateTime? lastHeard;
  final double snr;
}