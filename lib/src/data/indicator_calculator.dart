import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/models/indicator_config.dart';
import '../domain/models/k_line_data.dart';
import '../domain/models/k_line_dataset.dart';
import '../domain/models/k_line_indicators.dart';

/// 指标计算引擎。
///
/// [calculate] 生成全量指标列表，适合通过 [compute] 在 Isolate 中调用。
/// [updateLast] 增量更新最后一根，在主线程直接执行。
class IndicatorCalculator {
  const IndicatorCalculator(this.config);

  final IndicatorConfig config;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// 全量计算所有指标，返回新的 [KLineDataset]。
  ///
  /// 通过 [computeDataset] 在 Isolate 中调用。
  KLineDataset calculate(List<KLineData> candles) {
    final n = candles.length;
    final indicators = List.generate(n, (_) => KLineIndicators());

    if (n == 0) {
      return KLineDataset(candles: candles, indicators: indicators);
    }

    _calcMA(candles, indicators);
    _calcEMA(candles, indicators);
    _calcBOLL(candles, indicators);
    _calcVolMA(candles, indicators);
    _calcMACD(candles, indicators);
    _calcKDJ(candles, indicators);
    _calcRSI(candles, indicators);
    _calcWR(candles, indicators);

    return KLineDataset(candles: candles, indicators: indicators);
  }

  /// 增量更新最后一根 K 线的指标（主线程执行）。
  ///
  /// 当最后一根 K 线收到 tick 推送时调用，无需重算全量。
  void updateLast(KLineDataset dataset, KLineData updatedCandle) {
    if (dataset.isEmpty) return;

    final candles = List.of(dataset.candles)..[dataset.length - 1] = updatedCandle;
    final i = dataset.length - 1;
    final ind = dataset.indicators[i];

    _updateLastMA(candles, dataset.indicators, i, ind);
    _updateLastEMA(candles, dataset.indicators, i, ind);
    _updateLastBOLL(candles, i, ind);
    _updateLastVolMA(candles, i, ind);
    _updateLastMACD(dataset.indicators, i, ind);
    _updateLastKDJ(candles, dataset.indicators, i, ind);
    _updateLastRSI(candles, dataset.indicators, i, ind);
    _updateLastWR(candles, i, ind);
  }

  // ---------------------------------------------------------------------------
  // MA
  // ---------------------------------------------------------------------------

  void _calcMA(List<KLineData> candles, List<KLineIndicators> out) {
    final periods = config.maPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      double sum = 0;
      for (var i = 0; i < candles.length; i++) {
        sum += candles[i].close;
        if (i >= period) sum -= candles[i - period].close;
        if (i >= period - 1) {
          final val = sum / period;
          switch (p) {
            case 0:
              out[i].ma5 = val;
            case 1:
              out[i].ma10 = val;
            case 2:
              out[i].ma30 = val;
          }
        }
      }
    }
  }

  void _updateLastMA(List<KLineData> candles, List<KLineIndicators> out, int i, KLineIndicators ind) {
    final periods = config.maPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      if (i < period - 1) continue;
      double sum = 0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += candles[j].close;
      }
      final val = sum / period;
      switch (p) {
        case 0:
          ind.ma5 = val;
        case 1:
          ind.ma10 = val;
        case 2:
          ind.ma30 = val;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // EMA
  // ---------------------------------------------------------------------------

  void _calcEMA(List<KLineData> candles, List<KLineIndicators> out) {
    final periods = config.emaPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      final k = 2.0 / (period + 1);
      double? ema;
      for (var i = 0; i < candles.length; i++) {
        final close = candles[i].close;
        ema = ema == null ? close : close * k + ema * (1 - k);
        switch (p) {
          case 0:
            out[i].ema5 = ema;
          case 1:
            out[i].ema10 = ema;
          case 2:
            out[i].ema20 = ema;
        }
      }
    }
  }

  void _updateLastEMA(List<KLineData> candles, List<KLineIndicators> out, int i, KLineIndicators ind) {
    if (i == 0) {
      ind.ema5 = candles[0].close;
      ind.ema10 = candles[0].close;
      ind.ema20 = candles[0].close;
      return;
    }
    final periods = config.emaPeriods;
    final prev = out[i - 1];
    final close = candles[i].close;
    for (var p = 0; p < periods.length; p++) {
      final k = 2.0 / (periods[p] + 1);
      double? prevEma;
      switch (p) {
        case 0:
          prevEma = prev.ema5;
        case 1:
          prevEma = prev.ema10;
        case 2:
          prevEma = prev.ema20;
      }
      if (prevEma == null) continue;
      final val = close * k + prevEma * (1 - k);
      switch (p) {
        case 0:
          ind.ema5 = val;
        case 1:
          ind.ema10 = val;
        case 2:
          ind.ema20 = val;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BOLL
  // ---------------------------------------------------------------------------

  void _calcBOLL(List<KLineData> candles, List<KLineIndicators> out) {
    final period = config.bollPeriod;
    final stdMult = config.bollStdDev.toDouble();
    double sum = 0;
    for (var i = 0; i < candles.length; i++) {
      sum += candles[i].close;
      if (i >= period) sum -= candles[i - period].close;
      if (i >= period - 1) {
        final mid = sum / period;
        double variance = 0;
        for (var j = i - period + 1; j <= i; j++) {
          final diff = candles[j].close - mid;
          variance += diff * diff;
        }
        final std = math.sqrt(variance / period);
        out[i].bollMid = mid;
        out[i].bollUp = mid + stdMult * std;
        out[i].bollDn = mid - stdMult * std;
      }
    }
  }

  void _updateLastBOLL(List<KLineData> candles, int i, KLineIndicators ind) {
    final period = config.bollPeriod;
    if (i < period - 1) return;
    final stdMult = config.bollStdDev.toDouble();
    double sum = 0;
    for (var j = i - period + 1; j <= i; j++) {
      sum += candles[j].close;
    }
    final mid = sum / period;
    double variance = 0;
    for (var j = i - period + 1; j <= i; j++) {
      final diff = candles[j].close - mid;
      variance += diff * diff;
    }
    final std = math.sqrt(variance / period);
    ind.bollMid = mid;
    ind.bollUp = mid + stdMult * std;
    ind.bollDn = mid - stdMult * std;
  }

  // ---------------------------------------------------------------------------
  // VOL MA
  // ---------------------------------------------------------------------------

  void _calcVolMA(List<KLineData> candles, List<KLineIndicators> out) {
    for (final entry in [
      (5, true),
      (10, false),
    ]) {
      final period = entry.$1;
      final isFirst = entry.$2;
      double sum = 0;
      for (var i = 0; i < candles.length; i++) {
        sum += candles[i].volume;
        if (i >= period) sum -= candles[i - period].volume;
        if (i >= period - 1) {
          final val = sum / period;
          if (isFirst) {
            out[i].maVolume5 = val;
          } else {
            out[i].maVolume10 = val;
          }
        }
      }
    }
  }

  void _updateLastVolMA(List<KLineData> candles, int i, KLineIndicators ind) {
    for (final entry in [
      (5, true),
      (10, false),
    ]) {
      final period = entry.$1;
      final isFirst = entry.$2;
      if (i < period - 1) continue;
      double sum = 0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += candles[j].volume;
      }
      final val = sum / period;
      if (isFirst) {
        ind.maVolume5 = val;
      } else {
        ind.maVolume10 = val;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // MACD
  // ---------------------------------------------------------------------------

  void _calcMACD(List<KLineData> candles, List<KLineIndicators> out) {
    final fast = config.macdFast;
    final slow = config.macdSlow;
    final signal = config.macdSignal;
    final kFast = 2.0 / (fast + 1);
    final kSlow = 2.0 / (slow + 1);
    final kSignal = 2.0 / (signal + 1);

    double? emaFast, emaSlow, dea;
    for (var i = 0; i < candles.length; i++) {
      final close = candles[i].close;
      emaFast = emaFast == null ? close : close * kFast + emaFast * (1 - kFast);
      emaSlow = emaSlow == null ? close : close * kSlow + emaSlow * (1 - kSlow);
      final dif = emaFast - emaSlow;
      dea = dea == null ? dif : dif * kSignal + dea * (1 - kSignal);
      out[i].macdDif = dif;
      out[i].macdDea = dea;
      out[i].macdBar = (dif - dea) * 2;
    }
  }

  void _updateLastMACD(List<KLineIndicators> out, int i, KLineIndicators ind) {
    if (i == 0) return;
    final prev = out[i - 1];
    final prevDif = prev.macdDif;
    final prevDea = prev.macdDea;
    // EMA values not stored separately; re-derive from dif/dea is non-trivial.
    // For updateLast, we rely on re-running from the previous indicator's dif/dea.
    // This is an approximation: exact EMA state not stored.
    if (prevDif == null || prevDea == null) return;
    final kSignal = 2.0 / (config.macdSignal + 1);
    // dif stays, just update dea smoothing with current dif
    final dif = ind.macdDif ?? prevDif;
    final dea = dif * kSignal + prevDea * (1 - kSignal);
    ind.macdDea = dea;
    ind.macdBar = (dif - dea) * 2;
  }

  // ---------------------------------------------------------------------------
  // KDJ
  // ---------------------------------------------------------------------------

  void _calcKDJ(List<KLineData> candles, List<KLineIndicators> out) {
    final period = config.kdjPeriod;
    final m1 = config.kdjM1.toDouble();
    final m2 = config.kdjM2.toDouble();
    double k = 50, d = 50;

    for (var i = 0; i < candles.length; i++) {
      if (i < period - 1) {
        out[i].kdjK = 0;
        out[i].kdjD = 0;
        out[i].kdjJ = 0;
        continue;
      }
      double highest = candles[i].high;
      double lowest = candles[i].low;
      for (var j = i - period + 1; j < i; j++) {
        if (candles[j].high > highest) highest = candles[j].high;
        if (candles[j].low < lowest) lowest = candles[j].low;
      }
      final range = highest - lowest;
      final rsv = range == 0 ? 50.0 : (candles[i].close - lowest) / range * 100;
      k = (rsv + (m1 - 1) * k) / m1;
      d = (k + (m2 - 1) * d) / m2;
      final j = 3 * k - 2 * d;
      out[i].kdjK = k;
      out[i].kdjD = d;
      out[i].kdjJ = j;
    }
  }

  void _updateLastKDJ(List<KLineData> candles, List<KLineIndicators> out, int i, KLineIndicators ind) {
    final period = config.kdjPeriod;
    if (i < period - 1) {
      ind.kdjK = 0;
      ind.kdjD = 0;
      ind.kdjJ = 0;
      return;
    }
    final m1 = config.kdjM1.toDouble();
    final m2 = config.kdjM2.toDouble();
    double highest = candles[i].high;
    double lowest = candles[i].low;
    for (var j = i - period + 1; j < i; j++) {
      if (candles[j].high > highest) highest = candles[j].high;
      if (candles[j].low < lowest) lowest = candles[j].low;
    }
    final range = highest - lowest;
    final rsv = range == 0 ? 50.0 : (candles[i].close - lowest) / range * 100;
    final prevK = (i > 0 ? out[i - 1].kdjK : null) ?? 50.0;
    final prevD = (i > 0 ? out[i - 1].kdjD : null) ?? 50.0;
    final k = (rsv + (m1 - 1) * prevK) / m1;
    final d = (k + (m2 - 1) * prevD) / m2;
    ind.kdjK = k;
    ind.kdjD = d;
    ind.kdjJ = 3 * k - 2 * d;
  }

  // ---------------------------------------------------------------------------
  // RSI (Wilder EMA smoothing)
  // ---------------------------------------------------------------------------

  void _calcRSI(List<KLineData> candles, List<KLineIndicators> out) {
    final periods = config.rsiPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      double avgGain = 0, avgLoss = 0;
      for (var i = 1; i < candles.length; i++) {
        final change = candles[i].close - candles[i - 1].close;
        final gain = change > 0 ? change : 0.0;
        final loss = change < 0 ? -change : 0.0;
        if (i < period) {
          avgGain += gain;
          avgLoss += loss;
        } else if (i == period) {
          avgGain = (avgGain + gain) / period;
          avgLoss = (avgLoss + loss) / period;
          final rs = avgLoss == 0 ? double.infinity : avgGain / avgLoss;
          final rsi = avgLoss == 0 ? 100.0 : 100 - 100 / (1 + rs);
          _setRsi(out[i], p, rsi);
        } else {
          avgGain = (avgGain * (period - 1) + gain) / period;
          avgLoss = (avgLoss * (period - 1) + loss) / period;
          final rs = avgLoss == 0 ? double.infinity : avgGain / avgLoss;
          final rsi = avgLoss == 0 ? 100.0 : 100 - 100 / (1 + rs);
          _setRsi(out[i], p, rsi);
        }
      }
    }
  }

  void _setRsi(KLineIndicators ind, int p, double val) {
    switch (p) {
      case 0:
        ind.rsi6 = val;
      case 1:
        ind.rsi12 = val;
      case 2:
        ind.rsi24 = val;
    }
  }

  void _updateLastRSI(List<KLineData> candles, List<KLineIndicators> out, int i, KLineIndicators ind) {
    if (i == 0) return;
    // For updateLast, recalculate from scratch on the last period window.
    // Wilder EMA needs historical avgGain/avgLoss state, so we re-run a short window.
    final periods = config.rsiPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      if (i < period) continue;
      double avgGain = 0, avgLoss = 0;
      // Seed from i-period to i-(period/2) for efficiency (approx Wilder EMA)
      final start = (i - period * 3).clamp(1, i);
      for (var j = start; j <= i; j++) {
        final change = candles[j].close - candles[j - 1].close;
        final gain = change > 0 ? change : 0.0;
        final loss = change < 0 ? -change : 0.0;
        if (j - start < period) {
          avgGain += gain;
          avgLoss += loss;
          if (j - start == period - 1) {
            avgGain /= period;
            avgLoss /= period;
          }
        } else {
          avgGain = (avgGain * (period - 1) + gain) / period;
          avgLoss = (avgLoss * (period - 1) + loss) / period;
        }
      }
      final rs = avgLoss == 0 ? double.infinity : avgGain / avgLoss;
      final rsi = avgLoss == 0 ? 100.0 : 100 - 100 / (1 + rs);
      _setRsi(ind, p, rsi);
    }
  }

  // ---------------------------------------------------------------------------
  // WR (Williams %R)
  // ---------------------------------------------------------------------------

  void _calcWR(List<KLineData> candles, List<KLineIndicators> out) {
    final periods = config.wrPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      for (var i = period - 1; i < candles.length; i++) {
        double highest = candles[i].high;
        double lowest = candles[i].low;
        for (var j = i - period + 1; j < i; j++) {
          if (candles[j].high > highest) highest = candles[j].high;
          if (candles[j].low < lowest) lowest = candles[j].low;
        }
        final range = highest - lowest;
        final wr = range == 0 ? -50.0 : (highest - candles[i].close) / range * -100;
        if (p == 0) {
          out[i].wr4 = wr;
        } else {
          out[i].wr20 = wr;
        }
      }
    }
  }

  void _updateLastWR(List<KLineData> candles, int i, KLineIndicators ind) {
    final periods = config.wrPeriods;
    for (var p = 0; p < periods.length; p++) {
      final period = periods[p];
      if (i < period - 1) continue;
      double highest = candles[i].high;
      double lowest = candles[i].low;
      for (var j = i - period + 1; j < i; j++) {
        if (candles[j].high > highest) highest = candles[j].high;
        if (candles[j].low < lowest) lowest = candles[j].low;
      }
      final range = highest - lowest;
      final wr = range == 0 ? -50.0 : (highest - candles[i].close) / range * -100;
      if (p == 0) {
        ind.wr4 = wr;
      } else {
        ind.wr20 = wr;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Isolate entry point
// ---------------------------------------------------------------------------

/// Isolate payload for [computeDataset].
class _CalcPayload {
  _CalcPayload(this.candles, this.config);
  final List<KLineData> candles;
  final IndicatorConfig config;
}

/// 在 Isolate 中全量计算指标，返回新的 [KLineDataset]。
///
/// 传入参数仅含基础类型，满足 [compute] 限制。
Future<KLineDataset> computeDataset(
  List<KLineData> candles,
  IndicatorConfig config,
) {
  return compute(
    _isolateCalculate,
    _CalcPayload(candles, config),
  );
}

KLineDataset _isolateCalculate(_CalcPayload payload) {
  return IndicatorCalculator(payload.config).calculate(payload.candles);
}
