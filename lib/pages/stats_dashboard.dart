import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/streak_calendar.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsDashboard extends StatefulWidget {
  const StatsDashboard({super.key});

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard>
    with SingleTickerProviderStateMixin {
  List<HabbitModel> _habits = [];
  bool _isLoading = true;
  late TabController _tabController;
  HabbitModel? _selectedHabit;

  final List<String> _types = ['Binary', 'Count', 'Duration'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final prefs = Provider.of<SharedPreferences>(context, listen: false);
    final json = prefs.getStringList('habbits') ?? [];
    setState(() {
      _habits = json
          .map(
            (e) => HabbitModel.fromJson(jsonDecode(e) as Map<String, dynamic>),
          )
          .toList();
      _isLoading = false;
    });
  }

  // ── Aggregation helpers ──────────────────────────────────────────────────

  int _currentStreak(HabbitModel h) {
    final logs = h.logs;
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

  int _bestStreak(HabbitModel h) {
    final logs = [...h.logs]..sort((a, b) => a.date.compareTo(b.date));
    int best = 0, current = 0;
    DateTime? prev;
    for (final log in logs) {
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

  double _completionRate(HabbitModel h) {
    if (h.logs.isEmpty) return 0;
    return h.logs.where((l) => l.isCompleted).length / h.logs.length * 100;
  }

  double _avgValue(HabbitModel h) {
    if (h.logs.isEmpty) return 0;
    return h.logs.map((l) => l.value).reduce((a, b) => a + b) / h.logs.length;
  }

  // Last 7 days bar data
  List<BarChartGroupData> _barData(HabbitModel h) {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dayLogs = h.logs.where(
        (l) =>
            l.date.year == day.year &&
            l.date.month == day.month &&
            l.date.day == day.day,
      );
      double y = 0;
      if (h.type == 'Binary') {
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
          (h) => h.logs.any(
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
      : _habits.map(_bestStreak).reduce((a, b) => a > b ? a : b);

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stats',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: Divider(color: AppColors.grey3),
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
                  const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.streak,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Today\'s Overview',
                style: GoogleFonts.ubuntu(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey4,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryChip(
                label: 'Done Today',
                value: '$_todayCompleted / $_totalHabits',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.success,
              ),
              _summaryChip(
                label: 'Completion',
                value: '$rate%',
                icon: Icons.pie_chart_rounded,
                iconColor: AppColors.primary,
              ),
              _summaryChip(
                label: 'Best Streak',
                value: '${_globalBestStreak}d',
                icon: Icons.emoji_events_rounded,
                iconColor: AppColors.gold,
              ),
            ],
          ),
          if (_totalHabits > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _totalHabits == 0 ? 0 : _todayCompleted / _totalHabits,
                minHeight: 8,
                backgroundColor: AppColors.grey5.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  rate >= 80
                      ? AppColors.success
                      : rate >= 50
                      ? AppColors.gold
                      : AppColors.streak,
                ),
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
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.ubuntu(fontSize: 11, color: AppColors.grey4),
        ),
      ],
    );
  }

  // ── Tab section ──────────────────────────────────────────────────────────
  Widget _buildTabSection() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() => _selectedHabit = null),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey5,
            labelStyle: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.ubuntu(
              fontWeight: FontWeight.normal,
            ),
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.grey3,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            tabs: _types.map((t) => Tab(text: t)).toList(),
          ),
        ),
        const SizedBox(height: 14),
        _buildTypeTab(_types[_tabController.index]),
      ],
    );
  }

  Widget _buildTypeTab(String type) {
    final habits = _habits.where((h) => h.type == type).toList();
    if (habits.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: AppColors.grey4),
            const SizedBox(height: 10),
            Text(
              'No $type habits yet',
              style: GoogleFonts.ubuntu(color: AppColors.grey5, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Habit selector chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _habitChip(null, 'Overview', type),
              ...habits.map((h) => _habitChip(h, h.name, type)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Content: either overview or selected habit
        _selectedHabit == null || _selectedHabit!.type != type
            ? _buildOverviewCards(habits, type)
            : _buildHabitDetail(_selectedHabit!),
      ],
    );
  }

  Widget _habitChip(HabbitModel? habit, String label, String activeType) {
    final isSelected = habit == null
        ? (_selectedHabit == null || _selectedHabit!.type != activeType)
        : _selectedHabit?.id == habit.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedHabit = habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.grey6,
          ),
        ),
      ),
    );
  }

  // ── Overview: all habits of a type as summary rows ───────────────────────
  Widget _buildOverviewCards(List<HabbitModel> habits, String type) {
    return Column(
      children: habits.map((h) => _buildSummaryRow(h, type)).toList(),
    );
  }

  Widget _buildSummaryRow(HabbitModel h, String type) {
    final streak = _currentStreak(h);
    final rate = _completionRate(h);
    return GestureDetector(
      onTap: () => setState(() => _selectedHabit = h),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey3),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey3.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(h.iconData, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.name,
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
  Widget _buildHabitDetail(HabbitModel h) {
    final streak = _currentStreak(h);
    final best = _bestStreak(h);
    final rate = _completionRate(h);
    final avg = _avgValue(h);
    final isBinary = h.type == 'Binary';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                h.type == 'Count' ? '📊 Avg' : '⏱ Avg',
                h.type == 'Count'
                    ? '${avg.toStringAsFixed(1)}x'
                    : '${avg.toStringAsFixed(0)}m',
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
          child: StreakCalendar(logs: h.logs),
        ),
        const SizedBox(height: 16),

        // Bar chart – last 7 days
        Text(
          'Last 7 Days${isBinary ? '' : ' (total ${h.type == 'Count' ? 'count' : 'mins'})'}',
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.grey5,
          ),
        ),
        const SizedBox(height: 8),
        _buildBarChart(h),
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

  Widget _buildBarChart(HabbitModel h) {
    final bars = _barData(h);
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
                    rod.toY == 1 && h.type == 'Binary'
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
