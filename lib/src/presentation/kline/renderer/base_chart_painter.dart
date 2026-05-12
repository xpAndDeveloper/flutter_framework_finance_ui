import 'dart:math' as math;
import 'dart:ui' show Canvas, Rect, Size;

import 'package:flutter/painting.dart';

import '../../../domain/models/k_line_data.dart';
import '../../../domain/models/k_line_dataset.dart';
import '../../../domain/models/k_line_indicators.dart';
import '../../theme/k_chart_style.dart';
import 'chart_enums.dart';

/// K 线图 CustomPainter 基类，负责坐标系变换与区域布局。
abstract class BaseChartPainter extends CustomPainter {
  BaseChartPainter({
    required this.dataset,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.selectY,
    required this.style,
    required this.mainIndicator,
    required this.subIndicators,
    this.isLine = false,
    required Object repaintKey,
  }) : super(repaint: null) {
    _repaintKey = repaintKey;
    mItemCount = dataset.length;
    mPointWidth = style.pointWidth;
    mDataLen = mItemCount * mPointWidth;
  }

  final KLineDataset dataset;
  final double scaleX;
  final double scrollX;
  final bool isLongPress;
  final double selectX;
  final double selectY;
  final KChartStyle style;
  final MainIndicator mainIndicator;
  final List<SubIndicator> subIndicators;
  final bool isLine;

  late final Object _repaintKey;

  int mItemCount = 0;
  double mPointWidth = 11.0;
  double mDataLen = 0.0;
  double mMarginRight = 0.0;

  late Rect mMainRect;
  Rect? mVolRect;
  final Map<SubIndicator, Rect> _subRects = {};

  late double mDisplayHeight;
  late double mWidth;
  double mTranslateX = -double.maxFinite;

  int mStartIndex = 0;
  int mStopIndex = 0;

  double mMainMaxValue = -double.maxFinite;
  double mMainMinValue = double.maxFinite;
  double mMainHighMaxValue = -double.maxFinite;
  double mMainLowMinValue = double.maxFinite;
  int mMainMaxIndex = 0;
  int mMainMinIndex = 0;

  static double maxScrollX = 0.0;

  // ---------------------------------------------------------------------------
  // CustomPainter
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));

    mDisplayHeight = size.height - style.topPadding - style.bottomDateHeight;
    mWidth = size.width;
    mMarginRight = (mWidth / style.gridColumns - mPointWidth) / scaleX;

    _initRect(size);
    _calculateValue();
    initChartRenderers();

    canvas.save();
    drawBackground(canvas, size);
    drawGrid(canvas);
    if (dataset.isNotEmpty) {
      drawChart(canvas, size);
      drawMaxAndMin(canvas);
      drawRightText(canvas);
      drawDate(canvas, size);
      drawText(canvas, dataset.candles.last, dataset.indicators.last, 5);
      drawRealTimePrice(canvas, size);
      if (isLongPress) drawCrossLine(canvas, size);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) =>
      _repaintKey != oldDelegate._repaintKey;

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  void _initRect(Size size) {
    double mainFactor;
    switch (subIndicators.length) {
      case 0:
        mainFactor = 1.00;
      case 1:
        mainFactor = 0.80;
      case 2:
        mainFactor = 0.68;
      case 3:
        mainFactor = 0.60;
      default:
        mainFactor = 0.54;
    }

    final mainHeight = mDisplayHeight * mainFactor;
    final subHeight = subIndicators.isEmpty
        ? 0.0
        : mDisplayHeight * (1 - mainFactor) / subIndicators.length;

    mMainRect = Rect.fromLTRB(
      0,
      style.topPadding,
      mWidth,
      style.topPadding + mainHeight,
    );

    _subRects.clear();
    double prevBottom = mMainRect.bottom + 4;
    for (final sub in subIndicators) {
      final rect = Rect.fromLTRB(0, prevBottom + 4, mWidth, prevBottom + subHeight);
      _subRects[sub] = rect;
      prevBottom = rect.bottom;
    }
  }

  Rect? getSubRect(SubIndicator sub) => _subRects[sub];

  // ---------------------------------------------------------------------------
  // Data traversal
  // ---------------------------------------------------------------------------

  void _calculateValue() {
    if (dataset.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    _setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));

    mMainMaxValue = -double.maxFinite;
    mMainMinValue = double.maxFinite;
    mMainHighMaxValue = -double.maxFinite;
    mMainLowMinValue = double.maxFinite;

    for (var i = math.max(0, mStartIndex - 1); i <= mStopIndex; i++) {
      _getMainMaxMin(dataset.candles[i], dataset.indicators[i], i);
    }
  }

  void _getMainMaxMin(KLineData candle, KLineIndicators ind, int i) {
    if (isLine) {
      mMainMaxValue = math.max(mMainMaxValue, candle.close);
      mMainMinValue = math.min(mMainMinValue, candle.close);
    } else {
      double maxPrice = candle.high;
      double minPrice = candle.low;

      switch (mainIndicator) {
        case MainIndicator.ma:
          for (final v in [ind.ma5, ind.ma10, ind.ma30]) {
            if (v != null && v > 0) {
              maxPrice = math.max(maxPrice, v);
              minPrice = math.min(minPrice, v);
            }
          }
        case MainIndicator.ema:
          for (final v in [ind.ema5, ind.ema10, ind.ema20]) {
            if (v != null && v > 0) {
              maxPrice = math.max(maxPrice, v);
              minPrice = math.min(minPrice, v);
            }
          }
        case MainIndicator.boll:
          for (final v in [ind.bollUp, ind.bollDn]) {
            if (v != null && v > 0) {
              maxPrice = math.max(maxPrice, v);
              minPrice = math.min(minPrice, v);
            }
          }
        case MainIndicator.none:
          break;
      }

      mMainMaxValue = math.max(mMainMaxValue, maxPrice);
      mMainMinValue = math.min(mMainMinValue, math.max(0, minPrice));

      if (mMainHighMaxValue < candle.high) {
        mMainHighMaxValue = candle.high;
        mMainMaxIndex = i;
      }
      if (mMainLowMinValue > candle.low) {
        mMainLowMinValue = candle.low;
        mMainMinIndex = i;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Coordinate helpers
  // ---------------------------------------------------------------------------

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _binarySearchIndex(translateX, 0, mItemCount - 1);

  int _binarySearchIndex(double tx, int start, int end) {
    if (mItemCount == 0) return 0;
    if (end <= start) return start;
    if (end - start == 1) {
      final s = getX(start);
      final e = getX(end);
      return (tx - s).abs() < (tx - e).abs() ? start : end;
    }
    final mid = start + (end - start) ~/ 2;
    final mv = getX(mid);
    if (tx < mv) return _binarySearchIndex(tx, start, mid);
    if (tx > mv) return _binarySearchIndex(tx, mid, end);
    return mid;
  }

  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  double translateXtoX(double translateX) => (translateX + mTranslateX) * scaleX;

  void _setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    x = x >= 0 ? 0.0 : x;
    if (x < 0) x -= mMarginRight;
    return x >= 0 ? 0.0 : x;
  }

  int calculateSelectedX(double selectX) {
    int idx = indexOfTranslateX(xToTranslateX(selectX));
    if (idx < mStartIndex) idx = mStartIndex;
    if (idx > mStopIndex) idx = mStopIndex;
    return idx;
  }

  // ---------------------------------------------------------------------------
  // Abstract hooks
  // ---------------------------------------------------------------------------

  void initChartRenderers();

  void drawBackground(Canvas canvas, Size size);
  void drawGrid(Canvas canvas);
  void drawChart(Canvas canvas, Size size);
  void drawRightText(Canvas canvas);
  void drawDate(Canvas canvas, Size size);
  void drawText(Canvas canvas, KLineData candle, KLineIndicators ind, double x);
  void drawMaxAndMin(Canvas canvas);
  void drawRealTimePrice(Canvas canvas, Size size);
  void drawCrossLine(Canvas canvas, Size size);
}
