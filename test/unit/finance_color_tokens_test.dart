import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_framework_finance_ui/src/presentation/theme/finance_color_tokens.dart';

void main() {
  group('FinanceColorTokens.light', () {
    test('all fields are non-null', () {
      const t = FinanceColorTokens.light;
      expect(t.income, isNotNull);
      expect(t.incomeSoft, isNotNull);
      expect(t.expense, isNotNull);
      expect(t.expenseSoft, isNotNull);
      expect(t.pending, isNotNull);
      expect(t.pendingSoft, isNotNull);
      expect(t.refund, isNotNull);
      expect(t.refundSoft, isNotNull);
      expect(t.frozen, isNotNull);
      expect(t.frozenSoft, isNotNull);
    });
  });

  group('FinanceColorTokens.dark', () {
    test('all fields are non-null', () {
      const t = FinanceColorTokens.dark;
      expect(t.income, isNotNull);
      expect(t.incomeSoft, isNotNull);
      expect(t.expense, isNotNull);
      expect(t.expenseSoft, isNotNull);
      expect(t.pending, isNotNull);
      expect(t.pendingSoft, isNotNull);
      expect(t.refund, isNotNull);
      expect(t.refundSoft, isNotNull);
      expect(t.frozen, isNotNull);
      expect(t.frozenSoft, isNotNull);
    });

    test('dark and light have same income color', () {
      expect(FinanceColorTokens.dark.income, equals(FinanceColorTokens.light.income));
    });

    test('dark and light have different soft background colors', () {
      expect(
        FinanceColorTokens.dark.incomeSoft,
        isNot(equals(FinanceColorTokens.light.incomeSoft)),
      );
    });
  });

  group('copyWith', () {
    test('overrides specified field', () {
      const original = FinanceColorTokens.light;
      final copy = original.copyWith(income: const Color(0xFF112233));
      expect(copy.income, const Color(0xFF112233));
      expect(copy.expense, original.expense);
    });

    test('without args returns equal token', () {
      const original = FinanceColorTokens.light;
      final copy = original.copyWith();
      expect(copy.income, original.income);
      expect(copy.frozen, original.frozen);
    });
  });

  group('lerp', () {
    test('t=0 returns self', () {
      const a = FinanceColorTokens.light;
      const b = FinanceColorTokens.dark;
      final result = a.lerp(b, 0.0);
      expect(result.income, equals(a.income));
      expect(result.frozen, equals(a.frozen));
    });

    test('t=1 returns other', () {
      const a = FinanceColorTokens.light;
      const b = FinanceColorTokens.dark;
      final result = a.lerp(b, 1.0);
      expect(result.incomeSoft, equals(b.incomeSoft));
      expect(result.frozenSoft, equals(b.frozenSoft));
    });

    test('t=0.5 interpolates colors', () {
      const a = FinanceColorTokens.light;
      const b = FinanceColorTokens.dark;
      final result = a.lerp(b, 0.5);
      final expected = Color.lerp(a.incomeSoft, b.incomeSoft, 0.5)!;
      expect(result.incomeSoft, equals(expected));
    });

    test('lerp with null returns self', () {
      const a = FinanceColorTokens.light;
      final result = a.lerp(null, 0.5);
      expect(result.income, a.income);
    });
  });
}
