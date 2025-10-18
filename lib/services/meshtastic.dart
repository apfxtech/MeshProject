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
  // единственный экземпляр-обёртка
  static final MeshtasticOneClient _singleton = MeshtasticOneClient._internal();

  // реальный клиент (ленивая инициализация)
  MeshtasticClient? _client;

  MeshtasticOneClient._internal();

  factory MeshtasticOneClient() => _singleton;

  /// Возвращает реальный MeshtasticClient, создаёт его при первом вызове.
  MeshtasticClient get() {
    _client ??= MeshtasticClient();
    return _client!;
  }

  /// Альтернативно: можно вызвать экземпляр как функцию: MeshtasticOneClient()()
  MeshtasticClient call() => get();
}