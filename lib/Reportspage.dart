import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'main.dart' show BF;
import 'AppState.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');
  late TabController _tab;
  String _period = 'This Month';
  final _periods = ['This Week', 'This Month', 'Last Month', 'All Time'];

  AppState get _s => AppStateScope.of(context);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _s.transactions.where((tx) {
      final d = tx['date'] as DateTime;
      switch (_period) {
        case 'This Week':
          return d.isAfter(now.subtract(Duration(days: now.weekday)));
        case 'This Month':
          return d.month == now.month && d.year == now.year;
        case 'Last Month':
          final lm = DateTime(now.year, now.month - 1);
          return d.month == lm.month && d.year == lm.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? BF.darkBg : BF.lightBg,
      appBar: _appBar(isDark),
      body: Column(
        children: [
          _periodRow(isDark),
          const SizedBox(height: 12),
          _tabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _overviewTab(isDark),
                _categoriesTab(isDark),
                _trendsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(bool isDark) => AppBar(
    backgroundColor: isDark ? BF.darkBg : BF.lightBg,
    elevation: 0,
    centerTitle: true,
    title: Text(
      "Reports & Analytics",
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back_ios_rounded,
        color: isDark ? Colors.white : Colors.black87,
      ),
      onPressed: () => Navigator.pop(context),
    ),
  );

  Widget _periodRow(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: _periods.map((p) {
          final sel = p == _period;
          return GestureDetector(
            onTap: () => setState(() => _period = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel
                    ? BF.accent
                    : (isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? BF.accent
                      : (isDark ? BF.darkBorder : BF.lightBorder),
                  width: 1,
                ),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? BF.darkSurface : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tab,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
        indicator: BoxDecoration(
          color: BF.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Overview"),
          Tab(text: "Categories"),
          Tab(text: "Trends"),
        ],
      ),
    );
  }

  Widget _overviewTab(bool isDark) {
    final txs = _filtered;
    final income = txs
        .where((t) => t['isIncome'])
        .fold(0.0, (s, t) => s + (t['amount'] as double));
    final expense = txs
        .where((t) => !t['isIncome'])
        .fold(0.0, (s, t) => s + (t['amount'] as double));
    final net = income - expense;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _statCard("Income", income, BF.green, isDark)),
            const SizedBox(width: 10),
            Expanded(child: _statCard("Expense", expense, BF.red, isDark)),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                "Net",
                net,
                net >= 0 ? BF.green : BF.red,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (income > 0 || expense > 0)
          _infoCard(
            isDark,
            child: PieChart(
              dataMap: {
                if (income > 0) "Income": income,
                if (expense > 0) "Expense": expense,
              },
              chartType: ChartType.ring,
              ringStrokeWidth: 24,
              chartRadius: 130,
              chartValuesOptions: const ChartValuesOptions(
                showChartValuesInPercentage: true,
                chartValueStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              legendOptions: LegendOptions(
                legendTextStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              colorList: const [BF.green, BF.red],
            ),
          )
        else
          _emptyData(isDark),
        const SizedBox(height: 14),
        _infoCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Summary",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _summaryRow("Total Transactions", "${txs.length}", isDark),
              _divider(isDark),
              _summaryRow(
                "Total Income",
                currency.format(income),
                isDark,
                vc: BF.green,
              ),
              _divider(isDark),
              _summaryRow(
                "Total Expenses",
                currency.format(expense),
                isDark,
                vc: BF.red,
              ),
              _divider(isDark),
              _summaryRow(
                "Net Savings",
                currency.format(net),
                isDark,
                vc: net >= 0 ? BF.green : BF.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoriesTab(bool isDark) {
    final txs = _filtered.where((t) => !t['isIncome']).toList();
    final Map<String, double> catMap = {};
    for (var tx in txs) {
      final c = tx['category'] as String;
      catMap[c] = (catMap[c] ?? 0) + (tx['amount'] as double);
    }
    final total = catMap.values.fold(0.0, (a, b) => a + b);
    final sorted = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final colors = [
      BF.accent,
      BF.red,
      BF.green,
      BF.amber,
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFF14B8A6),
    ];

    if (sorted.isEmpty) return _emptyData(isDark);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (total > 0)
          _infoCard(
            isDark,
            child: PieChart(
              dataMap: {for (var e in sorted) e.key: e.value},
              chartType: ChartType.ring,
              ringStrokeWidth: 20,
              chartRadius: 120,
              colorList: colors,
              chartValuesOptions: const ChartValuesOptions(
                showChartValuesInPercentage: true,
                chartValueStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
              legendOptions: LegendOptions(
                legendTextStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        ...sorted.asMap().entries.map((e) {
          final color = colors[e.key % colors.length];
          final pct = total > 0 ? e.value.value / total : 0.0;
          return _catBar(e.value.key, e.value.value, pct, color, isDark);
        }),
      ],
    );
  }

  Widget _trendsTab(bool isDark) {
    final txs = _filtered;
    final Map<String, double> incByDay = {}, expByDay = {};
    for (var tx in txs) {
      final key = DateFormat('MM/dd').format(tx['date'] as DateTime);
      if (tx['isIncome']) {
        incByDay[key] = (incByDay[key] ?? 0) + (tx['amount'] as double);
      } else {
        expByDay[key] = (expByDay[key] ?? 0) + (tx['amount'] as double);
      }
    }
    if (incByDay.isEmpty && expByDay.isEmpty) return _emptyData(isDark);
    final keys = {...incByDay.keys, ...expByDay.keys}.toList()..sort();
    final maxVal = keys
        .expand((k) => [incByDay[k] ?? 0, expByDay[k] ?? 0])
        .fold(0.0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _infoCard(
          isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Cash Flow",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: keys.map((key) {
                    final inc = incByDay[key] ?? 0;
                    final exp = expByDay[key] ?? 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (inc > 0)
                              Container(
                                height: maxVal > 0
                                    ? (inc / maxVal * 120).clamp(4.0, 120.0)
                                    : 0,
                                decoration: BoxDecoration(
                                  color: BF.green,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            const SizedBox(height: 2),
                            if (exp > 0)
                              Container(
                                height: maxVal > 0
                                    ? (exp / maxVal * 120).clamp(4.0, 120.0)
                                    : 0,
                                decoration: BoxDecoration(
                                  color: BF.red,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              key,
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'Poppins',
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _legend(BF.green, "Income", isDark),
                  const SizedBox(width: 20),
                  _legend(BF.red, "Expense", isDark),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _statCard(String label, double val, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BF.card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              label == "Income"
                  ? Icons.arrow_downward_rounded
                  : label == "Expense"
                  ? Icons.arrow_upward_rounded
                  : Icons.balance_rounded,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            currency.format(val),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(bool isDark, {required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BF.card(isDark),
    child: child,
  );

  Widget _summaryRow(String label, String value, bool isDark, {Color? vc}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: vc ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      );

  Widget _divider(bool isDark) => Divider(
    height: 1,
    thickness: 1,
    color: isDark ? BF.darkBorder : BF.lightBorder,
  );

  Widget _catBar(
    String cat,
    double amount,
    double pct,
    Color color,
    bool isDark,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BF.card(isDark),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cat,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              currency.format(amount),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${(pct * 100).toStringAsFixed(1)}% of expenses",
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    ),
  );

  Widget _legend(Color color, String label, bool isDark) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    ],
  );

  Widget _emptyData(bool isDark) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.bar_chart_rounded,
              size: 36,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No data for this period",
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
