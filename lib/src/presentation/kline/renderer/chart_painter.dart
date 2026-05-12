import 'dart:math' as math;
import 'dart:ui' show Canvas, Offset, Size, Rect;

import 'package:flutter/painting.dart';

import '../../../domain/models/k_line_data.dart';
import '../../../domain/models/k_line_indicators.dart';
import '../../theme/k_chart_style.dart';
import 'base_chart_painter.dart';
import 'chart_enums.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

/// 完整 K 线图 CustomPainter。
///
/// 持有 [MainRenderer]、[VolRenderer]（若 VOL 在副图中）和若干 [SecondaryRenderer]，
/// 统一编排 paint 流程。
class ChartPainter extends BaseChartPainter {
  ChartPainter({
    required super.dataset,
    required super.scaleX,
    required super.scrollX,
    required super.isLongPress,
    required super.selectX,
    required super.selectY,
    required super.style,
    required super.mainIndicator,
    required super.subIndicators,
    super.isLine,
    required super.repaintKey,
  });

  MainRenderer? _mainRenderer;
  VolRenderer? _volRenderer;
  final Map<SubIndicator, SecondaryRenderer> _secondaryRenderers = {};

  static KLineData? currentSelectData;

  final TextStyle _defaultTextStyle = const TextStyle(
    fontSize: 10,
    color: Color(0xFF999999),
  );

  TextStyle get _axisStyle => TextStyle(
        fontSize: style.axisTextSize,
        color: style.axisTextColor,
      );

  // ---------------------------------------------------------------------------
  // Init renderers
  // ---------------------------------------------------------------------------

  @override
  void initChartRenderers() {
    if (dataset.isEmpty) return;

    // Build sub max/min values
    final volMax = _calcMax(SubIndicator.vol);
    final subMaxMin = <SubIndicator, (double, double)>{};
    for (final sub in subIndicators) {
      if (sub != SubIndicator.vol) {
        subMaxMin[sub] = _calcSubMaxMin(sub);
      }
    }

    _mainRenderer = MainRenderer(
      chartRect: mMainRect,
      maxValue: mMainMaxValue,
      minValue: mMainMinValue,
      topPadding: style.topPadding,
      scaleX: scaleX,
      textStyle: _defaultTextStyle,
      style: style,
      mainIndicator: mainIndicator,
      isLine: isLine,
      pointWidth: mPointWidth,
      candleWidth: style.candleWidth,
    )
      ..maxIndex = mMainMaxIndex
      ..minIndex = mMainMinIndex
      ..maxHighValue = mMainHighMaxValue
      ..minLowValue = mMainLowMinValue;

    if (subIndicators.contains(SubIndicator.vol)) {
      final volRect = getSubRect(SubIndicator.vol);
      if (volRect != null) {
        _volRenderer = VolRenderer(
          chartRect: volRect,
          maxValue: volMax,
          scaleX: scaleX,
          textStyle: _defaultTextStyle,
          style: style,
          volWidth: style.volWidth,
        );
      }
    }

    _secondaryRenderers.clear();
    for (final sub in subIndicators) {
      if (sub == SubIndicator.vol) continue;
      final rect = getSubRect(sub);
      if (rect == null) continue;
      final (maxV, minV) = subMaxMin[sub] ?? (1.0, 0.0);
      _secondaryRenderers[sub] = SecondaryRenderer(
        chartRect: rect,
        maxValue: maxV,
        minValue: minV,
        scaleX: scaleX,
        textStyle: _defaultTextStyle,
        style: style,
        subIndicator: sub,
      );
    }
  }

  double _calcMax(SubIndicator sub) {
    double max = -double.maxFinite;
    for (var i = mStartIndex; i <= mStopIndex; i++) {
      final ind = dataset.indicators[i];
      final candle = dataset.candles[i];
      switch (sub) {
        case SubIndicator.vol:
          max = math.max(max, candle.volume);
          if (ind.maVolume5 != null) max = math.max(max, ind.maVolume5!);
          if (ind.maVolume10 != null) max = math.max(max, ind.maVolume10!);
        default:
          break;
      }
    }
    return max <= 0 ? 1.0 : max;
  }

  (double, double) _calcSubMaxMin(SubIndicator sub) {
    double max = -double.maxFinite;
    double min = double.maxFinite;
    for (var i = mStartIndex; i <= mStopIndex; i++) {
      final ind = dataset.indicators[i];
      void check(double? v) {
        if (v == null) return;
        max = math.max(max, v);
        min = math.min(min, v);
      }

      switch (sub) {
        case SubIndicator.macd:
          check(ind.macdDif);
          check(ind.macdDea);
          check(ind.macdBar);
        case SubIndicator.kdj:
          check(ind.kdjK);
          check(ind.kdjD);
          check(ind.kdjJ);
        case SubIndicator.rsi:
          check(ind.rsi6);
          check(ind.rsi12);
          check(ind.rsi24);
        case SubIndicator.wr:
          check(ind.wr4);
          check(ind.wr20);
        case SubIndicator.vol:
          break;
      }
    }
    if (max == -double.maxFinite) max = 1.0;
    if (min == double.maxFinite) min = 0.0;
    return (max, min);
  }

  // ---------------------------------------------------------------------------
  // Draw
  // ---------------------------------------------------------------------------

  @override
  void drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = style.bgColor,
    );
  }

  @override
  void drawGrid(Canvas canvas) {
    _mainRenderer?.drawGrid(canvas, style.gridRows, style.gridColumns);
    for (final r in _secondaryRenderers.values) {
      r.drawGrid(canvas, 2, style.gridColumns);
    }
    _volRenderer?.drawGrid(canvas, 2, style.gridColumns);
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, mWidth - style.rightWidth, size.height));

    KLineData? lastCandle;
    KLineIndicators? lastInd;
    double? lastX;

    for (var i = mStartIndex; i <= mStopIndex; i++) {
      final candle = dataset.candles[i];
      final ind = dataset.indicators[i];
      final x = translateXtoX(getX(i));

      if (isLine) {
        if (lastCandle != null && lastX != null) {
          _mainRenderer?.drawCandleLine(lastCandle, candle, lastX, x, canvas);
        }
      } else {
        _mainRenderer?.drawCandle(candle, x, canvas);
      }
      _mainRenderer?.drawIndicators(lastInd, ind, lastX ?? x, x, canvas);

      if (_volRenderer != null) {
        _volRenderer!.drawVolBar(candle, x, canvas);
        _volRenderer!.drawVolMA(lastInd, ind, lastX ?? x, x, canvas);
      }

      for (final entry in _secondaryRenderers.entries) {
        entry.value.drawIndicator(lastInd, ind, lastX ?? x, x, canvas);
      }

      lastCandle = candle;
      lastInd = ind;
      lastX = x;
    }

    canvas.restore();
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    final maxX = translateXtoX(getX(mMainMaxIndex));
    final minX = translateXtoX(getX(mMainMinIndex));
    _mainRenderer?.drawMaxAndMin(canvas, maxX, minX);
  }

  @override
  void drawRightText(Canvas canvas) {
    if (_mainRenderer == null) return;
    final step = (_mainRenderer!.maxValue - _mainRenderer!.minValue) / style.gridRows;
    for (var i = 0; i <= style.gridRows; i++) {
      final value = _mainRenderer!.minValue + step * i;
      final y = _mainRenderer!.getY(value);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(2), style: _axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mWidth - style.rightWidth + 4, y - tp.height / 2));
    }
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (dataset.isEmpty) return;
    final step = math.max(1, (mStopIndex - mStartIndex) ~/ style.gridColumns);
    for (var i = mStartIndex; i <= mStopIndex; i += step) {
      final x = translateXtoX(getX(i));
      if (x < 0 || x > mWidth - style.rightWidth) continue;
      final ts = dataset.candles[i].timestamp;
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      final label = '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: _axisStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - style.bottomDateHeight));
    }
  }

  @override
  void drawText(Canvas canvas, KLineData candle, KLineIndicators ind, double x) {
    // Indicator labels at top left — minimal implementation
    final parts = <String>[];
    switch (mainIndicator) {
      case MainIndicator.ma:
        if (ind.ma5 != null) parts.add('MA5: ${ind.ma5!.toStringAsFixed(2)}');
        if (ind.ma10 != null) parts.add('MA10: ${ind.ma10!.toStringAsFixed(2)}');
        if (ind.ma30 != null) parts.add('MA30: ${ind.ma30!.toStringAsFixed(2)}');
      case MainIndicator.ema:
        if (ind.ema5 != null) parts.add('EMA5: ${ind.ema5!.toStringAsFixed(2)}');
        if (ind.ema10 != null) parts.add('EMA10: ${ind.ema10!.toStringAsFixed(2)}');
        if (ind.ema20 != null) parts.add('EMA20: ${ind.ema20!.toStringAsFixed(2)}');
      case MainIndicator.boll:
        if (ind.bollUp != null) parts.add('BOLL: ${ind.bollMid!.toStringAsFixed(2)}');
      case MainIndicator.none:
        break;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: parts.join('  '),
        style: TextStyle(fontSize: style.defaultTextSize, color: style.axisTextColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: mWidth - style.rightWidth);
    tp.paint(canvas, Offset(x, 4));
  }

  @override
  void drawRealTimePrice(Canvas canvas, Size size) {
    if (dataset.isEmpty) return;
    final lastClose = dataset.candles.last.close;
    if (_mainRenderer == null) return;
    final y = _mainRenderer!.getY(lastClose);
    if (y < mMainRect.top || y > mMainRect.bottom) return;

    final paint = Paint()
      ..color = style.realTimeColor
      ..strokeWidth = 0.5;
    _drawDashedLine(canvas, Offset(0, y), Offset(mWidth - style.rightWidth, y), paint);

    // Price label
    final text = lastClose.toStringAsFixed(2);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: style.axisTextSize,
          color: style.crossTextColor,
          backgroundColor: style.realTimeColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(mWidth - style.rightWidth + 4, y - tp.height / 2));
  }

  @override
  void drawCrossLine(Canvas canvas, Size size) {
    if (dataset.isEmpty) return;
    final idx = calculateSelectedX(selectX);
    final x = translateXtoX(getX(idx));
    final candle = dataset.candles[idx];
    currentSelectData = candle;

    final crossPaint = Paint()
      ..color = style.crossLineColor
      ..strokeWidth = 0.5;

    // Vertical line
    _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height - style.bottomDateHeight), crossPaint);

    if (_mainRenderer != null) {
      final y = _mainRenderer!.getY(candle.close);
      // Horizontal line
      _drawDashedLine(canvas, Offset(0, y), Offset(mWidth, y), crossPaint);

      // Price label on Y axis
      final priceText = candle.close.toStringAsFixed(2);
      final tp = TextPainter(
        text: TextSpan(
          text: priceText,
          style: TextStyle(
            fontSize: style.axisTextSize,
            color: style.crossTextColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bgRect = Rect.fromLTWH(
        mWidth - style.rightWidth,
        y - tp.height / 2 - 2,
        style.rightWidth,
        tp.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = style.crossBgColor);
      tp.paint(canvas, Offset(mWidth - style.rightWidth + 4, y - tp.height / 2));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = dx / len;
    final ny = dy / len;
    double traveled = 0;
    bool drawing = true;
    while (traveled < len) {
      final next = math.min(traveled + (drawing ? dashWidth : dashSpace), len);
      if (drawing) {
        canvas.drawLine(
          Offset(p1.dx + nx * traveled, p1.dy + ny * traveled),
          Offset(p1.dx + nx * next, p1.dy + ny * next),
          paint,
        );
      }
      traveled = next;
      drawing = !drawing;
    }
  }
}
