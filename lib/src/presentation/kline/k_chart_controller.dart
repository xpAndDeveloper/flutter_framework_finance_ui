import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'renderer/chart_enums.dart';

/// K 线图控制器，管理主图指标、副图列表、滚动位置和缩放比例。
///
/// 使用方：
/// ```dart
/// final controller = KChartController();
/// // 切换主图
/// controller.setMainIndicator(MainIndicator.boll);
/// // 添加副图（最多 4 个）
/// controller.addSubIndicator(SubIndicator.macd);
/// // 滚动到最新
/// controller.scrollToLatest();
/// ```
class KChartController extends ChangeNotifier {
  KChartController({
    MainIndicator mainIndicator = MainIndicator.ma,
    List<SubIndicator> subIndicators = const [SubIndicator.vol],
    double scrollX = 0.0,
    double scaleX = 1.0,
    TickerProvider? vsync,
  })  : _mainIndicator = mainIndicator,
        _subIndicators = List.of(subIndicators),
        _scrollX = scrollX,
        _scaleX = scaleX,
        _vsync = vsync;

  MainIndicator _mainIndicator;
  final List<SubIndicator> _subIndicators;
  double _scrollX;
  double _scaleX;
  final TickerProvider? _vsync;

  AnimationController? _scrollAnim;

  static const double minScaleX = 0.15;
  static const double maxScaleX = 3.5;
  static const int maxSubIndicators = 4;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  MainIndicator get mainIndicator => _mainIndicator;
  List<SubIndicator> get subIndicators => List.unmodifiable(_subIndicators);
  double get scrollX => _scrollX;
  double get scaleX => _scaleX;

  // ---------------------------------------------------------------------------
  // Main indicator
  // ---------------------------------------------------------------------------

  void setMainIndicator(MainIndicator indicator) {
    if (_mainIndicator == indicator) return;
    _mainIndicator = indicator;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Sub indicators
  // ---------------------------------------------------------------------------

  void addSubIndicator(SubIndicator indicator) {
    assert(
      _subIndicators.length < maxSubIndicators,
      '副图最多 $maxSubIndicators 个，当前已有 ${_subIndicators.length} 个',
    );
    if (_subIndicators.contains(indicator)) return;
    _subIndicators.add(indicator);
    notifyListeners();
  }

  void removeSubIndicator(SubIndicator indicator) {
    if (_subIndicators.remove(indicator)) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Scroll / scale
  // ---------------------------------------------------------------------------

  void updateScrollX(double dx) {
    _scrollX += dx;
    if (_scrollX > 0) _scrollX = 0;
    notifyListeners();
  }

  void updateScaleX(double factor) {
    _scaleX = (_scaleX * factor).clamp(minScaleX, maxScaleX);
    notifyListeners();
  }

  void setScrollX(double value) {
    if (_scrollX == value) return;
    _scrollX = value;
    notifyListeners();
  }

  /// 动画滚动到最新 K 线（scrollX = 0）。
  ///
  /// 需要传入 [vsync] 才能播放动画，否则直接跳转。
  void scrollToLatest() {
    _scrollAnim?.dispose();
    _scrollAnim = null;

    if (_vsync == null || _scrollX == 0) {
      _scrollX = 0;
      notifyListeners();
      return;
    }

    final anim = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 300),
    );
    final tween = Tween<double>(begin: _scrollX, end: 0);
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);

    curved.addListener(() {
      _scrollX = tween.evaluate(curved);
      notifyListeners();
    });
    anim.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        anim.dispose();
        _scrollAnim = null;
      }
    });

    _scrollAnim = anim;
    anim.forward();
  }

  @override
  void dispose() {
    _scrollAnim?.dispose();
    super.dispose();
  }
}
