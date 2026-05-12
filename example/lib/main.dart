import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_framework_finance_ui/flutter_framework_finance_ui.dart';
import 'package:flutter_framework_ui/flutter_framework_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance UI Example',
      theme: AppTheme.light().copyWith(
        extensions: [
          ...AppTheme.light().extensions.values,
          FinanceColorTokens.light,
        ],
      ),
      darkTheme: AppTheme.dark().copyWith(
        extensions: [
          ...AppTheme.dark().extensions.values,
          FinanceColorTokens.dark,
        ],
      ),
      home: const KLineExamplePage(),
    );
  }
}

class KLineExamplePage extends StatefulWidget {
  const KLineExamplePage({super.key});

  @override
  State<KLineExamplePage> createState() => _KLineExamplePageState();
}

class _KLineExamplePageState extends State<KLineExamplePage> {
  late KChartController _controller;
  late KLineDataset _dataset;
  bool _isLine = false;
  Timer? _tickTimer;

  static const _config = IndicatorConfig();
  static final _calc = IndicatorCalculator(_config);
  static final _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _controller = KChartController(
      mainIndicator: MainIndicator.ma,
      subIndicators: [SubIndicator.vol, SubIndicator.macd],
    );
    _dataset = _generateDataset(200);
    _tickTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _simulateTick(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  KLineDataset _generateDataset(int count) {
    final candles = <KLineData>[];
    double price = 100.0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var i = 0; i < count; i++) {
      final change = (_random.nextDouble() - 0.48) * 2;
      price = (price + change).clamp(10.0, 500.0);
      candles.add(KLineData(
        timestamp: now - (count - i) * 60,
        open: price - change / 2,
        high: price + _random.nextDouble() * 1.5,
        low: price - _random.nextDouble() * 1.5,
        close: price,
        volume: 1000 + _random.nextDouble() * 5000,
      ));
    }
    return _calc.calculate(candles);
  }

  void _simulateTick() {
    if (_dataset.isEmpty) return;
    final last = _dataset.candles.last;
    final change = (_random.nextDouble() - 0.48) * 0.5;
    _calc.updateLast(_dataset, last.copyWith(close: last.close + change));
    setState(() => _dataset = _dataset.incrementVersion());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorTokens>()!;
    final finance = Theme.of(context).extension<FinanceColorTokens>()!;
    final style = KChartStyle.fromTokens(colors, finance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('K 线图示例'),
        actions: [
          IconButton(
            icon: Icon(_isLine ? Icons.candlestick_chart : Icons.show_chart),
            onPressed: () => setState(() => _isLine = !_isLine),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: KChartWidget(
              dataset: _dataset,
              controller: _controller,
              style: style,
              isLine: _isLine,
              onLoadMore: () {
                final more = _generateDataset(50);
                setState(() {
                  _dataset = _calc.calculate([
                    ...more.candles,
                    ..._dataset.candles,
                  ]);
                });
              },
            ),
          ),
          _ControlBar(controller: _controller),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.controller});
  final KChartController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('主图：', style: TextStyle(fontSize: 12)),
                ...MainIndicator.values.map((ind) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(ind.name.toUpperCase()),
                        selected: controller.mainIndicator == ind,
                        onSelected: (_) => controller.setMainIndicator(ind),
                      ),
                    )),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Text('副图：', style: TextStyle(fontSize: 12)),
                ...SubIndicator.values.map((sub) {
                  final active = controller.subIndicators.contains(sub);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(sub.name.toUpperCase()),
                      selected: active,
                      onSelected: (v) => v
                          ? controller.addSubIndicator(sub)
                          : controller.removeSubIndicator(sub),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.scrollToLatest,
                  child: const Text('回到最新'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
