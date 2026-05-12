import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_framework_finance_ui/src/data/indicator_calculator.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/indicator_config.dart';
import 'package:flutter_framework_finance_ui/src/domain/models/k_line_data.dart';

KLineData candle(double close, {double? high, double? low, double? volume}) =>
    KLineData(
      timestamp: 0,
      open: close,
      high: high ?? close,
      low: low ?? close,
      close: close,
      volume: volume ?? 100.0,
    );

List<KLineData> closes(List<double> values) =>
    values.map((c) => candle(c)).toList();

const _calc = IndicatorCalculator(IndicatorConfig());

void main() {
  group('empty / insufficient data', () {
    test('empty candles returns empty dataset', () {
      final ds = _calc.calculate([]);
      expect(ds.length, 0);
    });

    test('4 candles: MA5 all null (need 5)', () {
      final ds = _calc.calculate(closes([1, 2, 3, 4]));
      expect(ds.indicators.every((e) => e.ma5 == null), isTrue);
    });

    test('1 candle: EMA is set (EMA starts from first bar)', () {
      final ds = _calc.calculate(closes([10.0]));
      expect(ds.indicators.first.ema5, 10.0);
    });
  });

  group('MA', () {
    test('MA5 value at index 4 equals mean of first 5 closes', () {
      final ds = _calc.calculate(closes([2, 4, 6, 8, 10]));
      expect(ds.indicators[4].ma5, closeTo(6.0, 1e-9));
    });

    test('MA5 at index 5 shifts window', () {
      final ds = _calc.calculate(closes([2, 4, 6, 8, 10, 12]));
      // (4+6+8+10+12)/5 = 8
      expect(ds.indicators[5].ma5, closeTo(8.0, 1e-9));
    });

    test('MA30 null when fewer than 30 candles', () {
      final ds = _calc.calculate(closes(List.generate(29, (i) => i.toDouble())));
      expect(ds.indicators.every((e) => e.ma30 == null), isTrue);
    });
  });

  group('EMA', () {
    test('EMA5 first bar equals close', () {
      final ds = _calc.calculate(closes([100.0, 90.0, 110.0]));
      expect(ds.indicators[0].ema5, closeTo(100.0, 1e-9));
    });

    test('EMA5 second bar applies multiplier', () {
      // k = 2/(5+1) = 1/3
      final ds = _calc.calculate(closes([100.0, 90.0]));
      final expected = 90.0 * (1.0 / 3) + 100.0 * (2.0 / 3);
      expect(ds.indicators[1].ema5, closeTo(expected, 1e-9));
    });

    test('EMA converges toward price sequence', () {
      final ds = _calc.calculate(closes(List.generate(20, (_) => 100.0)));
      // All closes are 100, EMA should be 100
      expect(ds.indicators[19].ema5, closeTo(100.0, 1e-9));
    });
  });

  group('BOLL', () {
    test('BOLL null for first 19 candles (period=20)', () {
      final ds = _calc.calculate(closes(List.generate(19, (i) => i.toDouble())));
      expect(ds.indicators.every((e) => e.bollMid == null), isTrue);
    });

    test('BOLL mid equals MA20 at period start', () {
      final values = List.generate(20, (i) => (i + 1).toDouble());
      final ds = _calc.calculate(closes(values));
      final expectedMid = values.reduce((a, b) => a + b) / 20;
      expect(ds.indicators[19].bollMid, closeTo(expectedMid, 1e-9));
    });

    test('bollUp > bollMid > bollDn when variance > 0', () {
      final values = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
          .map((e) => e.toDouble())
          .toList();
      final ds = _calc.calculate(closes(values));
      final ind = ds.indicators[19];
      expect(ind.bollUp!, greaterThan(ind.bollMid!));
      expect(ind.bollMid!, greaterThan(ind.bollDn!));
    });

    test('bollUp == bollMid == bollDn when all closes equal', () {
      final ds = _calc.calculate(closes(List.generate(20, (_) => 50.0)));
      final ind = ds.indicators[19];
      expect(ind.bollUp, closeTo(50.0, 1e-9));
      expect(ind.bollDn, closeTo(50.0, 1e-9));
    });
  });

  group('VOL MA', () {
    test('maVolume5 equals mean of first 5 volumes', () {
      final candles = List.generate(
        5,
        (i) => KLineData(
          timestamp: i,
          open: 1,
          high: 1,
          low: 1,
          close: 1,
          volume: (i + 1) * 100.0,
        ),
      );
      final ds = _calc.calculate(candles);
      expect(ds.indicators[4].maVolume5, closeTo(300.0, 1e-9)); // (100+200+300+400+500)/5
    });
  });

  group('MACD', () {
    test('macdDif and macdDea are set from first bar', () {
      final ds = _calc.calculate(closes([100.0, 101.0, 102.0]));
      expect(ds.indicators[0].macdDif, isNotNull);
      expect(ds.indicators[0].macdDea, isNotNull);
    });

    test('macdBar = (dif - dea) * 2', () {
      final ds = _calc.calculate(closes(List.generate(30, (i) => (100 + i).toDouble())));
      final ind = ds.indicators[29];
      expect(ind.macdBar, closeTo((ind.macdDif! - ind.macdDea!) * 2, 1e-9));
    });

    test('constant price: macdDif approaches 0', () {
      final ds = _calc.calculate(closes(List.generate(100, (_) => 50.0)));
      expect(ds.indicators[99].macdDif!.abs(), lessThan(1e-6));
    });
  });

  group('KDJ', () {
    test('kdjK/D/J are 0 for first 8 candles (period=9)', () {
      final ds = _calc.calculate(
        List.generate(8, (i) => candle(100.0, high: 105.0, low: 95.0)),
      );
      expect(ds.indicators.every((e) => e.kdjK == 0 && e.kdjD == 0 && e.kdjJ == 0), isTrue);
    });

    test('kdjK/D/J are non-null from index 8 (period=9)', () {
      final ds = _calc.calculate(
        List.generate(9, (i) => candle(100.0 + i, high: 110.0 + i, low: 90.0 + i)),
      );
      expect(ds.indicators[8].kdjK, isNotNull);
      expect(ds.indicators[8].kdjD, isNotNull);
      expect(ds.indicators[8].kdjJ, isNotNull);
    });

    test('kdjJ = 3*K - 2*D', () {
      final ds = _calc.calculate(
        List.generate(20, (i) => candle(100.0 + i, high: 110.0 + i, low: 90.0 + i)),
      );
      final ind = ds.indicators[19];
      expect(ind.kdjJ, closeTo(3 * ind.kdjK! - 2 * ind.kdjD!, 1e-9));
    });
  });

  group('RSI', () {
    test('rsi6 null for first 5 candles (need period closes)', () {
      final ds = _calc.calculate(closes([1, 2, 3, 4, 5]));
      expect(ds.indicators[5 - 1].rsi6, isNull);
    });

    test('rsi6 is 100 when all closes rise', () {
      final ds = _calc.calculate(closes(List.generate(20, (i) => (i + 1).toDouble())));
      expect(ds.indicators[19].rsi6, closeTo(100.0, 1e-6));
    });

    test('rsi6 is 0 when all closes fall', () {
      final ds = _calc.calculate(closes(List.generate(20, (i) => (20 - i).toDouble())));
      expect(ds.indicators[19].rsi6, closeTo(0.0, 1e-6));
    });

    test('rsi6 is between 0 and 100 for mixed data', () {
      final ds = _calc.calculate(closes([10, 12, 11, 13, 12, 14, 13, 15, 14, 16]));
      final ind = ds.indicators[9];
      if (ind.rsi6 != null) {
        expect(ind.rsi6! >= 0 && ind.rsi6! <= 100, isTrue);
      }
    });
  });

  group('WR', () {
    test('wr4 null for first 3 candles (period=4)', () {
      final ds = _calc.calculate(
        List.generate(3, (i) => candle(100.0, high: 110.0, low: 90.0)),
      );
      expect(ds.indicators.every((e) => e.wr4 == null), isTrue);
    });

    test('wr4 between -100 and 0', () {
      final ds = _calc.calculate(
        List.generate(10, (i) => candle(100.0 + i, high: 105.0 + i, low: 95.0 + i)),
      );
      for (var i = 3; i < 10; i++) {
        final wr = ds.indicators[i].wr4;
        expect(wr, isNotNull);
        expect(wr! >= -100 && wr <= 0, isTrue, reason: 'wr4[$i]=$wr out of range');
      }
    });

    test('wr4 = -100 when close == lowest', () {
      final candles = [
        candle(90.0, high: 110.0, low: 90.0),
        candle(90.0, high: 110.0, low: 90.0),
        candle(90.0, high: 110.0, low: 90.0),
        candle(90.0, high: 110.0, low: 90.0),
      ];
      final ds = _calc.calculate(candles);
      expect(ds.indicators[3].wr4, closeTo(-100.0, 1e-9));
    });

    test('wr4 = 0 when close == highest', () {
      final candles = [
        candle(110.0, high: 110.0, low: 90.0),
        candle(110.0, high: 110.0, low: 90.0),
        candle(110.0, high: 110.0, low: 90.0),
        candle(110.0, high: 110.0, low: 90.0),
      ];
      final ds = _calc.calculate(candles);
      expect(ds.indicators[3].wr4, closeTo(0.0, 1e-9));
    });
  });

  group('updateLast', () {
    test('updates MA of last candle', () {
      final candles = List.generate(5, (i) => candle((i + 1).toDouble()));
      final ds = _calc.calculate(candles);
      // Replace last candle with close=10 instead of 5
      final updated = candles[4].copyWith(close: 10.0);
      _calc.updateLast(ds, updated);
      // New MA5 = (1+2+3+4+10)/5 = 4.0
      expect(ds.indicators[4].ma5, closeTo(4.0, 1e-9));
    });

    test('updateLast on empty dataset does nothing', () {
      final ds = _calc.calculate([]);
      expect(() => _calc.updateLast(ds, candle(1.0)), returnsNormally);
    });
  });
}
