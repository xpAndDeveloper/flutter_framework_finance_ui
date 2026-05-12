import 'dart:ui' show Canvas, Rect, Size, Path;

import 'package:flutter/painting.dart';

import '../../../domain/models/k_line_data.dart';
import '../../../domain/models/k_line_indicators.dart';
import '../../theme/k_chart_style.dart';
import 'base_chart_renderer.dart';
import 'chart_enums.dart';

/// 主图渲染器：蜡烛图/折线图 + MA/EMA/BOLL 指标线 + 最高最低标注。
class MainRenderer extends BaseChartRenderer {
  MainRenderer({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required super.topPadding,
    required super.scaleX,
    required super.textStyle,
    required this.style,
    required this.mainIndicator,
    required this.isLine,
    required this.pointWidth,
    required this.candleWidth,
  });

  final KChartStyle style;
  final MainIndicator mainIndicator;
  final bool isLine;
  final double pointWidth;
  final double candleWidth;

  // 最高最低价记录（由 ChartPainter 赋值后调用 drawMaxAndMin）
  int maxIndex = 0;
  int minIndex = 0;
  double maxHighValue = 0;
  double minLowValue = double.maxFinite;

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    final rowStep = chartRect.height / gridRows;
    final colStep = chartRect.width / gridColumns;
    final paint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i <= gridRows; i++) {
      final y = chartRect.top + rowStep * i;
      canvas.drawLine(Offset(0, y), Offset(chartRect.width, y), paint);
    }
    for (var i = 0; i <= gridColumns; i++) {
      final x = colStep * i;
      canvas.drawLine(Offset(x, chartRect.top), Offset(x, chartRect.bottom), paint);
    }
  }

  void drawCandle(
    KLineData candle,
    double x,
    Canvas canvas,
  ) {
    final isUp = candle.close >= candle.open;
    final color = isUp ? style.upColor : style.downColor;
    final halfW = candleWidth / 2 / scaleX;

    final top = getY(math_max(candle.open, candle.close));
    final bottom = getY(math_min(candle.open, candle.close));
    final highY = getY(candle.high);
    final lowY = getY(candle.low);

    final paint = chartPaint
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 上下影线
    canvas.drawLine(Offset(x, highY), Offset(x, top), paint);
    canvas.drawLine(Offset(x, bottom), Offset(x, lowY), paint);

    // 实体
    final bodyRect = Rect.fromLTRB(x - halfW, top, x + halfW, bottom);
    if ((bottom - top) < 1) {
      canvas.drawLine(Offset(x - halfW, top), Offset(x + halfW, top), paint);
    } else {
      canvas.drawRect(bodyRect, paint..style = PaintingStyle.fill);
    }
  }

  void drawCandleLine(KLineData lastCandle, KLineData curCandle, double lastX, double curX, Canvas canvas) {
    drawLine(lastCandle.close, curCandle.close, canvas, lastX, curX, style.upColor);
  }

  void drawIndicators(
    KLineIndicators? lastInd,
    KLineIndicators curInd,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (lastInd == null) return;
    switch (mainIndicator) {
      case MainIndicator.ma:
        _drawLine(lastInd.ma5, curInd.ma5, lastX, curX, canvas, style.ma1Color);
        _drawLine(lastInd.ma10, curInd.ma10, lastX, curX, canvas, style.ma2Color);
        _drawLine(lastInd.ma30, curInd.ma30, lastX, curX, canvas, style.ma3Color);
      case MainIndicator.ema:
        _drawLine(lastInd.ema5, curInd.ema5, lastX, curX, canvas, style.ema1Color);
        _drawLine(lastInd.ema10, curInd.ema10, lastX, curX, canvas, style.ema2Color);
        _drawLine(lastInd.ema20, curInd.ema20, lastX, curX, canvas, style.ema3Color);
      case MainIndicator.boll:
        _drawLine(lastInd.bollUp, curInd.bollUp, lastX, curX, canvas, style.bollUpColor);
        _drawLine(lastInd.bollMid, curInd.bollMid, lastX, curX, canvas, style.bollMidColor);
        _drawLine(lastInd.bollDn, curInd.bollDn, lastX, curX, canvas, style.bollDnColor);
      case MainIndicator.none:
        break;
    }
  }

  void _drawLine(
    double? last,
    double? cur,
    double lastX,
    double curX,
    Canvas canvas,
    Color color,
  ) {
    if (last == null || cur == null || last == 0 || cur == 0) return;
    super.drawLine(last, cur, canvas, lastX, curX, color);
  }

  void drawMaxAndMin(Canvas canvas, double maxX, double minX) {
    _drawAnnotation(canvas, maxX, maxHighValue, isMax: true);
    _drawAnnotation(canvas, minX, minLowValue, isMax: false);
  }

  void _drawAnnotation(Canvas canvas, double x, double value, {required bool isMax}) {
    final y = getY(value);
    final text = value.toStringAsFixed(2);
    final span = TextSpan(
      text: isMax ? '── $text' : '── $text',
      style: TextStyle(color: style.maxMinTextColor, fontSize: style.axisTextSize),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    final dx = x > chartRect.width / 2 ? x - tp.width - 4 : x + 4;
    tp.paint(canvas, Offset(dx, y - tp.height / 2));

    // 小三角指向 K 线
    final paint = Paint()..color = style.maxMinTextColor;
    final path = Path();
    if (x > chartRect.width / 2) {
      path
        ..moveTo(x, y)
        ..lineTo(x - 6, y - 3)
        ..lineTo(x - 6, y + 3);
    } else {
      path
        ..moveTo(x, y)
        ..lineTo(x + 6, y - 3)
        ..lineTo(x + 6, y + 3);
    }
    canvas.drawPath(path, paint);
  }
}

double math_max(double a, double b) => a > b ? a : b;
double math_min(double a, double b) => a < b ? a : b;
