import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_framework_ui/flutter_framework_ui.dart';
import 'package:flutter_framework_finance_ui/src/presentation/theme/finance_color_tokens.dart';
import 'package:flutter_framework_finance_ui/src/presentation/theme/k_chart_style.dart';

void main() {
  group('KChartStyle.fromTokens', () {
    final style = KChartStyle.fromTokens(
      AppColorTokens.light,
      FinanceColorTokens.light,
    );

    test('upColor maps to finance.income', () {
      expect(style.upColor, equals(FinanceColorTokens.light.income));
    });

    test('downColor maps to finance.expense', () {
      expect(style.downColor, equals(FinanceColorTokens.light.expense));
    });

    test('bgColor maps to colors.bg.page', () {
      expect(style.bgColor, equals(AppColorTokens.light.bg.page));
    });

    test('gridColor maps to colors.border.divider', () {
      expect(style.gridColor, equals(AppColorTokens.light.border.divider));
    });

    test('axisTextColor maps to colors.text.muted', () {
      expect(style.axisTextColor, equals(AppColorTokens.light.text.muted));
    });

    test('realTimeColor maps to finance.income', () {
      expect(style.realTimeColor, equals(FinanceColorTokens.light.income));
    });

    test('volUpColor maps to finance.income', () {
      expect(style.volUpColor, equals(FinanceColorTokens.light.income));
    });

    test('volDownColor maps to finance.expense', () {
      expect(style.volDownColor, equals(FinanceColorTokens.light.expense));
    });

    test('default sizes are set', () {
      expect(style.candleWidth, 8.5);
      expect(style.gridRows, 4);
      expect(style.rightWidth, 60.0);
    });

    test('dark theme has different bgColor than light', () {
      final dark = KChartStyle.fromTokens(
        AppColorTokens.dark,
        FinanceColorTokens.dark,
      );
      expect(dark.bgColor, isNot(equals(style.bgColor)));
    });
  });
}
