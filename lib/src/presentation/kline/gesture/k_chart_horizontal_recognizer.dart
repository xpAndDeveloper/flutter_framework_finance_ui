import 'package:flutter/gestures.dart';

/// 横向拖拽识别器，附带惯性滚动与加载更多触发。
///
/// 单指横向拖拽时接管手势；双指时拒绝（交给 [KChartScaleRecognizer]）。
class KChartHorizontalRecognizer extends HorizontalDragGestureRecognizer {
  KChartHorizontalRecognizer({super.debugOwner});

  int _pointerCount = 0;

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerDownEvent) {
      _pointerCount++;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_pointerCount > 0) _pointerCount--;
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_pointerCount >= 2) {
      rejectGesture(pointer);
      return;
    }
    super.acceptGesture(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    _pointerCount = 0;
  }
}
