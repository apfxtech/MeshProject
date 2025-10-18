export 'src/meshtastic_client.dart';
export 'src/models/connection_state.dart';
export 'src/models/mesh_packet_wrapper.dart';
export 'src/models/node_info.dart';
export 'src/models/meshtastic_config.dart';
export 'src/exceptions/meshtastic_exceptions.dart';
export 'generated/mesh.pb.dart';
export 'generated/mesh.pbenum.dart';
export 'generated/config.pb.dart';
export 'generated/module_config.pb.dart';

import 'src/meshtastic_client.dart';

class MeshtasticOneClient {
  static final MeshtasticOneClient _singleton = MeshtasticOneClient._internal();
  MeshtasticClient? _client;
  MeshtasticOneClient._internal();
  factory MeshtasticOneClient() => _singleton;
  MeshtasticClient get() {
    _client ??= MeshtasticClient();
    return _client!;
  }

  MeshtasticClient call() => get();
}