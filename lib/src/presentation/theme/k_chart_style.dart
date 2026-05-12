import 'package:flutter/material.dart';
import 'package:flutter_framework_ui/flutter_framework_ui.dart';
import 'finance_color_tokens.dart';

/// K 线图全量样式配置。
///
/// 所有颜色与尺寸集中于此，Renderer 通过此类取色，
/// 不直接访问 ThemeExtension，保持渲染层无 BuildContext 依赖。
@immutable
class KChartStyle {
  const KChartStyle({
    // --- K 线主色 ---
    required this.upColor,
    required this.downColor,
    required this.upBorderColor,
    required this.downBorderColor,
    // --- 背景 / 网格 ---
    required this.bgColor,
    required this.gridColor,
    required this.axisTextColor,
    // --- 指标线颜色 ---
    required this.ma1Color,
    required this.ma2Color,
    required this.ma3Color,
    required this.ema1Color,
    required this.ema2Color,
    required this.ema3Color,
    required this.bollUpColor,
    required this.bollMidColor,
    required this.bollDnColor,
    // --- VOL ---
    required this.volUpColor,
    required this.volDownColor,
    required this.volMa1Color,
    required this.volMa2Color,
    // --- MACD ---
    required this.macdDifColor,
    required this.macdDeaColor,
    required this.macdUpColor,
    required this.macdDownColor,
    // --- KDJ ---
    required this.kdjKColor,
    required this.kdjDColor,
    required this.kdjJColor,
    // --- RSI ---
    required this.rsi1Color,
    required this.rsi2Color,
    required this.rsi3Color,
    // --- WR ---
    required this.wr1Color,
    required this.wr2Color,
    // --- 实时价格线 ---
    required this.realTimeColor,
    // --- 十字线 ---
    required this.crossLineColor,
    required this.crossTextColor,
    required this.crossBgColor,
    // --- 标注 ---
    required this.maxMinTextColor,
    // --- 尺寸 ---
    this.candleWidth = 8.5,
    this.candleLineWidth = 1.5,
    this.volWidth = 8.5,
    this.macdWidth = 3.0,
    this.pointWidth = 11.0,
    this.gridRows = 4,
    this.gridColumns = 4,
    this.topPadding = 30.0,
    this.bottomDateHeight = 20.0,
    this.rightWidth = 60.0,
    this.axisTextSize = 10.0,
    this.defaultTextSize = 12.0,
  });

  // K 线
  final Color upColor;
  final Color downColor;
  final Color upBorderColor;
  final Color downBorderColor;

  // 背景
  final Color bgColor;
  final Color gridColor;
  final Color axisTextColor;

  // MA
  final Color ma1Color;
  final Color ma2Color;
  final Color ma3Color;

  // EMA
  final Color ema1Color;
  final Color ema2Color;
  final Color ema3Color;

  // BOLL
  final Color bollUpColor;
  final Color bollMidColor;
  final Color bollDnColor;

  // VOL
  final Color volUpColor;
  final Color volDownColor;
  final Color volMa1Color;
  final Color volMa2Color;

  // MACD
  final Color macdDifColor;
  final Color macdDeaColor;
  final Color macdUpColor;
  final Color macdDownColor;

  // KDJ
  final Color kdjKColor;
  final Color kdjDColor;
  final Color kdjJColor;

  // RSI
  final Color rsi1Color;
  final Color rsi2Color;
  final Color rsi3Color;

  // WR
  final Color wr1Color;
  final Color wr2Color;

  // 实时价格
  final Color realTimeColor;

  // 十字线
  final Color crossLineColor;
  final Color crossTextColor;
  final Color crossBgColor;

  // 最高最低标注
  final Color maxMinTextColor;

  // 尺寸
  final double candleWidth;
  final double candleLineWidth;
  final double volWidth;
  final double macdWidth;
  final double pointWidth;
  final int gridRows;
  final int gridColumns;
  final double topPadding;
  final double bottomDateHeight;
  final double rightWidth;
  final double axisTextSize;
  final double defaultTextSize;

  // ---------------------------------------------------------------------------
  // Factory
  // ---------------------------------------------------------------------------

  /// 从框架主题 token 自动映射 K 线样式。
  factory KChartStyle.fromTokens(
    AppColorTokens colors,
    FinanceColorTokens finance,
  ) {
    return KChartStyle(
      upColor: finance.income,
      downColor: finance.expense,
      upBorderColor: finance.income,
      downBorderColor: finance.expense,
      bgColor: colors.bg.page,
      gridColor: colors.border.divider,
      axisTextColor: colors.text.muted,
      // MA 线沿用通用配色
      ma1Color: const Color(0xFFF5A623),
      ma2Color: const Color(0xFF4A90E2),
      ma3Color: const Color(0xFF7B68EE),
      ema1Color: const Color(0xFFF5A623),
      ema2Color: const Color(0xFF4A90E2),
      ema3Color: const Color(0xFF7B68EE),
      bollUpColor: const Color(0xFF4A90E2),
      bollMidColor: const Color(0xFFF5A623),
      bollDnColor: const Color(0xFF4A90E2),
      volUpColor: finance.income,
      volDownColor: finance.expense,
      volMa1Color: const Color(0xFFF5A623),
      volMa2Color: const Color(0xFF4A90E2),
      macdDifColor: const Color(0xFF4A90E2),
      macdDeaColor: const Color(0xFFF5A623),
      macdUpColor: finance.income,
      macdDownColor: finance.expense,
      kdjKColor: const Color(0xFFF5A623),
      kdjDColor: const Color(0xFF4A90E2),
      kdjJColor: const Color(0xFF7B68EE),
      rsi1Color: const Color(0xFFF5A623),
      rsi2Color: const Color(0xFF4A90E2),
      rsi3Color: const Color(0xFF7B68EE),
      wr1Color: const Color(0xFFF5A623),
      wr2Color: const Color(0xFF4A90E2),
      realTimeColor: finance.income,
      crossLineColor: colors.text.muted,
      crossTextColor: colors.text.inverse,
      crossBgColor: colors.bg.elevated,
      maxMinTextColor: colors.text.secondary,
    );
  }
}
