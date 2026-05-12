# flutter_framework_finance_ui — 模块知识库

## 启动时必须执行

**进入此目录时，立即读取：**
1. `AGENTS.md` — 当前身份（金融 UI 工程师）与工作边界

---

## 模块职责

金融 UI 扩展层，位于 `flutter_framework_ui`（通用 UI）与业务项目之间。

**依赖关系：**
```
flutter_framework_ui  ←  flutter_framework_finance_ui  ←  业务项目
```

## 技术要点

- K 线渲染基于 Flutter CustomPainter，使用 canvas.save/translate/scale/restore 管理坐标系
- 指标计算全量走 `compute()` Isolate，增量更新（updateLast）在主线程
- `KLineIndicators` 使用固定字段（非 Map），避免渲染循环中的装箱开销
- `ChartPainter.shouldRepaint` 通过 Dart record repaintKey 对比，避免无效重绘
- 颜色通过 `KChartStyle.fromTokens()` 从框架主题自动映射
