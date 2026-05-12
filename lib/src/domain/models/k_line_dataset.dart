import 'k_line_data.dart';
import 'k_line_indicators.dart';

/// K 线数据集，持有原始数据与指标计算结果。
///
/// [candles] 与 [indicators] 长度始终相等，索引一一对应。
/// [version] 在每次数据更新后自增，供 [ChartPainter.shouldRepaint] 使用。
class KLineDataset {
  KLineDataset({
    required List<KLineData> candles,
    required List<KLineIndicators> indicators,
    this.version = 0,
  })  : assert(candles.length == indicators.length,
            'candles 与 indicators 长度必须相等'),
        candles = List.unmodifiable(candles),
        indicators = indicators;

  final List<KLineData> candles;

  /// 可变列表：[IndicatorCalculator.updateLast] 会直接替换 last 元素
  final List<KLineIndicators> indicators;

  /// 数据版本号，每次全量更新后自增
  final int version;

  int get length => candles.length;
  bool get isEmpty => candles.isEmpty;

  KLineDataset incrementVersion() => KLineDataset(
        candles: List.of(candles),
        indicators: indicators,
        version: version + 1,
      );
}
