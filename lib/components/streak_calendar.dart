import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/models/habbit_log_model.dart';

class StreakCalendar extends StatelessWidget {
  final List<HabbitLogModel> logs;

  const StreakCalendar({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(today.year, today.month, 1);
    final lastDayOfMonth = DateTime(today.year, today.month + 1, 0);

    // Build a lookup: date-string → isCompleted
    final Map<String, bool?> logMap = {};
    for (final log in logs) {
      final key = _dateKey(log.date);
      if (logMap[key] == null) {
        logMap[key] = log.isCompleted;
      } else if (log.isCompleted) {
        logMap[key] = true;
      }
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Weekday of the 1st of the month (Monday = 1, Sunday = 7)
    final int startWeekday = firstDayOfMonth.weekday;
    // Prefix empty slots before the 1st day
    final int prefixEmptySlots = startWeekday - 1;
    final int totalDays = lastDayOfMonth.day;
    final int totalGridItems = prefixEmptySlots + totalDays;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Weekday Headers
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels.map((label) {
              return SizedBox(
                width: 32,
                child: Text(
                  label,
                  style: GoogleFonts.ubuntu(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey5,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        // Days Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemCount: totalGridItems,
          itemBuilder: (context, index) {
            if (index < prefixEmptySlots) {
              return const SizedBox.shrink();
            }

            final int dayNum = index - prefixEmptySlots + 1;
            final date = DateTime(today.year, today.month, dayNum);
            final key = _dateKey(date);
            final status =
                logMap[key]; // null = no log, true = completed, false = missed
            final isToday =
                dayNum == today.day &&
                date.month == today.month &&
                date.year == today.year;
            final isFuture = date.isAfter(today);

            Color bgColor = Colors.transparent;
            Color textColor = AppColors.grey7;
            BoxBorder? border;
            List<BoxShadow>? boxShadow;

            if (isFuture) {
              textColor = AppColors.grey4;
            } else if (status == true) {
              bgColor = AppColors.success;
              textColor = Colors.white;
              boxShadow = [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ];
            } else if (status == false) {
              bgColor = AppColors.error;
              textColor = Colors.white;
              boxShadow = [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ];
            } else {
              // Past or today without completion
              if (isToday) {
                border = Border.all(color: AppColors.primary, width: 2);
                textColor = AppColors.primary;
              } else {
                bgColor = AppColors.grey2;
                textColor = AppColors.grey5;
              }
            }

            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                border: border,
                boxShadow: boxShadow,
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: GoogleFonts.ubuntu(
                      fontSize: 12,
                      fontWeight: (isToday || status != null)
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                  if (status == true)
                    Positioned(
                      bottom: 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
