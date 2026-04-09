import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'main.dart' show BF;
import 'AppState.dart';
import 'BudgetPage.dart';
import 'ReportsPage.dart';
import 'RecurringPage.dart';
import 'AccountsPage.dart';
import 'SavingsPage.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  final currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterType = 'All';
  DateTimeRange? _filterDateRange;

  AppState get _s => AppStateScope.of(context);

  double get _balance =>
      _s.accounts.fold(0.0, (s, a) => s + (a['balance'] as double));

  List<Map<String, dynamic>> get _filteredTxs {
    return _s.transactions.where((tx) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!(tx['title'] as String).toLowerCase().contains(q) &&
            !(tx['category'] as String).toLowerCase().contains(q))
          return false;
      }
      if (_filterCategory != 'All' && tx['category'] != _filterCategory)
        return false;
      if (_filterType == 'Income' && !(tx['isIncome'] as bool)) return false;
      if (_filterType == 'Expense' && (tx['isIncome'] as bool)) return false;
      if (_filterDateRange != null) {
        final d = tx['date'] as DateTime;
        if (d.isBefore(_filterDateRange!.start) ||
            d.isAfter(_filterDateRange!.end.add(const Duration(days: 1))))
          return false;
      }
      return true;
    }).toList();
  }

  List<String> get _categories => [
    'All',
    ..._s.transactions.map((t) => t['category'] as String).toSet(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? BF.darkBg : BF.lightBg,
      body: SafeArea(child: _page()),
      bottomNavigationBar: _navBar(isDark),
      floatingActionButton: _fab(),
    );
  }

  Widget _fab() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        colors: [BF.accent, BF.accentSoft],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: BF.accent.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: FloatingActionButton(
      backgroundColor: Colors.transparent,
      elevation: 0,
      onPressed: () => _showTxSheet(context),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    ),
  );

  Widget _navBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? BF.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? BF.darkBorder : BF.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
      ),
      child: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: BF.accent,
        unselectedItemColor: isDark
            ? Colors.white.withOpacity(0.3)
            : Colors.black.withOpacity(0.3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _page() {
    switch (_tab) {
      case 0:
        return _dashboard();
      case 1:
        return _activityPage();
      default:
        return _profilePage();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Widget _dashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double income = 0, expense = 0;
    final Map<String, double> catTotals = {};
    for (var tx in _s.transactions) {
      if (tx['isIncome']) {
        income += tx['amount'] as double;
      } else {
        expense += tx['amount'] as double;
        final c = tx['category'] as String;
        catTotals[c] = (catTotals[c] ?? 0) + (tx['amount'] as double);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi, ${widget.username.isNotEmpty ? widget.username.split(' ')[0] : 'User'} 👋",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.white : BF.primary,
                    ),
                  ),
                  Text(
                    "Your finance overview",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: isDark
                          ? Colors.white.withOpacity(0.45)
                          : Colors.black.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              _avatar(widget.username, size: 44),
            ],
          ),

          const SizedBox(height: 22),
          _balanceCard(isDark),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _summaryTile("Income", income, true, isDark)),
              const SizedBox(width: 12),
              Expanded(child: _summaryTile("Expenses", expense, false, isDark)),
            ],
          ),
          const SizedBox(height: 18),
          _featureGrid(isDark),
          const SizedBox(height: 18),
          _budgetAlerts(isDark),

          if (income > 0 || expense > 0) ...[
            _sectionHead("Overview", isDark),
            const SizedBox(height: 12),
            _pieCard(income, expense, isDark),
            const SizedBox(height: 18),
          ],

          if (catTotals.isNotEmpty) ...[
            _sectionHead("Spending Breakdown", isDark),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: catTotals.entries.map((e) {
                  final pct = expense > 0
                      ? (e.value / expense * 100).toStringAsFixed(0)
                      : '0';
                  return _catChip(e.key, pct, isDark);
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (_s.savingsGoals.isNotEmpty) ...[
            _sectionHead(
              "Savings Goals",
              isDark,
              action: _viewAll("View All", () => _push(SavingsPage())),
            ),
            const SizedBox(height: 12),
            ..._s.savingsGoals.take(2).map((g) => _goalMini(g, isDark)),
            const SizedBox(height: 18),
          ],

          _sectionHead(
            "Recent Transactions",
            isDark,
            action: _s.transactions.isNotEmpty
                ? _viewAll("See All", () => setState(() => _tab = 1))
                : null,
          ),
          const SizedBox(height: 12),
          _s.transactions.isEmpty
              ? _emptyState(
                  isDark,
                  "No transactions yet",
                  Icons.receipt_long_outlined,
                )
              : Column(
                  children: _s.transactions
                      .take(5)
                      .map((tx) => _txTile(tx, isDark))
                      .toList(),
                ),
        ],
      ),
    );
  }

  // ── Balance card ──────────────────────────────────────────────────────────

  Widget _balanceCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2F6E), Color(0xFF3B30C4), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BF.accent.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Balance",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: BF.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Live",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(_balance),
            style: const TextStyle(
              fontSize: 36,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showTxSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                "Add Transaction",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: BF.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Feature grid ──────────────────────────────────────────────────────────

  Widget _featureGrid(bool isDark) {
    final features = [
      {
        'label': 'Budget',
        'icon': Icons.wallet_rounded,
        'color': const Color(0xFF3B82F6),
        'page': BudgetPage(),
      },
      {
        'label': 'Reports',
        'icon': Icons.bar_chart_rounded,
        'color': BF.green,
        'page': ReportsPage(),
      },
      {
        'label': 'Recurring',
        'icon': Icons.repeat_rounded,
        'color': BF.amber,
        'page': RecurringPage(),
      },
      {
        'label': 'Accounts',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFFEC4899),
        'page': AccountsPage(),
      },
      {
        'label': 'Savings',
        'icon': Icons.savings_rounded,
        'color': const Color(0xFF8B5CF6),
        'page': SavingsPage(),
      },
    ];

    return Row(
      children: features.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        final color = f['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => _push(f['page'] as Widget),
            child: Container(
              margin: EdgeInsets.only(right: i < features.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BF.card(isDark),
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(f['icon'] as IconData, color: color, size: 19),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Budget alerts ─────────────────────────────────────────────────────────

  Widget _budgetAlerts(bool isDark) {
    final alerts = _s.budgets.where((b) {
      final spent = _s.spentInCategory(b['category'] as String);
      final limit = b['limit'] as double;
      return limit > 0 && (spent / limit) >= 0.8;
    }).toList();
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ...alerts.take(2).map((b) {
          final spent = _s.spentInCategory(b['category'] as String);
          final limit = b['limit'] as double;
          final isOver = spent > limit;
          final c = isOver ? BF.red : BF.amber;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  isOver
                      ? Icons.warning_rounded
                      : Icons.notifications_active_rounded,
                  color: c,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isOver
                        ? "${b['category']} over budget by ${currency.format(spent - limit)}"
                        : "${b['category']} at ${((spent / limit) * 100).toStringAsFixed(0)}% of budget",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Savings goal mini ─────────────────────────────────────────────────────

  Widget _goalMini(Map<String, dynamic> g, bool isDark) {
    final saved = g['saved'] as double;
    final target = g['target'] as double;
    final pct = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BF.card(isDark),
      child: Column(
        children: [
          Row(
            children: [
              Text(g['emoji'] ?? '🎯', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  g['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                "${(pct * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: BF.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: BF.accent.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(BF.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currency.format(saved),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                currency.format(target),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVITY PAGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _activityPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txs = _filteredTxs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              // Search bar
              Container(
                height: 48,
                decoration: BF
                    .card(isDark)
                    .copyWith(borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search transactions…",
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _searchQuery = ''),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 18,
                          ),
                        ),
                      ),
                    if (_searchQuery.isEmpty) const SizedBox(width: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip(
                      "All",
                      _filterType == 'All' && _filterCategory == 'All',
                      isDark,
                      () => setState(() {
                        _filterType = 'All';
                        _filterCategory = 'All';
                        _filterDateRange = null;
                      }),
                    ),
                    _chip(
                      "Income",
                      _filterType == 'Income',
                      isDark,
                      () => setState(
                        () => _filterType = _filterType == 'Income'
                            ? 'All'
                            : 'Income',
                      ),
                    ),
                    _chip(
                      "Expense",
                      _filterType == 'Expense',
                      isDark,
                      () => setState(
                        () => _filterType = _filterType == 'Expense'
                            ? 'All'
                            : 'Expense',
                      ),
                    ),
                    ..._categories
                        .where((c) => c != 'All')
                        .map(
                          (c) => _chip(
                            c,
                            _filterCategory == c,
                            isDark,
                            () => setState(
                              () => _filterCategory = _filterCategory == c
                                  ? 'All'
                                  : c,
                            ),
                          ),
                        ),
                    _chip(
                      _filterDateRange != null ? "📅 Date ✓" : "📅 Date",
                      _filterDateRange != null,
                      isDark,
                      () async {
                        final r = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _filterDateRange,
                        );
                        setState(() => _filterDateRange = r);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
              ? _emptyState(
                  isDark,
                  "No transactions found",
                  Icons.search_off_rounded,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                  itemCount: txs.length,
                  itemBuilder: (_, i) => _txTile(txs[i], isDark),
                ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE PAGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _profilePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalIncome = _s.transactions
        .where((t) => t['isIncome'])
        .fold(0.0, (s, t) => s + (t['amount'] as double));
    final totalExpense = _s.transactions
        .where((t) => !t['isIncome'])
        .fold(0.0, (s, t) => s + (t['amount'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Profile header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A2F6E),
                  Color(0xFF3B30C4),
                  Color(0xFF6C63FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: BF.accent.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _avatar(widget.username, size: 80),
                const SizedBox(height: 14),
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "BudgetFlow Member",
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          // First row - only Transactions and Goals
          Row(
            children: [
              Expanded(
                child: _statBox(
                  "Transactions",
                  "${_s.transactions.length}",
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox("Goals", "${_s.savingsGoals.length}", isDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second row - Income and Expenses
          Row(
            children: [
              Expanded(
                child: _statBox2(
                  "Total Income",
                  currency.format(totalIncome),
                  BF.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox2(
                  "Total Spent",
                  currency.format(totalExpense),
                  BF.red,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),
          _sectionHead("Features", isDark),
          const SizedBox(height: 12),
          _profileLink(
            isDark,
            Icons.wallet_rounded,
            "Budget Manager",
            const Color(0xFF3B82F6),
            () => _push(BudgetPage()),
          ),
          _profileLink(
            isDark,
            Icons.bar_chart_rounded,
            "Reports & Analytics",
            BF.green,
            () => _push(ReportsPage()),
          ),
          _profileLink(
            isDark,
            Icons.repeat_rounded,
            "Recurring Transactions",
            BF.amber,
            () => _push(RecurringPage()),
          ),
          _profileLink(
            isDark,
            Icons.account_balance_rounded,
            "Accounts & Wallets",
            const Color(0xFFEC4899),
            () => _push(AccountsPage()),
          ),
          _profileLink(
            isDark,
            Icons.savings_rounded,
            "Savings Goals",
            const Color(0xFF8B5CF6),
            () => _push(SavingsPage()),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BF.red,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ADD / EDIT TRANSACTION SHEET
  // ══════════════════════════════════════════════════════════════════════════

  void _showTxSheet(BuildContext context, {Map<String, dynamic>? existing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing['amount'] as double).toStringAsFixed(0)
          : '',
    );
    final noteCtrl = TextEditingController(text: existing?['title'] ?? '');
    final categoryCtrl = TextEditingController(
      text: existing?['category'] ?? '',
    );
    bool isIncome = existing?['isIncome'] ?? true;
    String accountId =
        existing?['accountId'] ??
        (_s.accounts.isNotEmpty
            ? _s.accounts[0]['id'] as String
            : 'cash_default');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: isDark ? BF.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  existing != null ? "Edit Transaction" : "New Transaction",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // Type toggle
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? BF.darkSurface : BF.lightBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _toggle(
                        "Income",
                        true,
                        isIncome,
                        isDark,
                        setS,
                        () => isIncome = true,
                      ),
                      _toggle(
                        "Expense",
                        false,
                        isIncome,
                        isDark,
                        setS,
                        () => isIncome = false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _sheetField(
                  amountCtrl,
                  "Amount",
                  isDark,
                  prefix: "₱ ",
                  type: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _sheetField(noteCtrl, "Title / Note", isDark),
                const SizedBox(height: 12),
                _sheetField(categoryCtrl, "Category", isDark),
                const SizedBox(height: 12),

                if (_s.accounts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? BF.darkSurface : BF.lightBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? BF.darkBorder : BF.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: accountId,
                        isExpanded: true,
                        dropdownColor: isDark ? BF.darkCard : Colors.white,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: _s.accounts
                            .map(
                              (a) => DropdownMenuItem<String>(
                                value: a['id'] as String,
                                child: Row(
                                  children: [
                                    Text(
                                      a['emoji'] ?? '💰',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      a['name'],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setS(() => accountId = v!),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BF.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text) ?? 0;
                      if (amount <= 0) return;
                      final map = {
                        'id': existing?['id'] ?? UniqueKey().toString(),
                        'title': noteCtrl.text.isEmpty
                            ? (isIncome ? "Income" : "Expense")
                            : noteCtrl.text,
                        'amount': amount,
                        'isIncome': isIncome,
                        'category': categoryCtrl.text.isEmpty
                            ? 'General'
                            : categoryCtrl.text,
                        'accountId': accountId,
                        'date': existing?['date'] ?? DateTime.now(),
                        'note': noteCtrl.text,
                      };
                      if (existing != null) {
                        _s.editTransaction(existing['id'], map);
                      } else {
                        _s.addTransaction(map);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      existing != null ? "Save Changes" : "Add Transaction",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _txTile(Map<String, dynamic> tx, bool isDark) {
    final isIncome = tx['isIncome'] as bool;
    final id = tx['id'] as String;
    final acc = _s.accounts.firstWhere(
      (a) => a['id'] == tx['accountId'],
      orElse: () => {'name': '', 'emoji': ''},
    );

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _s.deleteTransaction(id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: BF.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _showTxSheet(context, existing: tx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BF.card(isDark),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isIncome
                      ? BF.green.withOpacity(0.12)
                      : BF.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIncome ? BF.green : BF.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BF.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx['category'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: BF.accent,
                            ),
                          ),
                        ),
                        if ((acc['name'] as String).isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            "${acc['emoji']} ${acc['name']}",
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Poppins',
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(
                        'dd MMM yyyy · hh:mm a',
                      ).format(tx['date'] as DateTime),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isIncome ? '+' : '-'}${currency.format(tx['amount'])}",
                    style: TextStyle(
                      color: isIncome ? BF.green : BF.red,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryTile(String label, double amount, bool isIncome, bool isDark) {
    final color = isIncome ? BF.green : BF.red;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BF.card(isDark),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                Text(
                  currency.format(amount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pieCard(double income, double expense, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BF.card(isDark),
      child: PieChart(
        dataMap: {
          if (income > 0) "Income": income,
          if (expense > 0) "Expense": expense,
        },
        chartType: ChartType.ring,
        ringStrokeWidth: 22,
        chartRadius: 120,
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
    );
  }

  Widget _catChip(String label, String percent, bool isDark) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BF.card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: BF.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.category_rounded,
              size: 15,
              color: BF.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              fontSize: 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            "$percent%",
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String title, bool isDark, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _viewAll(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: BF.accent,
        ),
      ),
    );
  }

  Widget _emptyState(bool isDark, String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BF.card(isDark),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              size: 28,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, {double size = 44}) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'U';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [BF.accent, BF.accentSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          fontSize: size * 0.32,
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? BF.accent
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? BF.accent
                : (isDark ? BF.darkBorder : BF.lightBorder),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _toggle(
    String label,
    bool value,
    bool current,
    bool isDark,
    StateSetter setS,
    VoidCallback fn,
  ) {
    final sel = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => setS(() => fn()),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? (value ? BF.green : BF.red) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: (value ? BF.green : BF.red).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: sel
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    bool isDark, {
    String? prefix,
    TextInputType? type,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixStyle: TextStyle(
          fontFamily: 'Poppins',
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        filled: true,
        fillColor: isDark ? BF.darkSurface : BF.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? BF.darkBorder : BF.lightBorder,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BF.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BF.card(isDark),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: BF.accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statBox2(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BF.card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
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

  Widget _profileLink(
    bool isDark,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BF.card(isDark),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
