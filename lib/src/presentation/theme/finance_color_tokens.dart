import 'package:flutter/material.dart';
import 'package:flutter_framework_ui/flutter_framework_ui.dart';

/// 金融业务专用颜色语义 token。
///
/// 通过 [ThemeExtension] 注入到 [ThemeData]，消费方使用：
/// ```dart
/// final colors = Theme.of(context).extension<FinanceColorTokens>()!;
/// ```
@immutable
class FinanceColorTokens extends ThemeExtension<FinanceColorTokens> {
  const FinanceColorTokens({
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.pending,
    required this.pendingSoft,
    required this.refund,
    required this.refundSoft,
    required this.frozen,
    required this.frozenSoft,
  });

  /// 收入（涨）主色
  final Color income;

  /// 收入软背景
  final Color incomeSoft;

  /// 支出（跌）主色
  final Color expense;

  /// 支出软背景
  final Color expenseSoft;

  /// 待处理主色
  final Color pending;

  /// 待处理软背景
  final Color pendingSoft;

  /// 退款主色
  final Color refund;

  /// 退款软背景
  final Color refundSoft;

  /// 冻结主色
  final Color frozen;

  /// 冻结软背景
  final Color frozenSoft;

  // ---------------------------------------------------------------------------
  // Presets
  // ---------------------------------------------------------------------------

  static const FinanceColorTokens light = FinanceColorTokens(
    income: UPayColors.financeIncome,
    incomeSoft: UPayColors.statusSuccessSoftLight,
    expense: UPayColors.financeExpense,
    expenseSoft: UPayColors.statusErrorSoftLight,
    pending: UPayColors.financePending,
    pendingSoft: UPayColors.statusWarningSoftLight,
    refund: UPayColors.financeRefund,
    refundSoft: UPayColors.statusWarningSoftLight,
    frozen: UPayColors.financeFrozenLight,
    frozenSoft: UPayColors.statusNeutralSoftLight,
  );

  static const FinanceColorTokens dark = FinanceColorTokens(
    income: UPayColors.financeIncome,
    incomeSoft: UPayColors.statusSuccessSoftDark,
    expense: UPayColors.financeExpense,
    expenseSoft: UPayColors.statusErrorSoftDark,
    pending: UPayColors.financePending,
    pendingSoft: UPayColors.statusWarningSoftDark,
    refund: UPayColors.financeRefund,
    refundSoft: UPayColors.statusWarningSoftDark,
    frozen: UPayColors.financeFrozenDark,
    frozenSoft: UPayColors.statusNeutralSoftDark,
  );

  // ---------------------------------------------------------------------------
  // ThemeExtension
  // ---------------------------------------------------------------------------

  @override
  FinanceColorTokens copyWith({
    Color? income,
    Color? incomeSoft,
    Color? expense,
    Color? expenseSoft,
    Color? pending,
    Color? pendingSoft,
    Color? refund,
    Color? refundSoft,
    Color? frozen,
    Color? frozenSoft,
  }) =>
      FinanceColorTokens(
        income: income ?? this.income,
        incomeSoft: incomeSoft ?? this.incomeSoft,
        expense: expense ?? this.expense,
        expenseSoft: expenseSoft ?? this.expenseSoft,
        pending: pending ?? this.pending,
        pendingSoft: pendingSoft ?? this.pendingSoft,
        refund: refund ?? this.refund,
        refundSoft: refundSoft ?? this.refundSoft,
        frozen: frozen ?? this.frozen,
        frozenSoft: frozenSoft ?? this.frozenSoft,
      );

  @override
  FinanceColorTokens lerp(FinanceColorTokens? other, double t) {
    if (other == null) return this;
    return FinanceColorTokens(
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      pendingSoft: Color.lerp(pendingSoft, other.pendingSoft, t)!,
      refund: Color.lerp(refund, other.refund, t)!,
      refundSoft: Color.lerp(refundSoft, other.refundSoft, t)!,
      frozen: Color.lerp(frozen, other.frozen, t)!,
      frozenSoft: Color.lerp(frozenSoft, other.frozenSoft, t)!,
    );
  }
}
