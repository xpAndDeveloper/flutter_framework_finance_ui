import 'dart:ui' show Canvas, Rect;
import 'package:flutter/painting.dart' show TextStyle, Color, Paint, FilterQuality;

/// K 线渲染器基类。
///
/// 持有坐标变换参数，子类通过 [getY] 将数据值映射到画布 Y 坐标。
abstract class BaseChartRenderer {
  BaseChartRenderer({
    required this.chartRect,
    required this.maxValue,
    required this.minValue,
    required this.topPadding,
    required this.scaleX,
    required this.textStyle,
  }) {
    if (maxValue == minValue) {
      maxValue += 0.5;
      minValue -= 0.5;
    }
    scaleY = chartRect.height / (maxValue - minValue);
  }

  double maxValue;
  double minValue;
  late double scaleY;
  final double scaleX;
  final double topPadding;
  final Rect chartRect;
  final TextStyle textStyle;

  final Paint chartPaint = Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high
    ..strokeWidth = 1.0;

  /// 将数据值映射到画布 Y 坐标。
  double getY(double value) => (maxValue - value) * scaleY + chartRect.top;

  /// 画线段。
  void drawLine(
    double lastValue,
    double curValue,
    Canvas canvas,
    double lastX,
    double curX,
    Color color,
  ) {
    canvas.drawLine(
      Offset(lastX, getY(lastValue)),
      Offset(curX, getY(curValue)),
      chartPaint..color = color,
    );
  }

  void drawGrid(Canvas canvas, int gridRows, int gridColumns);
}
