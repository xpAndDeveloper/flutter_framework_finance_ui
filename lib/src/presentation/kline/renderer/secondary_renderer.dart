import 'dart:ui' show Canvas, Rect;

import 'package:flutter/painting.dart';

import '../../../domain/models/k_line_indicators.dart';
import '../../theme/k_chart_style.dart';
import 'base_chart_renderer.dart';
import 'chart_enums.dart';

/// 副图渲染器：根据 [subIndicator] 绘制 MACD/KDJ/RSI/WR。
class SecondaryRenderer extends BaseChartRenderer {
  SecondaryRenderer({
    required super.chartRect,
    required super.maxValue,
    required super.minValue,
    required super.scaleX,
    required super.textStyle,
    required this.style,
    required this.subIndicator,
  }) : super(topPadding: 0);

  final KChartStyle style;
  final SubIndicator subIndicator;

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    final paint = Paint()
      ..color = style.gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, chartRect.top),
      Offset(chartRect.width, chartRect.top),
      paint,
    );
  }

  void drawIndicator(
    KLineIndicators? lastInd,
    KLineIndicators curInd,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    switch (subIndicator) {
      case SubIndicator.macd:
        _drawMACD(lastInd, curInd, lastX, curX, canvas);
      case SubIndicator.kdj:
        _drawKDJ(lastInd, curInd, lastX, curX, canvas);
      case SubIndicator.rsi:
        _drawRSI(lastInd, curInd, lastX, curX, canvas);
      case SubIndicator.wr:
        _drawWR(lastInd, curInd, lastX, curX, canvas);
      case SubIndicator.vol:
        break; // VOL handled by VolRenderer
    }
  }

  void _drawMACD(
    KLineIndicators? last,
    KLineIndicators cur,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (last != null) {
      _line(last.macdDif, cur.macdDif, lastX, curX, canvas, style.macdDifColor);
      _line(last.macdDea, cur.macdDea, lastX, curX, canvas, style.macdDeaColor);
    }
    final bar = cur.macdBar;
    if (bar != null) {
      final color = bar > 0 ? style.macdUpColor : style.macdDownColor;
      final halfW = 3.0 / scaleX;
      final top = getY(bar > 0 ? bar : 0);
      final bottom = getY(bar > 0 ? 0 : bar);
      canvas.drawRect(
        Rect.fromLTRB(curX - halfW, top, curX + halfW, bottom),
        chartPaint
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawKDJ(
    KLineIndicators? last,
    KLineIndicators cur,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (last == null) return;
    _line(last.kdjK, cur.kdjK, lastX, curX, canvas, style.kdjKColor);
    _line(last.kdjD, cur.kdjD, lastX, curX, canvas, style.kdjDColor);
    _line(last.kdjJ, cur.kdjJ, lastX, curX, canvas, style.kdjJColor);
  }

  void _drawRSI(
    KLineIndicators? last,
    KLineIndicators cur,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (last == null) return;
    _line(last.rsi6, cur.rsi6, lastX, curX, canvas, style.rsi1Color);
    _line(last.rsi12, cur.rsi12, lastX, curX, canvas, style.rsi2Color);
    _line(last.rsi24, cur.rsi24, lastX, curX, canvas, style.rsi3Color);
  }

  void _drawWR(
    KLineIndicators? last,
    KLineIndicators cur,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (last == null) return;
    _line(last.wr4, cur.wr4, lastX, curX, canvas, style.wr1Color);
    _line(last.wr20, cur.wr20, lastX, curX, canvas, style.wr2Color);
  }

  void _line(
    double? last,
    double? cur,
    double lastX,
    double curX,
    Canvas canvas,
    Color color,
  ) {
    if (last == null || cur == null) return;
    drawLine(last, cur, canvas, lastX, curX, color);
  }
}
