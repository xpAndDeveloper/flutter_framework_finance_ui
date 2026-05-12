import 'package:flutter/foundation.dart';

/// 单根 K 线原始数据（OHLCV）。
///
/// 轻量不可变对象，所有周期数据常驻内存。
/// 指标计算结果存储在单独的 [KLineIndicators] 中。
@immutable
class KLineData {
  const KLineData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  /// Unix 时间戳（秒）
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  KLineData copyWith({
    int? timestamp,
    double? open,
    double? high,
    double? low,
    double? close,
    double? volume,
  }) =>
      KLineData(
        timestamp: timestamp ?? this.timestamp,
        open: open ?? this.open,
        high: high ?? this.high,
        low: low ?? this.low,
        close: close ?? this.close,
        volume: volume ?? this.volume,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KLineData &&
          timestamp == other.timestamp &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume;

  @override
  int get hashCode =>
      Object.hash(timestamp, open, high, low, close, volume);
}
