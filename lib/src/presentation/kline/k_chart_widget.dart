import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/indicator_config.dart';
import '../../domain/models/k_line_data.dart';
import '../../domain/models/k_line_dataset.dart';
import '../theme/k_chart_style.dart';
import 'gesture/k_chart_horizontal_recognizer.dart';
import 'gesture/k_chart_scale_recognizer.dart';
import 'k_chart_controller.dart';
import 'renderer/base_chart_painter.dart';
import 'renderer/chart_painter.dart';

/// K 线图 Widget。
///
/// 接收外部提供的 [KLineDataset]，通过 [KChartController] 控制状态，
/// [style] 决定外观（可通过 [KChartStyle.fromTokens] 从主题自动映射）。
///
/// 滚动/缩放由内部手势识别器处理；长按触发十字线。
/// [onLoadMore] 在用户滚到最左端时触发，业务层可在回调中加载历史数据。
/// [onCrossLine] 在十字线激活时回调当前选中的 [KLineData]。
class KChartWidget extends StatefulWidget {
  const KChartWidget({
    super.key,
    required this.dataset,
    required this.controller,
    required this.style,
    this.config = const IndicatorConfig(),
    this.isLine = false,
    this.onLoadMore,
    this.onCrossLine,
  });

  final KLineDataset dataset;
  final KChartController controller;
  final KChartStyle style;
  final IndicatorConfig config;
  final bool isLine;
  final VoidCallback? onLoadMore;
  final ValueChanged<KLineData?>? onCrossLine;

  @override
  State<KChartWidget> createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  bool _isLongPress = false;
  double _selectX = 0.0;
  double _selectY = 0.0;
  double _lastScaleX = 1.0;

  // 惯性动画
  late AnimationController _flingAnim;
  double _flingScrollX = 0.0;

  // 长按选中数据广播
  final _crossLineController = StreamController<KLineData?>.broadcast();

  Stream<KLineData?> get crossLineStream => _crossLineController.stream;

  bool _loadMoreTriggered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _flingAnim = AnimationController(vsync: this)
      ..addListener(_onFlingTick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          _flingAnim.stop();
        }
      });
  }

  @override
  void didUpdateWidget(KChartWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _flingAnim.dispose();
    _crossLineController.close();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  void _onFlingTick() {
    final dx = _flingScrollX * _flingAnim.value;
    widget.controller.updateScrollX(dx);

    // 到达最左端触发 onLoadMore
    if (widget.controller.scrollX <= BaseChartPainter.maxScrollX * -1 &&
        !_loadMoreTriggered) {
      _loadMoreTriggered = true;
      widget.onLoadMore?.call();
    }
  }

  void _startFling(double velocity) {
    _flingScrollX = velocity / 60;
    _flingAnim
      ..value = 1.0
      ..animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.decelerate,
      );
  }

  void _stopFling() {
    _flingAnim.stop();
    _loadMoreTriggered = false;
  }

  // ---------------------------------------------------------------------------
  // Long press
  // ---------------------------------------------------------------------------

  void _handleLongPress(Offset localPosition) {
    if (!_isLongPress) {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _isLongPress = true;
      _selectX = localPosition.dx;
      _selectY = localPosition.dy;
    });
    // Fire onCrossLine via ChartPainter.currentSelectData
    final data = ChartPainter.currentSelectData;
    widget.onCrossLine?.call(data);
    _crossLineController.add(data);
  }

  void _handleLongPressEnd() {
    setState(() {
      _isLongPress = false;
    });
    widget.onCrossLine?.call(null);
    _crossLineController.add(null);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final repaintKey = (
      widget.dataset.version,
      controller.scrollX,
      controller.scaleX,
      controller.mainIndicator,
      controller.subIndicators.join(','),
      _isLongPress,
      _selectX,
    );

    return RawGestureDetector(
      gestures: {
        KChartHorizontalRecognizer:
            GestureRecognizerFactoryWithHandlers<KChartHorizontalRecognizer>(
          () => KChartHorizontalRecognizer(),
          (r) {
            r.onStart = (_) => _stopFling();
            r.onUpdate = (d) {
              controller.updateScrollX(d.delta.dx / controller.scaleX);
              if (controller.scrollX <=
                      BaseChartPainter.maxScrollX * -1 &&
                  !_loadMoreTriggered) {
                _loadMoreTriggered = true;
                widget.onLoadMore?.call();
              }
            };
            r.onEnd = (d) {
              _loadMoreTriggered = false;
              final velocity = d.velocity.pixelsPerSecond.dx;
              if (velocity.abs() > 100) _startFling(velocity);
            };
          },
        ),
        KChartScaleRecognizer:
            GestureRecognizerFactoryWithHandlers<KChartScaleRecognizer>(
          () => KChartScaleRecognizer(),
          (r) {
            r.onStart = (_) {
              _stopFling();
              _lastScaleX = controller.scaleX;
            };
            r.onUpdate = (d) {
              controller.updateScaleX(d.scale / _lastScaleX);
              _lastScaleX = d.scale;
            };
          },
        ),
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (r) {
            r.onLongPressStart =
                (d) => _handleLongPress(d.localPosition);
            r.onLongPressMoveUpdate =
                (d) => _handleLongPress(d.localPosition);
            r.onLongPressEnd = (_) => _handleLongPressEnd();
          },
        ),
      },
      child: CustomPaint(
        painter: ChartPainter(
          dataset: widget.dataset,
          scaleX: controller.scaleX,
          scrollX: controller.scrollX,
          isLongPress: _isLongPress,
          selectX: _selectX,
          selectY: _selectY,
          style: widget.style,
          mainIndicator: controller.mainIndicator,
          subIndicators: controller.subIndicators,
          isLine: widget.isLine,
          repaintKey: repaintKey,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
