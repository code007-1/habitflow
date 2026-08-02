import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/components/detailed_log_list.dart';
import 'package:habbit/components/streak_calendar.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/core/data_provider.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/unit_of_measure.dart';

class LogHabbit extends StatefulWidget {
  final HabbitModel habbit;
  final String userId;

  const LogHabbit({super.key, required this.habbit, required this.userId});

  @override
  State<LogHabbit> createState() => _LogHabbitState();
}

class _LogHabbitState extends State<LogHabbit> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<HabbitLogModel>? _habbitLogs;
  bool _saving = false;

  HabbitModel get habbit => widget.habbit;

  @override
  void initState() {
    super.initState();
    DataProvider.getFilteredData(
      'habbitId',
      habbit.id,
      DataProvider.habitslogRef,
    ).then((value) {
      if (!mounted) return;
      setState(() => _habbitLogs = value);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Derived data ───────────────────────────────────────────────────────────
  List<HabbitLogModel> get _logs => _habbitLogs ?? [];
  bool get _loading => _habbitLogs == null;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<HabbitLogModel> get _todayLogs =>
      _logs.where((l) => _sameDay(l.date, DateTime.now())).toList();

  bool get _doneToday => _todayLogs.any((l) => l.isCompleted);

  double get _todayTotal => _todayLogs.fold(0.0, (sum, l) => sum + l.value);

  double get _todayProgress => habbit.goalValue <= 0
      ? 0
      : (_todayTotal / habbit.goalValue).clamp(0.0, 1.0);

  int get _currentStreak {
    if (_logs.isEmpty) return 0;
    final sorted = [..._logs]..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    DateTime cursor = DateTime.now();
    for (final log in sorted) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      if (cursor.difference(day).inDays > 1) break;
      if (log.isCompleted) {
        streak++;
        cursor = day;
      }
    }
    return streak;
  }

  int get _bestStreak {
    if (_logs.isEmpty) return 0;
    final sorted = [..._logs]..sort((a, b) => a.date.compareTo(b.date));
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

  int get _completionRate {
    if (_logs.isEmpty) return 0;
    return (_logs.where((l) => l.isCompleted).length / _logs.length * 100)
        .round();
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _saveLog() async {
    double value = 1;
    bool isCompleted = true;
    if (!habbit.isBinary) {
      value = double.tryParse(_inputController.text.trim()) ?? 0;
      if (value <= 0) {
        _showSnack('Enter a value to log', AppColors.error);
        return;
      }
      isCompleted =
          Measurement(value, habbit.unit).baseValue >= habbit.goal.baseValue;
    }

    final newLog = HabbitLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.userId,
      habbitId: habbit.id,
      date: DateTime.now(),
      value: value,
      unitId: habbit.unitId,
      isCompleted: isCompleted,
      note: _noteController.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await DataProvider.saveData(newLog, DataProvider.habitslogRef);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Save failed: $e', AppColors.error);
      return;
    }

    if (!mounted) return;
    setState(() {
      _habbitLogs = [...?_habbitLogs, newLog];
      _saving = false;
      _inputController.clear();
      _noteController.clear();
    });
    _showSnack('Log saved successfully!', AppColors.success);
  }

  // ── Edit / duplicate / delete ──────────────────────────────────────────────
  /// Applies a change locally first, then persists it — rolling the list back
  /// if the write fails so the UI never claims a save that didn't happen.
  Future<void> _mutateLogs(
    List<HabbitLogModel> next,
    Future<void> Function() write,
    String successMessage,
    String failurePrefix,
  ) async {
    final previous = _habbitLogs;
    setState(() => _habbitLogs = next);

    try {
      await write();
    } catch (e) {
      if (!mounted) return;
      setState(() => _habbitLogs = previous);
      _showSnack('$failurePrefix: $e', AppColors.error);
      return;
    }

    if (!mounted) return;
    _showSnack(successMessage, AppColors.success);
  }

  Future<void> _updateLog(HabbitLogModel updated) {
    return _mutateLogs(
      [
        for (final log in _logs)
          if (log.id == updated.id) updated else log,
      ],
      () => DataProvider.updateById(
        updated.id,
        updated,
        DataProvider.habitslogRef,
      ),
      'Log updated',
      'Update failed',
    );
  }

  Future<void> _duplicateLog(HabbitLogModel source) {
    final copy = source.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
    );

    return _mutateLogs(
      [..._logs, copy],
      () => DataProvider.saveData(copy, DataProvider.habitslogRef),
      'Logged again just now',
      'Save failed',
    );
  }

  Future<void> _deleteLogs(List<HabbitLogModel> logs) {
    if (logs.isEmpty) return Future.value();
    final ids = logs.map((l) => l.id).toSet();

    return _mutateLogs(
      _logs.where((log) => !ids.contains(log.id)).toList(),
      () => Future.wait(
        ids.map(
          (id) => DataProvider.deleteWhere('id', id, DataProvider.habitslogRef),
        ),
      ),
      ids.length == 1 ? 'Log deleted' : '${ids.length} logs deleted',
      'Delete failed',
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          color: AppColors.grey7,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          habbit.name,
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.grey3, height: 1),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildTodayCard(),
            const SizedBox(height: 16),
            _buildLogEntry(),
            const SizedBox(height: 20),
            _buildCalendar(),
            const SizedBox(height: 20),
            DetailedLogList(
              habbit: habbit,
              habbitLogs: _logs,
              isLoading: _loading,
              onEdit: _updateLog,
              onDuplicate: _duplicateLog,
              onDelete: _deleteLogs,
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero header ──────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(habbit.iconData, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habbit.name,
                      style: GoogleFonts.ubuntu(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (habbit.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habbit.description,
                        style: GoogleFonts.ubuntu(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _heroStat('🔥', 'Streak', '$_currentStreak d'),
              _heroStatDivider(),
              _heroStat('🏆', 'Best', '$_bestStreak d'),
              _heroStatDivider(),
              _heroStat('✅', 'Rate', '$_completionRate%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String emoji, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
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
            style: GoogleFonts.ubuntu(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatDivider() => Container(
    width: 1,
    height: 38,
    color: Colors.white.withValues(alpha: 0.25),
  );

  // ── Today progress card ────────────────────────────────────────────────────
  Widget _buildTodayCard() {
    final now = DateTime.now();
    final dateLabel = '${now.day}/${now.month}/${now.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _buildTodayIndicator(),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Goal",
                  style: GoogleFonts.ubuntu(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    color: AppColors.grey5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  habbit.isBinary
                      ? (_doneToday
                            ? 'Completed for today 🎉'
                            : 'Not done yet — mark it below.')
                      : '${_formatNum(_todayTotal)} / ${habbit.goal.format()} logged today',
                  style: GoogleFonts.ubuntu(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _doneToday || _todayProgress >= 1
                        ? AppColors.success
                        : AppColors.grey6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayIndicator() {
    final done = habbit.isBinary ? _doneToday : _todayProgress >= 1;
    final color = done ? AppColors.success : AppColors.primary;
    final progress = habbit.isBinary
        ? (_doneToday ? 1.0 : 0.0)
        : _todayProgress;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 7,
              backgroundColor: AppColors.grey2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (habbit.isBinary)
            Icon(
              done ? Icons.check_rounded : Icons.bolt_rounded,
              color: color,
              size: 30,
            )
          else
            Text(
              '${(_todayProgress * 100).round()}%',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  // ── Log entry card ─────────────────────────────────────────────────────────
  Widget _buildLogEntry() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log an Entry',
            style: GoogleFonts.ubuntu(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.grey7,
            ),
          ),
          const SizedBox(height: 14),
          if (habbit.isBinary) _buildBinaryAction() else _buildValueInput(),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.grey2,
              hintText: 'Add a quick note (optional)…',
              hintStyle: TextStyle(color: AppColors.grey4),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinaryAction() {
    if (_doneToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 30,
            ),
            const SizedBox(height: 6),
            Text(
              'Done for today',
              style: GoogleFonts.ubuntu(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _saving ? null : _saveLog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowBrand,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _saving
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
            const SizedBox(height: 4),
            Text(
              'Mark as Done',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.grey2,
              hintText: 'Enter ${habbit.unit.name.toLowerCase()}',
              hintStyle: TextStyle(color: AppColors.grey4),
              suffixText: habbit.unit.symbol.isEmpty
                  ? null
                  : habbit.unit.symbol,
              suffixStyle: GoogleFonts.ubuntu(
                color: AppColors.grey6,
                fontWeight: FontWeight.w700,
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.primary),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _saving ? null : _saveLog,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Log',
                      style: GoogleFonts.ubuntu(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Calendar card ──────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month',
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.grey7,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: _cardDecoration(),
          child: StreakCalendar(logs: _logs),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
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
  );

  String _formatNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
