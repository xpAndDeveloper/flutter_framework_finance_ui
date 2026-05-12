# flutter_framework_finance_ui — 目录结构与依赖

## 目录结构

```
lib/
├── src/
│   ├── domain/
│   │   └── models/
│   │       ├── k_line_data.dart         # OHLCV + timestamp，immutable
│   │       ├── k_line_indicators.dart   # 固定字段指标（非 Map）
│   │       ├── k_line_dataset.dart      # candles + indicators + version
│   │       └── indicator_config.dart   # 指标周期参数
│   ├── data/
│   │   └── indicator_calculator.dart   # 指标计算引擎 + Isolate 包装
│   └── presentation/
│       ├── theme/
│       │   ├── finance_color_tokens.dart  # ThemeExtension
│       │   └── k_chart_style.dart         # 图表样式数据类
│       └── kline/
│           ├── gesture/
│           │   ├── k_chart_horizontal_recognizer.dart
│           │   └── k_chart_scale_recognizer.dart
│           ├── renderer/
│           │   ├── chart_enums.dart         # MainIndicator, SubIndicator
│           │   ├── base_chart_renderer.dart
│           │   ├── base_chart_painter.dart
│           │   ├── main_renderer.dart
│           │   ├── vol_renderer.dart
│           │   ├── secondary_renderer.dart
│           │   └── chart_painter.dart
│           ├── k_chart_controller.dart
│           └── k_chart_widget.dart
├── flutter_framework_finance_ui.dart  # barrel 导出
test/
└── unit/
    ├── models_test.dart
    ├── indicator_calculator_test.dart
    ├── finance_color_tokens_test.dart
    ├── k_chart_style_test.dart
    └── renderer_test.dart
```

## 依赖关系

```yaml
dependencies:
  flutter_framework_ui:
    path: ../flutter_framework_ui

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

## 设计决策

| 决策 | 原因 |
|------|------|
| KLineIndicators 用固定字段而非 Map | 渲染循环中避免装箱开销，dart analyze 可静态检查 |
| compute() Isolate 全量计算 | 200+ 根 K 线全量计算耗时约 5-10ms，避免 UI 线程卡顿 |
| updateLast() 主线程执行 | 增量更新仅重算最后一根，耗时 < 0.1ms |
| Dart record 作为 repaintKey | 值语义对比，避免不必要的 CustomPainter 重绘 |
| KChartStyle.fromTokens() | 与框架主题系统解耦，支持亮/暗主题自动切换 |
