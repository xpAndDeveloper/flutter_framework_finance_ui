import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/k_line_data.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/k_line_indicators.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/k_line_dataset.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/indicator_config.dart';

void main() {
  group('KLineData', () {
    const data = KLineData(
      timestamp: 1000,
      open: 10.0,
      high: 15.0,
      low: 8.0,
      close: 12.0,
      volume: 1000.0,
    );

    test('equality: identical fields are equal', () {
      const other = KLineData(
        timestamp: 1000,
        open: 10.0,
        high: 15.0,
        low: 8.0,
        close: 12.0,
        volume: 1000.0,
      );
      expect(data, equals(other));
    });

    test('equality: different timestamp is not equal', () {
      const other = KLineData(
        timestamp: 2000,
        open: 10.0,
        high: 15.0,
        low: 8.0,
        close: 12.0,
        volume: 1000.0,
      );
      expect(data, isNot(equals(other)));
    });

    test('hashCode: equal objects have same hashCode', () {
      const other = KLineData(
        timestamp: 1000,
        open: 10.0,
        high: 15.0,
        low: 8.0,
        close: 12.0,
        volume: 1000.0,
      );
      expect(data.hashCode, equals(other.hashCode));
    });

    test('copyWith: overrides specified fields', () {
      final copy = data.copyWith(close: 99.0, volume: 500.0);
      expect(copy.close, 99.0);
      expect(copy.volume, 500.0);
      expect(copy.timestamp, data.timestamp);
      expect(copy.open, data.open);
      expect(copy.high, data.high);
      expect(copy.low, data.low);
    });

    test('copyWith: without args returns equal object', () {
      final copy = data.copyWith();
      expect(copy, equals(data));
    });
  });

  group('KLineIndicators', () {
    test('all fields default to null', () {
      final ind = KLineIndicators();
      expect(ind.ma5, isNull);
      expect(ind.ma10, isNull);
      expect(ind.ma30, isNull);
      expect(ind.ema5, isNull);
      expect(ind.macdDif, isNull);
      expect(ind.kdjK, isNull);
      expect(ind.rsi6, isNull);
      expect(ind.wr4, isNull);
    });

    test('fields are mutable', () {
      final ind = KLineIndicators();
      ind.ma5 = 10.5;
      ind.bollUp = 20.0;
      expect(ind.ma5, 10.5);
      expect(ind.bollUp, 20.0);
    });

    test('constructor sets provided fields', () {
      final ind = KLineIndicators(ma5: 1.0, ema20: 2.0, macdBar: 0.5);
      expect(ind.ma5, 1.0);
      expect(ind.ema20, 2.0);
      expect(ind.macdBar, 0.5);
      expect(ind.ma10, isNull);
    });
  });

  group('KLineDataset', () {
    KLineData makeCandle(int ts) => KLineData(
          timestamp: ts,
          open: 1.0,
          high: 2.0,
          low: 0.5,
          close: 1.5,
          volume: 100.0,
        );

    test('length returns candle count', () {
      final candles = [makeCandle(1), makeCandle(2), makeCandle(3)];
      final indicators = [KLineIndicators(), KLineIndicators(), KLineIndicators()];
      final ds = KLineDataset(candles: candles, indicators: indicators);
      expect(ds.length, 3);
    });

    test('isEmpty is true for empty dataset', () {
      final ds = KLineDataset(candles: [], indicators: []);
      expect(ds.isEmpty, isTrue);
    });

    test('candles list is unmodifiable', () {
      final candles = [makeCandle(1)];
      final indicators = [KLineIndicators()];
      final ds = KLineDataset(candles: candles, indicators: indicators);
      expect(() => (ds.candles as dynamic).add(makeCandle(2)), throwsUnsupportedError);
    });

    test('assert: mismatched candles and indicators lengths throws', () {
      expect(
        () => KLineDataset(
          candles: [makeCandle(1), makeCandle(2)],
          indicators: [KLineIndicators()],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('incrementVersion: version increases by 1', () {
      final candles = [makeCandle(1)];
      final indicators = [KLineIndicators()];
      final ds = KLineDataset(candles: candles, indicators: indicators, version: 5);
      final next = ds.incrementVersion();
      expect(next.version, 6);
    });

    test('incrementVersion: preserves candles and indicators', () {
      final candles = [makeCandle(42)];
      final indicators = [KLineIndicators()..ma5 = 7.0];
      final ds = KLineDataset(candles: candles, indicators: indicators);
      final next = ds.incrementVersion();
      expect(next.candles.first.timestamp, 42);
      expect(next.indicators.first.ma5, 7.0);
    });

    test('default version is 0', () {
      final ds = KLineDataset(candles: [], indicators: []);
      expect(ds.version, 0);
    });
  });

  group('IndicatorConfig', () {
    test('default values are correct', () {
      const config = IndicatorConfig();
      expect(config.maPeriods, [5, 10, 30]);
      expect(config.emaPeriods, [5, 10, 20]);
      expect(config.bollPeriod, 20);
      expect(config.bollStdDev, 2);
      expect(config.macdFast, 12);
      expect(config.macdSlow, 26);
      expect(config.macdSignal, 9);
      expect(config.kdjPeriod, 9);
      expect(config.kdjM1, 3);
      expect(config.kdjM2, 3);
      expect(config.rsiPeriods, [6, 12, 24]);
      expect(config.wrPeriods, [4, 20]);
    });

    test('assert: maPeriods with wrong length throws', () {
      expect(
        () => IndicatorConfig(maPeriods: [5, 10]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert: emaPeriods with wrong length throws', () {
      expect(
        () => IndicatorConfig(emaPeriods: [5, 10]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert: rsiPeriods with wrong length throws', () {
      expect(
        () => IndicatorConfig(rsiPeriods: [6]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('assert: wrPeriods with wrong length throws', () {
      expect(
        () => IndicatorConfig(wrPeriods: [4, 20, 60]),
        throwsA(isA<AssertionError>()),
      );
    });

    test('custom config is accepted', () {
      const config = IndicatorConfig(
        maPeriods: [3, 7, 21],
        emaPeriods: [3, 7, 14],
        rsiPeriods: [7, 14, 28],
        wrPeriods: [14, 28],
      );
      expect(config.maPeriods, [3, 7, 21]);
      expect(config.wrPeriods, [14, 28]);
    });
  });
}
