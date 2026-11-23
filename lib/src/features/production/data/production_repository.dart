import 'dart:async';
import 'dart:math';

import 'package:gm_fabrica_monitoramento/src/core/exceptions/base_exception.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/production_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/remote/supabase_catalog_datasource.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/room_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/telemetry_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/daily_production_accounting_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

final class ProductionRepository {
  final ProductionDao _dao;
  final WebsocketService _wsService;
  final CatalogRemoteDatasource? remoteDatasource;

  StreamSubscription? _wsSubscription;
  Timer? _midnightTimer;
  Timer? _bufferFlushTimer;

  ProductionBatchModel? _activeBatch;
  DailyProductionAccountingModel _currentAccounting =
      DailyProductionAccountingModel.zero(DateTime.now());
  List<ProductModel> _availableProducts = const [];
  bool _isSyncingProducts = false;
  String? _lastProductsSyncError;
  RoomRawData? _currentRoom;
  int? _lastHardwareCount;
  int? _lastBootId;
  int _uncountedDiscardOffset = 0;

  // Streams reativos para a UI (latência zero - Hot Path)
  final _activeBatchController =
      StreamController<ProductionBatchModel?>.broadcast();
  final _hitEventController =
      StreamController<
        ({int rawHardwareCount, int delta, bool isDirectHit})
      >.broadcast();
  final _conveyorWithoutBatchController =
      StreamController<bool>.broadcast();
  final _dailyAccountingController =
      StreamController<DailyProductionAccountingModel>.broadcast();
  final _productsController =
      StreamController<List<ProductModel>>.broadcast();
  final _productsLoadingController = StreamController<bool>.broadcast();
  final _productsErrorController = StreamController<String?>.broadcast();
  final _roomController = StreamController<RoomRawData?>.broadcast();

  // Buffer em segundo plano para persistência no Drift SQLite (Warm Path)
  final List<({String batchId, int hardwareCount, DateTime timestamp})>
  _hitBuffer = [];

  ProductionRepository(
    this._dao,
    this._wsService, {
    this.remoteDatasource,
  }) {
    _startHardwareListener();
    _init();
  }

  Stream<ProductionBatchModel?> get activeBatchStream =>
      _activeBatchController.stream;
  Stream<({int rawHardwareCount, int delta, bool isDirectHit})>
  get hitEventStream => _hitEventController.stream;
  Stream<bool> get conveyorWithoutBatchStream =>
      _conveyorWithoutBatchController.stream;
  Stream<DailyProductionAccountingModel> get dailyAccountingStream =>
      _dailyAccountingController.stream;
  Stream<List<ProductModel>> get availableProductsStream =>
      _productsController.stream;
  Stream<bool> get isSyncingProductsStream =>
      _productsLoadingController.stream;
  Stream<String?> get productsSyncErrorStream =>
      _productsErrorController.stream;
  Stream<RoomRawData?> get roomStream => _roomController.stream;

  ProductionBatchModel? get currentActiveBatch => _activeBatch;
  DailyProductionAccountingModel get currentDailyAccounting =>
      _currentAccounting;
  List<ProductModel> get currentProducts => _availableProducts;
  bool get isSyncingProducts => _isSyncingProducts;
  String? get lastProductsSyncError => _lastProductsSyncError;
  RoomRawData? get currentRoom => _currentRoom;

  Future<void> _init() async {
    // 1. Carrega produtos já sincronizados no SQLite local (zero mocks)
    final localProductsResult = await _dao.getActiveProducts();
    if (localProductsResult.isOk) {
      _availableProducts = localProductsResult.valueOrThrow;
      if (!_productsController.isClosed) {
        _productsController.add(_availableProducts);
      }
    }

    // 2. Verifica e encerra qualquer lote deixado aberto em dias anteriores
    await checkAndCloseExpiredBatches();

    // 3. Carrega lote ativo atual (se houver para o dia de hoje)
    final activeResult = await _dao.getActiveBatch();
    if (activeResult.isOk) {
      _activeBatch = activeResult.valueOrThrow;
      if (_activeBatch != null) {
        _lastHardwareCount = _activeBatch!.actualQuantity;
      }
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }
    }

    // 4. Emite a contabilidade inicial do dia
    await refreshDailyAccounting();

    // 5. Agenda timer para a virada da meia-noite (00:00:00)
    _scheduleMidnightTimer();

    // 6. Busca produtos reais do Supabase (e escuta atualizações se disponível)
    await refreshProductsFromSupabase();
  }

  /// Busca os produtos ativos da tabela `public.products` no Supabase e
  /// atualiza o cache local no SQLite (sem dados mockados).
  Future<Result<List<ProductModel>>> refreshProductsFromSupabase() =>
      Result.catchInAsync(
        fn: () async {
          final remote = remoteDatasource;
          if (remote == null) {
            final localRes = await _dao.getActiveProducts();
            if (localRes.isOk) {
              _availableProducts = localRes.valueOrThrow;
              if (!_productsController.isClosed) {
                _productsController.add(_availableProducts);
              }
            }
            return _availableProducts;
          }

          _isSyncingProducts = true;
          _lastProductsSyncError = null;
          if (!_productsLoadingController.isClosed) {
            _productsLoadingController.add(true);
          }
          if (!_productsErrorController.isClosed) {
            _productsErrorController.add(null);
          }

          try {
            final remoteProducts = await remote.fetchActiveProducts();
            final syncRes = await _dao.syncProductsFromSupabase(remoteProducts);
            if (syncRes.isOk) {
              _availableProducts = syncRes.valueOrThrow;
              if (!_productsController.isClosed) {
                _productsController.add(_availableProducts);
              }

              // Se o lote ativo pertence a um dos produtos atualizados, sincroniza seus metadados
              if (_activeBatch != null) {
                final updatedProd = _availableProducts
                    .where((p) => p.id == _activeBatch!.product.id)
                    .firstOrNull;
                if (updatedProd != null) {
                  _activeBatch = _activeBatch!.copyWith(product: updatedProd);
                  if (!_activeBatchController.isClosed) {
                    _activeBatchController.add(_activeBatch);
                  }
                }
              }
            }
            return _availableProducts;
          } catch (e) {
            _lastProductsSyncError =
                'Não foi possível buscar produtos no Supabase.';
            if (!_productsErrorController.isClosed) {
              _productsErrorController.add(_lastProductsSyncError);
            }
            // Mantém os produtos já sincronizados no SQLite local caso esteja offline
            final localRes = await _dao.getActiveProducts();
            if (localRes.isOk) {
              _availableProducts = localRes.valueOrThrow;
              if (!_productsController.isClosed) {
                _productsController.add(_availableProducts);
              }
            }
            rethrow;
          } finally {
            _isSyncingProducts = false;
            if (!_productsLoadingController.isClosed) {
              _productsLoadingController.add(false);
            }
          }
        },
        tag: 'ProductionRepository.refreshProductsFromSupabase',
      );

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now) + const Duration(seconds: 1);

    _midnightTimer = Timer(duration, () async {
      await checkAndCloseExpiredBatches();
      await refreshDailyAccounting();
      _scheduleMidnightTimer();
    });
  }

  /// Verifica se virou o dia e finaliza automaticamente lotes pendentes
  Future<Result<int>> checkAndCloseExpiredBatches() async {
    await _flushBuffer();

    final result = await _dao.autoCloseExpiredBatches();
    if (result.isOk && result.valueOrThrow > 0) {
      if (_activeBatch != null && !_isToday(_activeBatch!.startedAt)) {
        _activeBatch = null;
        if (!_activeBatchController.isClosed) {
          _activeBatchController.add(null);
        }
      }
    }
    return result;
  }

  void _startHardwareListener() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.rawDataStream.listen((data) {
      if (data is HitRawData) {
        _handleHardwarePulse(data.totalCount, isDirectHit: true);
      } else if (data is TelemetryRawData) {
        if (data.room != null) {
          _currentRoom = data.room;
          if (!_roomController.isClosed) {
            _roomController.add(_currentRoom);
          }
        }
        if (_lastBootId != null && data.bootId != _lastBootId) {
          _lastHardwareCount = null;
        }
        _lastBootId = data.bootId;
        _handleHardwarePulse(data.totalCount, isDirectHit: false);
      }
    });
  }

  /// Processa pulso de contagem recebido do hardware com máxima segurança e velocidade (0ms Hot Path)
  void _handleHardwarePulse(int rawHardwareCount, {required bool isDirectHit}) {
    final now = DateTime.now();

    if (_activeBatch != null && !_isToday(_activeBatch!.startedAt)) {
      checkAndCloseExpiredBatches();
      refreshDailyAccounting();
      return;
    }

    int delta = 0;
    if (_lastHardwareCount == null) {
      _lastHardwareCount = rawHardwareCount;
      delta = isDirectHit ? 1 : 0;
    } else if (rawHardwareCount >= _lastHardwareCount!) {
      delta = rawHardwareCount - _lastHardwareCount!;
      if (isDirectHit && delta == 0) {
        delta = 1;
      }
    } else {
      delta = rawHardwareCount > 0 ? rawHardwareCount : (isDirectHit ? 1 : 0);
    }

    _lastHardwareCount = rawHardwareCount;

    if (_activeBatch == null) {
      if (delta > 0 && !_conveyorWithoutBatchController.isClosed) {
        _conveyorWithoutBatchController.add(true);
      }
      return;
    }

    if (!_conveyorWithoutBatchController.isClosed) {
      _conveyorWithoutBatchController.add(false);
    }

    if (delta > 0) {
      final boxCap = _activeBatch!.product.defaultBoxCapacity > 0
          ? _activeBatch!.product.defaultBoxCapacity
          : 50;

      final updatedActual = _activeBatch!.actualQuantity + delta;
      _activeBatch = _activeBatch!.copyWith(actualQuantity: updatedActual);
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }

      final newDailyGross = _currentAccounting.grossCount + delta;
      final newDailyNet =
          (newDailyGross +
                  _uncountedDiscardOffset -
                  _currentAccounting.discardsCount)
              .clamp(0, 99999999);
      _currentAccounting = _currentAccounting.copyWith(
        grossCount: newDailyGross,
        netCount: newDailyNet,
        completedBoxes: newDailyNet ~/ boxCap,
      );
      if (!_dailyAccountingController.isClosed) {
        _dailyAccountingController.add(_currentAccounting);
      }

      if (!_hitEventController.isClosed) {
        _hitEventController.add((
          rawHardwareCount: rawHardwareCount,
          delta: delta,
          isDirectHit: isDirectHit,
        ));
      }

      _queueHitForPersistence(_activeBatch!.id, updatedActual, now);
    }
  }

  void _queueHitForPersistence(
    String batchId,
    int hardwareCount,
    DateTime timestamp,
  ) {
    _hitBuffer.add((
      batchId: batchId,
      hardwareCount: hardwareCount,
      timestamp: timestamp,
    ));

    if (_hitBuffer.length >= 10) {
      _flushBuffer();
    } else {
      _bufferFlushTimer ??= Timer(
        const Duration(milliseconds: 1500),
        _flushBuffer,
      );
    }
  }

  Future<void> _flushBuffer() async {
    _bufferFlushTimer?.cancel();
    _bufferFlushTimer = null;

    if (_hitBuffer.isEmpty) return;

    final hitsToWrite =
        List<({String batchId, int hardwareCount, DateTime timestamp})>.from(
          _hitBuffer,
        );
    _hitBuffer.clear();

    final lastHit = hitsToWrite.last;
    await _dao.batchLogTimelineHits(hitsToWrite);
    await _dao.updateBatchProgress(
      batchId: lastHit.batchId,
      actualHardwareCount: lastHit.hardwareCount,
    );
  }

  /// Inicia um novo lote de produção para um produto real.
  /// Regra de negócio: proibido iniciar outro produto sem antes encerrar o lote atual.
  Future<Result<ProductionBatchModel>> startProductionBatch({
    required ProductModel product,
  }) => Result.catchInAsync(
    fn: () async {
      await checkAndCloseExpiredBatches();

      final activeResult = await _dao.getActiveBatch();
      if (_activeBatch != null ||
          (activeResult.isOk && activeResult.valueOrThrow != null)) {
        throw BaseException(
          error: 'Encerre o lote atual antes de iniciar outro produto.',
          stackTrace: StackTrace.current,
          tag: 'ProductionRepository.startProductionBatch',
        );
      }

      final result = await _dao.startBatch(
        product: product,
        currentHardwareCount: _lastHardwareCount,
      );

      if (result.isError) {
        throw result.errorOrThrow;
      }

      _activeBatch = result.valueOrThrow;
      _lastHardwareCount = _activeBatch!.actualQuantity;
      if (!_activeBatchController.isClosed) {
        _activeBatchController.add(_activeBatch);
      }
      if (!_conveyorWithoutBatchController.isClosed) {
        _conveyorWithoutBatchController.add(false);
      }

      // Garante que o produto selecionado conste na lista em memória
      if (!_availableProducts.any((p) => p.id == product.id)) {
        _availableProducts = [..._availableProducts, product];
        if (!_productsController.isClosed) {
          _productsController.add(_availableProducts);
        }
      }

      await refreshDailyAccounting();
      return _activeBatch!;
    },
    tag: 'ProductionRepository.startProductionBatch',
  );

  /// Fecha manualmente o lote ativo
  Future<Result<Unit>> closeActiveBatch({ProductionBatchModel? batch}) =>
      Result.catchInAsync(
        fn: () async {
          final targetBatch = batch ?? _activeBatch;
          if (targetBatch == null) return unit;

          await _flushBuffer();

          final result = await _dao.closeBatch(batch: targetBatch);
          if (result.isError) {
            throw result.errorOrThrow;
          }

          if (_activeBatch?.id == targetBatch.id) {
            _activeBatch = null;
            if (!_activeBatchController.isClosed) {
              _activeBatchController.add(null);
            }
          }

          await refreshDailyAccounting();
          return unit;
        },
        tag: 'ProductionRepository.closeActiveBatch',
      );

  /// Registra ajuste (quebra/descarte com deltaQty < 0 ou adição manual com deltaQty > 0)
  /// com atualização imediata em memória (0ms Hot Path).
  Future<Result<Unit>> registerAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) async {
    await _flushBuffer();

    final boxCap =
        (_activeBatch?.product.defaultBoxCapacity ?? 50) > 0
            ? (_activeBatch?.product.defaultBoxCapacity ?? 50)
            : 50;

    if (deltaQty < 0) {
      final addedDiscards = deltaQty.abs();
      final excessOverNet = max(0, addedDiscards - _currentAccounting.netCount);
      _uncountedDiscardOffset += excessOverNet;

      final updatedDiscards = _currentAccounting.discardsCount + addedDiscards;
      final updatedNet =
          (_currentAccounting.netCount - addedDiscards).clamp(0, 99999999);
      _currentAccounting = _currentAccounting.copyWith(
        discardsCount: updatedDiscards,
        netCount: updatedNet,
        completedBoxes: updatedNet ~/ boxCap,
      );
    } else if (deltaQty > 0) {
      final updatedGross = _currentAccounting.grossCount + deltaQty;
      final updatedNet = (_currentAccounting.netCount + deltaQty).clamp(
        0,
        99999999,
      );
      _currentAccounting = _currentAccounting.copyWith(
        grossCount: updatedGross,
        netCount: updatedNet,
        completedBoxes: updatedNet ~/ boxCap,
      );
    }
    if (!_dailyAccountingController.isClosed) {
      _dailyAccountingController.add(_currentAccounting);
    }

    final result = await _dao.addAdjustment(
      batchId: batchId,
      deltaQty: deltaQty,
      reason: reason,
      observation: observation,
    );

    if (result.isOk) {
      await refreshDailyAccounting();
    }
    return result;
  }

  /// Busca e atualiza a contabilidade diária de ovos
  Future<Result<DailyProductionAccountingModel>> refreshDailyAccounting({
    DateTime? date,
  }) async {
    final result = await _dao.getDailyAccounting(date: date);
    if (result.isOk) {
      var accounting = result.valueOrThrow;
      final boxCap =
          (_activeBatch?.product.defaultBoxCapacity ?? 50) > 0
              ? (_activeBatch?.product.defaultBoxCapacity ?? 50)
              : 50;

      final resolvedGross = (_hitBuffer.isNotEmpty &&
              _currentAccounting.grossCount > accounting.grossCount)
          ? _currentAccounting.grossCount
          : accounting.grossCount;

      final resolvedNet =
          (resolvedGross + _uncountedDiscardOffset - accounting.discardsCount)
              .clamp(0, 99999999);

      accounting = accounting.copyWith(
        grossCount: resolvedGross,
        netCount: resolvedNet,
        completedBoxes: _activeBatch != null
            ? (resolvedNet ~/ boxCap)
            : accounting.completedBoxes,
      );

      _currentAccounting = accounting;
      if (!_dailyAccountingController.isClosed) {
        _dailyAccountingController.add(_currentAccounting);
      }
    }
    return result;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void dispose() {
    _wsSubscription?.cancel();
    _midnightTimer?.cancel();
    _bufferFlushTimer?.cancel();
    _flushBuffer();
    _activeBatchController.close();
    _hitEventController.close();
    _conveyorWithoutBatchController.close();
    _dailyAccountingController.close();
    _productsController.close();
    _productsLoadingController.close();
    _productsErrorController.close();
    _roomController.close();
  }
}
