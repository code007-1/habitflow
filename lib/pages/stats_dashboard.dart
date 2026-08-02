import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/streak_calendar.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/models/unit_of_measure.dart';

class StatsDashboard extends StatefulWidget {
  const StatsDashboard({super.key});

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard>
    with SingleTickerProviderStateMixin {
  List<HabbitModel> _habits = [];
  List<HabbitLogModel> _allLogs = [];
  bool _isLoading = true;
  late TabController _tabController;
  HabbitModel? _selectedHabit;

  final List<Dimension> _dims = Units.dimensions;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dims.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedHabit = null;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHabits());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHabits() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final habits = await DataProvider.getUserData(DataProvider.habitsRef);
      final logs = await DataProvider.getUserData(DataProvider.habitslogRef);
      setState(() {
        _habits = habits;
        _allLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<HabbitLogModel> _getLogsForHabit(HabbitModel habbit) {
    return _allLogs.where((l) => l.habbitId == habbit.id).toList();
  }

  // ── Aggregation helpers ──────────────────────────────────────────────────

  int _currentStreak(List<HabbitLogModel> logs) {
    if (logs.isEmpty) return 0;
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime cursor = DateTime.now();
    for (final log in sorted) {
      final diff = cursor
          .difference(DateTime(log.date.year, log.date.month, log.date.day))
          .inDays;
      if (diff > 1) break;
      if (log.isCompleted) {
        streak++;
        cursor = DateTime(log.date.year, log.date.month, log.date.day);
      }
    }
    return streak;
  }

  int _bestStreak(List<HabbitLogModel> logs) {
    if (logs.isEmpty) return 0;
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    int best = 0, current = 0;
    DateTime? prev;
    for (final log in sorted) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      if (prev == null || day.difference(prev).inDays == 1) {
        if (log.isCompleted) current++;
      } else {
        current = log.isCompleted ? 1 : 0;
      }
      if (current > best) best = current;
      prev = day;
    }
    return best;
  }

  double _completionRate(List<HabbitLogModel> logs) {
    if (logs.isEmpty) return 0;
    return (logs.where((l) => l.isCompleted).length / logs.length * 100)
        .roundToDouble();
  }

  double _avgValue(List<HabbitLogModel> logs) {
    if (logs.isEmpty) return 0;
    return logs.map((l) => l.value).reduce((a, b) => a + b) / logs.length;
  }

  // Last 7 days bar data
  List<BarChartGroupData> _barData(
    List<HabbitLogModel> logs,
    bool isBinary,
  ) {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dayLogs = logs.where(
        (l) =>
            l.date.year == day.year &&
            l.date.month == day.month &&
            l.date.day == day.day,
      );
      double y = 0;
      if (isBinary) {
        y = dayLogs.any((l) => l.isCompleted) ? 1 : 0;
      } else {
        y = dayLogs.isEmpty
            ? 0
            : dayLogs.map((l) => l.value).reduce((a, b) => a + b).toDouble();
      }
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: y,
            color: y > 0 ? AppColors.primary : AppColors.grey3,
            width: 18,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });
  }

  // ── Global aggregations across all habits ────────────────────────────────

  int get _totalHabits => _habits.length;
  int get _todayCompleted {
    final today = DateTime.now();
    return _habits
        .where(
          (h) => _getLogsForHabit(h).any(
            (l) =>
                l.date.year == today.year &&
                l.date.month == today.month &&
                l.date.day == today.day &&
                l.isCompleted,
          ),
        )
        .length;
  }

  int get _globalBestStreak => _habits.isEmpty
      ? 0
      : _habits
          .map((h) => _bestStreak(_getLogsForHabit(h)))
          .reduce((a, b) => a > b ? a : b);

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Your Progress',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Divider(color: AppColors.grey3, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHabits,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGlobalSummary(),
                  const SizedBox(height: 24),
                  _buildTabSection(),
                ],
              ),
            ),
    );
  }

  // ── Global summary card ──────────────────────────────────────────────────
  Widget _buildGlobalSummary() {
    final rate = _totalHabits == 0
        ? 0
        : (_todayCompleted / _totalHabits * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowBrand,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Today's Overview",
                style: GoogleFonts.ubuntu(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _summaryChip(
                label: 'Done Today',
                value: '$_todayCompleted / $_totalHabits',
                icon: Icons.check_circle_rounded,
              ),
              _summaryChip(
                label: 'Completion',
                value: '$rate%',
                icon: Icons.pie_chart_rounded,
              ),
              _summaryChip(
                label: 'Best Streak',
                value: '${_globalBestStreak}d',
                icon: Icons.emoji_events_rounded,
              ),
            ],
          ),
          if (_totalHabits > 0) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalHabits == 0 ? 0 : _todayCompleted / _totalHabits,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rate >= 80
                  ? "You're on fire today! 🔥"
                  : rate >= 50
                  ? 'Great pace — keep going!'
                  : 'A few more to reach your goal.',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab section ──────────────────────────────────────────────────────────
  Widget _buildTabSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Habits by Type',
            style: GoogleFonts.ubuntu(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.grey7,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.grey2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (_) => setState(() => _selectedHabit = null),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.primaryDeep,
            unselectedLabelColor: AppColors.grey5,
            labelStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.ubuntu(
              fontWeight: FontWeight.w500,
            ),
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            tabs: _dims.map((d) => Tab(text: d.label)).toList(),
          ),
        ),
        const SizedBox(height: 16),
        _buildTypeTab(_dims[_tabController.index]),
      ],
    );
  }

  Widget _buildTypeTab(Dimension dim) {
    final habits = _habits.where((h) => h.dimension == dim).toList();
    if (habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppColors.grey4),
            const SizedBox(height: 10),
            Text(
              'No ${dim.label} habits yet',
              style: GoogleFonts.ubuntu(color: AppColors.grey5, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Content: either overview or selected habit
        _selectedHabit == null || _selectedHabit!.dimension != dim
            ? _buildOverviewCards(habits)
            : _buildHabitDetail(_selectedHabit!),
      ],
    );
  }

  // ── Overview: all habits of a type as summary rows ───────────────────────
  Widget _buildOverviewCards(List<HabbitModel> habits) {
    return Column(
      children: habits.map((h) => _buildSummaryRow(h)).toList(),
    );
  }

  Widget _buildSummaryRow(HabbitModel habbit) {
    final logs = _getLogsForHabit(habbit);
    final streak = _currentStreak(logs);
    final rate = _completionRate(logs);
    return GestureDetector(
      onTap: () => setState(() => _selectedHabit = habbit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.grey3),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                habbit.iconData,
                color: AppColors.primaryDeep,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habbit.name,
                    style: GoogleFonts.ubuntu(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.grey7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate / 100,
                      minHeight: 5,
                      backgroundColor: AppColors.grey3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rate >= 80 ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.streak,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$streak',
                      style: GoogleFonts.ubuntu(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.streak,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${rate.round()}%',
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: AppColors.grey5,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.grey4,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Detailed view for a single selected habit ────────────────────────────
  Widget _buildHabitDetail(HabbitModel habbit) {
    final logs = _getLogsForHabit(habbit);
    final streak = _currentStreak(logs);
    final best = _bestStreak(logs);
    final rate = _completionRate(logs);
    final avg = _avgValue(logs);
    final isBinary = habbit.isBinary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back navigation and Habit title
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedHabit = null),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.grey2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.grey6,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(habbit.iconData, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                habbit.name,
                style: GoogleFonts.ubuntu(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.grey7,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Stat chips row
        Row(
          children: [
            _statPill(
              '🔥 Streak',
              '$streak d',
              AppColors.streakLight,
              AppColors.streak,
            ),
            const SizedBox(width: 8),
            _statPill(
              '🏆 Best',
              '$best d',
              AppColors.goldLight,
              AppColors.gold,
            ),
            const SizedBox(width: 8),
            _statPill(
              '✅ Rate',
              '${rate.round()}%',
              const Color(0xFFDCFCE7),
              AppColors.success,
            ),
            if (!isBinary) ...[
              const SizedBox(width: 8),
                _statPill(
                '📊 Avg',
                '${avg.toStringAsFixed(1)} ${habbit.unit.symbol}'.trim(),
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Streak calendar
        Text(
          'Monthly Calendar',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.grey5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.grey3),
          ),
          child: StreakCalendar(logs: logs),
        ),
        const SizedBox(height: 16),

        // Bar chart – last 7 days
        Text(
          'Last 7 Days${isBinary ? '' : ' (total ${habbit.unit.symbol})'}',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.grey5,
          ),
        ),
        const SizedBox(height: 8),
        _buildBarChart(habbit, logs),
      ],
    );
  }

  Widget _statPill(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                fontSize: 10,
                color: fg.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(HabbitModel habbit, List<HabbitLogModel> logs) {
    final bars = _barData(logs, habbit.isBinary);
    final maxY = bars
        .map((g) => g.barRods.first.toY)
        .fold<double>(0, (prev, y) => y > prev ? y : prev);
    final today = DateTime.now();
    const weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey3),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.3,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.grey3, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final date = today.subtract(
                    Duration(days: 6 - value.toInt()),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      weekDays[date.weekday - 1],
                      style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        color: AppColors.grey5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: bars,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.grey7,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                    rod.toY == 1 && habbit.isBinary
                        ? '✓'
                        : rod.toY.toStringAsFixed(0),
                    GoogleFonts.ubuntu(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
