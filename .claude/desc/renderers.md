# flutter_framework_finance_ui — 渲染器与绘图引擎

## K 线渲染架构

```
KChartWidget
  └── RawGestureDetector
        ├── KChartHorizontalRecognizer（单指横滑 + 惯性）
        ├── KChartScaleRecognizer（双指缩放）
        └── LongPressGestureRecognizer（十字线）
  └── CustomPaint → ChartPainter（extends BaseChartPainter）
        ├── MainRenderer（蜡烛图/折线图 + MA/EMA/BOLL）
        ├── VolRenderer（VOL 柱状图 + MA5/MA10）
        └── SecondaryRenderer × N（MACD/KDJ/RSI/WR）
```

## 坐标系变换

```dart
// 数据索引 → 屏幕 X
double getX(int index) => index * mPointWidth + mPointWidth / 2;

// 数据值 → 屏幕 Y（BaseChartRenderer）
double getY(double value) => (maxValue - value) * scaleY + chartRect.top;

// 屏幕 X → translateX（用于平移/缩放）
double xToTranslateX(double x) => -mTranslateX + x / scaleX;

// translateX → 屏幕 X
double translateXtoX(double tx) => (tx + mTranslateX) * scaleX;
```

## 区域布局（mainFactor）

| 副图数量 | mainFactor | 主图高度占比 |
|---------|-----------|------------|
| 0 | 1.00 | 100% |
| 1 | 0.80 | 80% |
| 2 | 0.68 | 68% |
| 3 | 0.60 | 60% |
| 4 | 0.54 | 54% |

## repaintKey（shouldRepaint 对比）

```dart
// Dart record，字段完全相同才跳过重绘
(dataset.version, scrollX, scaleX, mainIndicator,
 subIndicators.join(','), isLongPress, selectX)
```

## 关键渲染约定

- `canvas.save/clipRect/restore` 限制每个区域的绘制范围
- `VOL Y 轴从 0 基准`：VolRenderer 构造时传入 `minValue: 0`
- MACD 柱：`getY(bar > 0 ? bar : 0)` to `getY(bar > 0 ? 0 : bar)`
- 最高最低价标注：三角指针 + 文字，自动避开边界
- 十字线：通过 `_binarySearchIndex` 二分查找最近 K 线
