/// 单根 K 线的全量指标计算结果。
///
/// 固定字段设计（非 Map），渲染器直接字段访问，无哈希/装箱开销。
/// 字段名中的数字表示"第 N 条线"，具体周期由 [IndicatorConfig] 决定：
///   - ma5 → maPeriods[0]，ma10 → maPeriods[1]，ma30 → maPeriods[2]
///   - ema5 → emaPeriods[0]，ema10 → emaPeriods[1]，ema20 → emaPeriods[2]
///   - rsi6 → rsiPeriods[0]，rsi12 → rsiPeriods[1]，rsi24 → rsiPeriods[2]
///   - wr4 → wrPeriods[0]，wr20 → wrPeriods[1]
///
/// null 表示数据不足以计算该指标（如前 N 根数据的 MA(N) 为 null）。
class KLineIndicators {
  KLineIndicators({
    this.ma5,
    this.ma10,
    this.ma30,
    this.ema5,
    this.ema10,
    this.ema20,
    this.bollUp,
    this.bollMid,
    this.bollDn,
    this.maVolume5,
    this.maVolume10,
    this.macdDif,
    this.macdDea,
    this.macdBar,
    this.kdjK,
    this.kdjD,
    this.kdjJ,
    this.rsi6,
    this.rsi12,
    this.rsi24,
    this.wr4,
    this.wr20,
  });

  // MA（maPeriods[0/1/2]）
  double? ma5;
  double? ma10;
  double? ma30;

  // EMA（emaPeriods[0/1/2]）
  double? ema5;
  double? ema10;
  double? ema20;

  // BOLL
  double? bollUp;
  double? bollMid;
  double? bollDn;

  // VOL MA
  double? maVolume5;
  double? maVolume10;

  // MACD
  double? macdDif;
  double? macdDea;
  double? macdBar;

  // KDJ
  double? kdjK;
  double? kdjD;
  double? kdjJ;

  // RSI（rsiPeriods[0/1/2]）
  double? rsi6;
  double? rsi12;
  double? rsi24;

  // WR（wrPeriods[0/1]）
  double? wr4;
  double? wr20;
}
