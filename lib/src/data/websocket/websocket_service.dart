import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';

abstract interface class WebsocketService {
  Stream<WsConnectionStateEnum> get connectionStateStream;
  Stream<BaseRawData> get rawDataStream;
  Stream<String?> get errorStream;

  Future<void> connect(String host, int port);
  Future<void> disconnect();

  Future<void> dispose();
}
