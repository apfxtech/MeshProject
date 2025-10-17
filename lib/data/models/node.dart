import '../../services/meshtastic.dart';

class Neighbor {
  Neighbor({
    required this.avgRssi,
    required this.avgSnr,
    required this.neighborId,
    required this.packetCount,
    required this.tracerouteCount,
  });

  factory Neighbor.fromJson(Map<String, dynamic> json) {
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

    return Neighbor(
      avgRssi: parseDouble(json['avg_rssi']) ?? 0.0,
      avgSnr: parseDouble(json['avg_snr']) ?? 0.0,
      neighborId: parseInt(json['neighbor_id']) ?? 0,
      packetCount: parseInt(json['packet_count']) ?? 0,
      tracerouteCount: parseInt(json['traceroute_count']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'avg_rssi': avgRssi,
        'avg_snr': avgSnr,
        'neighbor_id': neighborId,
        'packet_count': packetCount,
        'traceroute_count': tracerouteCount,
      };

  final double avgRssi;
  final double avgSnr;
  final int neighborId;
  final int packetCount;
  final int tracerouteCount;
}

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
    this.ageHours,
    this.avgSnr,
    this.directNeighbors,
    this.displayName,
    this.hexId,
    this.hwModelStr,
    this.lastSeenNetwork,
    this.neighbors,
    this.packetCount,
    this.precisionBits,
    this.precisionMeters,
    this.primaryChannel,
    this.roleStr,
    this.satsInView,
    this.timestamp,
    this.timestampStr,
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

  factory Node.fromStatsJson(Map<String, dynamic> json) {
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

    // bool parseBool(dynamic value) {
    //   if (value is bool) return value;
    //   if (value is int) return value != 0;
    //   if (value is String) return value.toLowerCase() == 'true' || value == '1';
    //   return false;
    // }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    List<Neighbor>? parseNeighbors(dynamic value) {
      if (value == null || value is! List) return null;
      return value.map((e) => Neighbor.fromJson(e as Map<String, dynamic>)).toList();
    }

    return Node(
      nodeNum: parseInt(json['node_id']) ?? 0,
      longName: json['long_name'] as String?,
      shortName: json['short_name'] as String?,
      hwModel: null,
      isLicensed: false,
      role: null,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      altitude: parseInt(json['altitude']),
      batteryLevel: null,
      voltage: null,
      channelUtilization: null,
      airUtilTx: null,
      channel: 0,
      lastHeard: parseDateTime(json['timestamp']),
      snr: parseDouble(json['avg_snr']) ?? 0.0,
      ageHours: parseDouble(json['age_hours']),
      avgSnr: parseDouble(json['avg_snr']),
      directNeighbors: parseInt(json['direct_neighbors']),
      displayName: json['display_name'] as String?,
      hexId: json['hex_id'] as String?,
      hwModelStr: json['hw_model'] as String?,
      lastSeenNetwork: parseDateTime(json['last_seen_network']),
      neighbors: parseNeighbors(json['neighbors']),
      packetCount: parseInt(json['packet_count']),
      precisionBits: parseInt(json['precision_bits']),
      precisionMeters: parseDouble(json['precision_meters']),
      primaryChannel: json['primary_channel'] as String?,
      roleStr: json['role'] as String?,
      satsInView: parseInt(json['sats_in_view']),
      timestamp: parseDouble(json['timestamp']),
      timestampStr: json['timestamp_str'] as String?,
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

  Map<String, dynamic> toStatsJson() => {
        'age_hours': ageHours,
        'altitude': altitude,
        'avg_snr': avgSnr,
        'direct_neighbors': directNeighbors,
        'display_name': displayName,
        'hex_id': hexId,
        'hw_model': hwModelStr,
        'last_seen_network': lastSeenNetwork != null ? (lastSeenNetwork!.millisecondsSinceEpoch / 1000) : null,
        'latitude': latitude,
        'long_name': longName,
        'longitude': longitude,
        'neighbors': neighbors?.map((e) => e.toJson()).toList(),
        'node_id': nodeNum,
        'packet_count': packetCount,
        'precision_bits': precisionBits,
        'precision_meters': precisionMeters,
        'primary_channel': primaryChannel,
        'role': roleStr,
        'sats_in_view': satsInView,
        'short_name': shortName,
        'timestamp': timestamp,
        'timestamp_str': timestampStr,
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

  final double? ageHours;
  final double? avgSnr;
  final int? directNeighbors;
  final String? displayName;
  final String? hexId;
  final String? hwModelStr;
  final DateTime? lastSeenNetwork;
  final List<Neighbor>? neighbors;
  final int? packetCount;
  final int? precisionBits;
  final double? precisionMeters;
  final String? primaryChannel;
  final String? roleStr;
  final int? satsInView;
  final double? timestamp;
  final String? timestampStr;
}