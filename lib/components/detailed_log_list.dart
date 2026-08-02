import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/habbit_model.dart';
import 'package:habbit/models/unit_of_measure.dart';

/// Where a single log sits within its day.
///
/// Derived per day (not stored): logs are walked in chronological order and
/// compared against the habit goal, so an entry made after the goal was already
/// reached reads as extra credit rather than yet another "completed".
enum _LogStatus { completed, extraCredit, partial, missed }

/// One log paired with the status it earned inside its day.
class _Entry {
  final HabbitLogModel log;
  final _LogStatus status;

  const _Entry(this.log, this.status);
}

/// A day of logs, newest day first.
class _DayGroup {
  final DateTime day;
  final List<_Entry> entries;

  const _DayGroup(this.day, this.entries);
}

/// Detailed, per-entry history for a habit: logs grouped into day cards with
/// time, status, note and inline actions (edit / duplicate / delete), plus a
/// multi-select mode for deleting several entries at once.
///
/// Persistence is left to the parent — this widget only reports intent through
/// [onEdit], [onDuplicate] and [onDelete].
class DetailedLogList extends StatefulWidget {
  final HabbitModel habbit;
  final List<HabbitLogModel> habbitLogs;
  final bool isLoading;

  /// Called with the edited copy of a log.
  final ValueChanged<HabbitLogModel> onEdit;

  /// Called with the log that should be re-logged at the current time.
  final ValueChanged<HabbitLogModel> onDuplicate;

  /// Called with every log the user confirmed for deletion.
  final ValueChanged<List<HabbitLogModel>> onDelete;

  const DetailedLogList({
    super.key,
    required this.habbit,
    required this.habbitLogs,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.isLoading = false,
  });

  @override
  State<DetailedLogList> createState() => _DetailedLogListState();
}

class _DetailedLogListState extends State<DetailedLogList> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  HabbitModel get habbit => widget.habbit;

  // ── Grouping & status ──────────────────────────────────────────────────────
  List<_DayGroup> get _groups {
    final Map<DateTime, List<HabbitLogModel>> byDay = {};
    for (final log in widget.habbitLogs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      byDay.putIfAbsent(day, () => []).add(log);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return days.map((day) => _DayGroup(day, _entriesFor(byDay[day]!))).toList();
  }

  /// Walks a day's logs chronologically, tagging each with the status it earned
  /// given how much of the goal was already banked before it.
  List<_Entry> _entriesFor(List<HabbitLogModel> dayLogs) {
    final ordered = [...dayLogs]..sort((a, b) => a.date.compareTo(b.date));
    final goalBase = habbit.goal.baseValue;

    double banked = 0;
    bool alreadyDone = false;
    final entries = <_Entry>[];

    for (final log in ordered) {
      final goalMet = habbit.isBinary
          ? alreadyDone
          : (goalBase > 0 && banked >= goalBase);

      entries.add(_Entry(log, _statusFor(log, goalMet)));

      banked += log.measurement.baseValue;
      alreadyDone = alreadyDone || log.isCompleted;
    }
    return entries;
  }

  _LogStatus _statusFor(HabbitLogModel log, bool goalAlreadyMet) {
    if (goalAlreadyMet) return _LogStatus.extraCredit;
    if (log.isCompleted) return _LogStatus.completed;
    if (!habbit.isBinary && log.value > 0) return _LogStatus.partial;
    return _LogStatus.missed;
  }

  // ── Selection ──────────────────────────────────────────────────────────────
  void _enterSelection([HabbitLogModel? seed]) {
    setState(() {
      _selectionMode = true;
      if (seed != null) _selectedIds.add(seed.id);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggle(HabbitLogModel log) {
    setState(() {
      if (!_selectedIds.remove(log.id)) _selectedIds.add(log.id);
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _edit(HabbitLogModel log) async {
    final updated = await showModalBottomSheet<HabbitLogModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditLogSheet(habbit: habbit, log: log),
    );
    if (updated != null) widget.onEdit(updated);
  }

  Future<void> _confirmDelete(List<HabbitLogModel> logs) async {
    if (logs.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          logs.length == 1 ? 'Delete this log?' : 'Delete ${logs.length} logs?',
          style: GoogleFonts.ubuntu(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.grey7,
          ),
        ),
        content: Text(
          'This cannot be undone. Your streak and stats will be recalculated.',
          style: GoogleFonts.ubuntu(fontSize: 13, color: AppColors.grey5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w700,
                color: AppColors.grey5,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.ubuntu(
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    widget.onDelete(logs);
    if (_selectionMode) _exitSelection();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final groups = _groups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(groups),
        const SizedBox(height: 10),
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          )
        else if (groups.isEmpty)
          _buildEmptyState()
        else
          for (final group in groups) ...[
            _buildDayCard(group),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildHeader(List<_DayGroup> groups) {
    if (_selectionMode) {
      return Row(
        children: [
          Text(
            _selectedIds.isEmpty
                ? 'Select logs'
                : '${_selectedIds.length} selected',
            style: GoogleFonts.ubuntu(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.grey7,
            ),
          ),
          const Spacer(),
          if (_selectedIds.isNotEmpty)
            _headerAction(
              'Delete',
              AppColors.error,
              () => _confirmDelete(
                widget.habbitLogs
                    .where((l) => _selectedIds.contains(l.id))
                    .toList(),
              ),
            ),
          _headerAction('Cancel', AppColors.grey5, _exitSelection),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'Detailed Logs',
          style: GoogleFonts.ubuntu(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.grey7,
          ),
        ),
        const SizedBox(width: 8),
        if (!widget.isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.habbitLogs.length}',
              style: GoogleFonts.ubuntu(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        const Spacer(),
        if (groups.isNotEmpty)
          _headerAction(
            'Select Multiple',
            AppColors.primaryDeep,
            () => _enterSelection(),
          ),
      ],
    );
  }

  Widget _headerAction(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.ubuntu(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(_DayGroup group) {
    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: Column(
        children: [
          _buildDayHeader(group),
          for (int i = 0; i < group.entries.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.grey3),
            _buildEntry(group.entries[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildDayHeader(_DayGroup group) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.grey2,
        border: Border(bottom: BorderSide(color: AppColors.grey3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _dayLabel(group.day).toUpperCase(),
              style: GoogleFonts.ubuntu(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.grey5,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (!habbit.isBinary)
            Text(
              '${_dayTotal(group).format()} / ${habbit.goal.format()}',
              style: GoogleFonts.ubuntu(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.grey5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntry(_Entry entry) {
    final log = entry.log;
    final selected = _selectedIds.contains(log.id);

    // Decoration sits on an [Ink] so tap ripples paint above it, and the left
    // accent bar is a border so it always spans the full entry height.
    return Ink(
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        border: Border(
          left: BorderSide(
            width: 4,
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
      child: InkWell(
        onTap: _selectionMode ? () => _toggle(log) : null,
        onLongPress: _selectionMode ? null : () => _enterSelection(log),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _timeLabel(log.date),
                          style: GoogleFonts.ubuntu(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey5,
                          ),
                        ),
                        const Spacer(),
                        _StatusChip(status: entry.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _valueLabel(log),
                      style: GoogleFonts.ubuntu(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.grey7,
                      ),
                    ),
                    if (log.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 15,
                            color: AppColors.grey4,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              log.note,
                              style: GoogleFonts.ubuntu(
                                fontSize: 12.5,
                                height: 1.4,
                                color: AppColors.grey5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (!_selectionMode)
                      Row(
                        children: [
                          _iconAction(
                            Icons.edit_outlined,
                            'Edit log',
                            () => _edit(log),
                          ),
                          _iconAction(
                            Icons.copy_rounded,
                            'Log again now',
                            () => widget.onDuplicate(log),
                          ),
                          _iconAction(
                            Icons.delete_outline_rounded,
                            'Delete log',
                            () => _confirmDelete([log]),
                            color: AppColors.error,
                          ),
                        ],
                      )
                    else
                      const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_selectionMode) ...[
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.grey4,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconAction(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color ?? AppColors.grey5),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.grey2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grey3),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: AppColors.grey4),
          const SizedBox(height: 8),
          Text(
            'No logs yet',
            style: GoogleFonts.ubuntu(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.grey5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start logging to see your history here',
            style: GoogleFonts.ubuntu(fontSize: 13, color: AppColors.grey4),
          ),
        ],
      ),
    );
  }

  // ── Labels ─────────────────────────────────────────────────────────────────
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// "Today, October 26" / "Yesterday, October 25" / "Tuesday, October 24".
  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;

    final String prefix;
    if (diff == 0) {
      prefix = 'Today';
    } else if (diff == 1) {
      prefix = 'Yesterday';
    } else {
      prefix = _weekdays[day.weekday - 1];
    }

    final date = '${_months[day.month - 1]} ${day.day}';
    return day.year == now.year
        ? '$prefix, $date'
        : '$prefix, $date ${day.year}';
  }

  String _timeLabel(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute '
        '${date.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "20 minutes" / "1 kilometer" / "Marked done".
  String _valueLabel(HabbitLogModel log) {
    if (habbit.isBinary) return log.isCompleted ? 'Marked done' : 'Not done';

    final measurement = log.measurement;
    final value = measurement.value;
    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    final name = measurement.unit.name.toLowerCase();
    final plural = value == 1 || name.endsWith('s') ? name : '${name}s';
    return '$formatted $plural';
  }

  /// The day's logged total, expressed in the habit's own unit.
  Measurement _dayTotal(_DayGroup group) {
    final base = group.entries.fold<double>(
      0,
      (sum, e) => sum + e.log.measurement.baseValue,
    );
    return Measurement(habbit.unit.fromBase(base), habbit.unit);
  }
}

/// The small pill that labels a log's status within its day.
class _StatusChip extends StatelessWidget {
  final _LogStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _LogStatus.completed => ('Completed', AppColors.primaryDeep),
      _LogStatus.extraCredit => ('Extra Credit', AppColors.success),
      _LogStatus.partial => ('Partial', AppColors.warning),
      _LogStatus.missed => ('Missed', AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.ubuntu(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Bottom sheet for editing a single log's amount / completion and note.
/// Pops with the edited [HabbitLogModel], or `null` if the user backs out.
class _EditLogSheet extends StatefulWidget {
  final HabbitModel habbit;
  final HabbitLogModel log;

  const _EditLogSheet({required this.habbit, required this.log});

  @override
  State<_EditLogSheet> createState() => _EditLogSheetState();
}

class _EditLogSheetState extends State<_EditLogSheet> {
  late final TextEditingController _valueController;
  late final TextEditingController _noteController;
  late bool _completed;
  String? _error;

  HabbitModel get habbit => widget.habbit;
  HabbitLogModel get log => widget.log;

  @override
  void initState() {
    super.initState();
    final value = log.value;
    _valueController = TextEditingController(
      text: value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toString(),
    );
    _noteController = TextEditingController(text: log.note);
    _completed = log.isCompleted;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (habbit.isBinary) {
      Navigator.pop(
        context,
        log.copyWith(
          isCompleted: _completed,
          value: _completed ? 1 : 0,
          note: _noteController.text.trim(),
        ),
      );
      return;
    }

    final value = double.tryParse(_valueController.text.trim()) ?? -1;
    if (value < 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    Navigator.pop(
      context,
      log.copyWith(
        value: value,
        isCompleted:
            Measurement(value, log.measurement.unit).baseValue >=
            habbit.goal.baseValue,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Log',
              style: GoogleFonts.ubuntu(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.grey7,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              habbit.name,
              style: GoogleFonts.ubuntu(fontSize: 13, color: AppColors.grey5),
            ),
            const SizedBox(height: 16),
            if (habbit.isBinary)
              _buildCompletedSwitch()
            else
              _buildValueField(),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: GoogleFonts.ubuntu(fontSize: 14, color: AppColors.grey7),
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.grey2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.ubuntu(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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
                      child: Center(
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.ubuntu(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueField() {
    final unit = log.measurement.unit;

    return TextField(
      controller: _valueController,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.ubuntu(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.grey7,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.grey2,
        labelText: 'Amount',
        labelStyle: GoogleFonts.ubuntu(color: AppColors.grey5),
        errorText: _error,
        suffixText: unit.symbol.isEmpty ? null : unit.symbol,
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
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
    );
  }

  Widget _buildCompletedSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Completed',
              style: GoogleFonts.ubuntu(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey7,
              ),
            ),
          ),
          Switch(
            value: _completed,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            onChanged: (value) => setState(() => _completed = value),
          ),
        ],
      ),
    );
  }
}
