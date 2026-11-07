import 'dart:async';

import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/production_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';

final class ProductionRepository {
  final ProductionDao _dao;
  final WebsocketService _wsService;
  StreamSubscription? _wsSubscription;

  ProductionRepository(this._dao, this._wsService);

  // ==========================================
  // 1. ORQUESTRAÇÃO DO HARDWARE (O Maestro)
  // ==========================================

  /// Inicia a escuta dos sensores físicos.
  /// Deve ser chamado quando a aplicação/feature arrancar.
  void startListeningToHardware() {
    // Filtra o stream global para ouvir apenas os "Hits" da calha
    _wsSubscription = _wsService.rawDataStream
        .where((data) => data is HitRawData)
        .cast<HitRawData>()
        .listen(_onHitReceived);
  }

  void stopListeningToHardware() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
  }

  /// Interceta o JSON bruto do WebSocket e regista a linha do tempo no Drift
  Future<Result<Unit>> _onHitReceived(HitRawData hit) async {
    final batchResult = await _dao.getActiveBatch();

    if (batchResult.isError) {
      return Result.error(batchResult.errorOrThrow);
    }

    final batch = batchResult.valueOrThrow;

    if (batch == null) {
      return Result.error(
        BaseException(
          error: 'Nenhum lote ativo encontrado',
          stackTrace: StackTrace.current,
          tag: 'ProductionRepository-_onHitReceived',
        ),
      );
    }

    await _dao.logTimelineHit(batchId: batch.id, hardwareCount: hit.totalCount);
    return Result.ok(unit);
  }

  // ==========================================
  // 2. EXPOSIÇÃO PARA A UI (Signals / Controllers)
  // ==========================================

  Future<Result<String>> startProductionBatch({
    required String productId,
    required int currentHardwareCount,
  }) {
    return _dao.startBatch(
      productId: productId,
      initialCount: currentHardwareCount,
    );
  }

  Future<Result<Unit>> closeActiveBatch({
    required String batchId,
    required int finalCount,
  }) {
    return _dao.closeBatch(batchId: batchId, finalCount: finalCount);
  }

  Future<Result<Unit>> registerAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) {
    return _dao.addAdjustment(
      batchId: batchId,
      deltaQty: deltaQty,
      reason: reason,
      observation: observation,
    );
  }

  /// Retorna o fluxo reativo de estornos para a UI recalcular o total líquido
  Stream<int> watchAdjustments(String batchId) {
    return _dao.watchTotalAdjustments(batchId);
  }
}
