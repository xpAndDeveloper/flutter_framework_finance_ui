import 'package:flutter/foundation.dart';

/// 指标计算参数配置。
///
/// 视为不可变配置；运行时修改周期需全量重建 [KLineDataset]。
@immutable
class IndicatorConfig {
  const IndicatorConfig({
    this.maPeriods = const [5, 10, 30],
    this.emaPeriods = const [5, 10, 20],
    this.bollPeriod = 20,
    this.bollStdDev = 2,
    this.macdFast = 12,
    this.macdSlow = 26,
    this.macdSignal = 9,
    this.kdjPeriod = 9,
    this.kdjM1 = 3,
    this.kdjM2 = 3,
    this.rsiPeriods = const [6, 12, 24],
    this.wrPeriods = const [4, 20],
  })  : assert(maPeriods.length == 3, 'maPeriods 需要恰好 3 个周期'),
        assert(emaPeriods.length == 3, 'emaPeriods 需要恰好 3 个周期'),
        assert(rsiPeriods.length == 3, 'rsiPeriods 需要恰好 3 个周期'),
        assert(wrPeriods.length == 2, 'wrPeriods 需要恰好 2 个周期');

  /// MA 周期，对应 KLineIndicators.ma5/ma10/ma30，默认 [5, 10, 30]
  final List<int> maPeriods;

  /// EMA 周期，对应 KLineIndicators.ema5/ema10/ema20，默认 [5, 10, 20]
  final List<int> emaPeriods;

  final int bollPeriod;
  final int bollStdDev;

  final int macdFast;
  final int macdSlow;
  final int macdSignal;

  final int kdjPeriod;
  final int kdjM1;
  final int kdjM2;

  /// RSI 周期，对应 KLineIndicators.rsi6/rsi12/rsi24，默认 [6, 12, 24]
  final List<int> rsiPeriods;

  /// WR 周期，对应 KLineIndicators.wr4/wr20，默认 [4, 20]
  final List<int> wrPeriods;
}
