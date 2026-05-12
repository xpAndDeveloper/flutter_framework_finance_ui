import 'package:flutter/gestures.dart';

/// 双指缩放识别器。
///
/// 单指时强制拒绝，仅双指触发时接管手势，
/// 防止与 [KChartHorizontalRecognizer] 发生冲突。
class KChartScaleRecognizer extends ScaleGestureRecognizer {
  KChartScaleRecognizer({super.debugOwner});

  final List<int> _pointers = [];

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerDownEvent) {
      _pointers.add(event.pointer);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);
      if (_pointers.isEmpty) _pointers.clear();
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (_pointers.length < 2) {
      super.rejectGesture(pointer);
    } else {
      super.acceptGesture(pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (_pointers.length > 1) {
      super.acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
      _pointers.clear();
    }
  }
}
