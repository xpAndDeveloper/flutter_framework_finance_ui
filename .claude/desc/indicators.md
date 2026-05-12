# flutter_framework_finance_ui — 指标引擎与主题 Token

## 指标计算引擎

### 使用方式

```dart
// 全量计算（Isolate，异步）
final dataset = await computeDataset(candles, const IndicatorConfig());

// 同步全量计算（主线程，测试用）
final dataset = IndicatorCalculator(config).calculate(candles);

// 增量更新最后一根（主线程，实时 tick）
_calc.updateLast(dataset, updatedLastCandle);
setState(() => _dataset = _dataset.incrementVersion());
```

### 指标字段映射

| 指标 | 字段 |
|------|------|
| MA | `ma5` / `ma10` / `ma30` |
| EMA | `ema5` / `ema10` / `ema20` |
| BOLL | `bollUp` / `bollMid` / `bollDn` |
| VOL MA | `maVolume5` / `maVolume10` |
| MACD | `macdDif` / `macdDea` / `macdBar`（bar = dif - dea × 2） |
| KDJ | `kdjK` / `kdjD` / `kdjJ`（前 period-1 根置 0） |
| RSI | `rsi6` / `rsi12` / `rsi24`（Wilder EMA 平滑法） |
| WR | `wr4` / `wr20` |

---

## FinanceColorTokens

金融语义颜色 ThemeExtension，需注入 ThemeData：

```dart
// app.dart 注册
theme: AppTheme.light().copyWith(
  extensions: [
    ...AppTheme.light().extensions.values,
    FinanceColorTokens.light,
  ],
),

// Widget 中读取
final finance = Theme.of(context).extension<FinanceColorTokens>()!;
finance.income      // 收入绿
finance.incomeSoft  // 收入浅色背景
finance.expense     // 支出红
finance.expenseSoft
finance.pending     // 待处理橙
finance.pendingSoft
finance.refund      // 退款蓝
finance.refundSoft
finance.frozen      // 冻结灰
finance.frozenSoft
```

---

## KChartStyle

从框架 Token 自动映射：

```dart
final style = KChartStyle.fromTokens(
  Theme.of(context).extension<AppColorTokens>()!,
  Theme.of(context).extension<FinanceColorTokens>()!,
);
```

| style 字段 | 来源 Token |
|-----------|-----------|
| `upColor` | `finance.income` |
| `downColor` | `finance.expense` |
| `bgColor` | `colors.bg.page` |
| `gridColor` | `colors.border.divider` |
| `axisTextColor` | `colors.text.muted` |
| `crossLineColor` | `colors.text.secondary` |
