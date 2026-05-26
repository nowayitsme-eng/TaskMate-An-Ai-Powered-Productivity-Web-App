import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// A GitHub-style 52-week activity heatmap.
/// [activityMap] maps `yyyy-MM-dd` strings → combined activity score.
class ActivityHeatmap extends StatelessWidget {
  final Map<String, int> activityMap;

  const ActivityHeatmap({super.key, required this.activityMap});

  static const int _weeks = 52;
  static const int _days = 7; // rows

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _cellColor(int score) {
    if (score <= 0) return const Color(0xFF1E293B);
    if (score < 10) return const Color(0xFF4C1D95);
    if (score < 25) return const Color(0xFF6D28D9);
    if (score < 50) return const Color(0xFF8B5CF6);
    return const Color(0xFFC4B5FD);
  }

  @override
  Widget build(BuildContext context) {
    // Compute the start date: go back 52 full weeks from the start of this week
    final now = DateTime.now();
    final todayWeekday = now.weekday % 7; // Sunday = 0
    final startOfThisWeek = now.subtract(Duration(days: todayWeekday));
    final startDate = startOfThisWeek.subtract(const Duration(days: (_weeks - 1) * 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.grayLight),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_weeks, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Column(
                  children: List.generate(_days, (dayIndex) {
                    final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                    final key = _dateKey(date);
                    final score = activityMap[key] ?? 0;
                    final isToday = key == _dateKey(now);
                    final isFuture = date.isAfter(now);

                    return Tooltip(
                      message: isFuture
                          ? ''
                          : '$key${score > 0 ? ' — score: $score' : ' — no activity'}',
                      child: Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: isFuture
                              ? Colors.transparent
                              : _cellColor(score),
                          borderRadius: BorderRadius.circular(3),
                          border: isToday
                              ? Border.all(color: AppTheme.primaryLight, width: 1.5)
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Less', style: TextStyle(fontSize: 10, color: AppTheme.gray)),
            const SizedBox(width: 4),
            ...[0, 10, 25, 50, 80].map((score) => Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _cellColor(score),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
            const SizedBox(width: 4),
            const Text('More', style: TextStyle(fontSize: 10, color: AppTheme.gray)),
          ],
        ),
      ],
    );
  }
}
