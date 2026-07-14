import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/models/habbit_log_model.dart';
import 'package:habbit/models/habbit_model.dart';

class HabbitHistoryList extends StatelessWidget {
  final HabbitModel habbit;

  const HabbitHistoryList({super.key, required this.habbit});

  // Group logs by month (e.g. "July 2026")
  Map<String, List<HabbitLogModel>> _groupByMonth(List<HabbitLogModel> logs) {
    final sorted = [...logs]..sort((a, b) => b.date.compareTo(a.date));
    final Map<String, List<HabbitLogModel>> grouped = {};
    for (final log in sorted) {
      final key = _monthLabel(log.date);
      grouped.putIfAbsent(key, () => []).add(log);
    }
    return grouped;
  }

  String _monthLabel(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _dayLabel(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${days[date.weekday - 1]}';
  }

  String _logTitle(HabbitLogModel log) {
    if (habbit.type == 'Binary') return 'Completed';
    if (habbit.type == 'Count') {
      return '${log.value} / ${habbit.goalThreshold} times';
    }
    return '${log.value} / ${habbit.goalThreshold} mins';
  }

  @override
  Widget build(BuildContext context) {
    final logs = habbit.logs;

    if (logs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppColors.grey2,
          borderRadius: BorderRadius.circular(12),
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

    final grouped = _groupByMonth(logs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.ubuntu(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey5,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(color: AppColors.grey3, thickness: 1),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.value.length} logs',
                      style: GoogleFonts.ubuntu(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Log tiles
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey3),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entry.value.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: AppColors.grey3),
                itemBuilder: (context, index) {
                  final log = entry.value[index];
                  return _LogTile(
                    log: log,
                    dayLabel: _dayLabel(log.date),
                    logTitle: _logTitle(log),
                    isBinary: habbit.type == 'Binary',
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

class _LogTile extends StatelessWidget {
  final HabbitLogModel log;
  final String dayLabel;
  final String logTitle;
  final bool isBinary;

  const _LogTile({
    required this.log,
    required this.dayLabel,
    required this.logTitle,
    required this.isBinary,
  });

  @override
  Widget build(BuildContext context) {
    final completed = log.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date badge
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  dayLabel.split(',').first.trim(), // e.g. "14 Jul"
                  style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: completed ? AppColors.success : AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  dayLabel.contains(',')
                      ? dayLabel.split(',').last.trim()
                      : '', // e.g. "Mon"
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    color: completed
                        ? AppColors.success.withValues(alpha: 0.8)
                        : AppColors.error.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Log details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logTitle,
                  style: GoogleFonts.ubuntu(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey7,
                  ),
                ),
                if (log.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    log.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      color: AppColors.grey5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Completion indicator
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 24,
                color: completed ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 2),
              Text(
                completed ? 'Done' : 'Missed',
                style: GoogleFonts.ubuntu(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: completed ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
