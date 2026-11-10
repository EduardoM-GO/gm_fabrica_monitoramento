import 'package:gm_fabrica_monitoramento/src/domain/models/base_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_event_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/room_model.dart';

final class TelemetryModel extends BaseModel {
  final ProductionBatchModel batch;
  final List<FreezerEventModel> freezerEvents;
  final RoomModel? room;

  TelemetryModel({
    super.id,
    required this.freezerEvents,
    required this.room,
    required this.batch,
  });
}
