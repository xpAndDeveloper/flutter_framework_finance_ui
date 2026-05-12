import 'dart:ui' show Canvas, Rect;

import 'package:flutter/painting.dart';

import '../../../domain/models/k_line_data.dart';
import '../../../domain/models/k_line_indicators.dart';
import '../../theme/k_chart_style.dart';
import 'base_chart_renderer.dart';

/// VOL 柱状图 + MA5/MA10 均量线。
///
/// Y 轴从 0 基准映射（maxVol → chartRect.top，0 → chartRect.bottom）。
class VolRenderer extends BaseChartRenderer {
  VolRenderer({
    required super.chartRect,
    required super.maxValue,
    required super.scaleX,
    required super.textStyle,
    required this.style,
    required this.volWidth,
  }) : super(minValue: 0, topPadding: 0);

  final KChartStyle style;
  final double volWidth;

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

  void drawVolBar(KLineData candle, double x, Canvas canvas) {
    final isUp = candle.close >= candle.open;
    final color = isUp ? style.volUpColor : style.volDownColor;
    final halfW = volWidth / 2 / scaleX;
    final top = getY(candle.volume);
    final bottom = chartRect.bottom;

    canvas.drawRect(
      Rect.fromLTRB(x - halfW, top, x + halfW, bottom),
      chartPaint
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void drawVolMA(
    KLineIndicators? lastInd,
    KLineIndicators curInd,
    double lastX,
    double curX,
    Canvas canvas,
  ) {
    if (lastInd == null) return;
    _line(lastInd.maVolume5, curInd.maVolume5, lastX, curX, canvas, style.volMa1Color);
    _line(lastInd.maVolume10, curInd.maVolume10, lastX, curX, canvas, style.volMa2Color);
  }

  void _line(double? last, double? cur, double lastX, double curX, Canvas canvas, Color color) {
    if (last == null || cur == null || last == 0 || cur == 0) return;
    drawLine(last, cur, canvas, lastX, curX, color);
  }
}
