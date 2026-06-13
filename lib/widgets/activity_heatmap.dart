import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// A GitHub-style 365-day activity heatmap.
/// [activityMap] maps `yyyy-MM-dd` strings → combined activity score.
/// Scrolls so that *today* is always visible at the right edge by default.
class ActivityHeatmap extends StatefulWidget {
  final Map<String, int> activityMap;

  const ActivityHeatmap({super.key, required this.activityMap});

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  late final ScrollController _scrollController;

  static const double _cellSize = 13.0;
  static const double _cellGap = 3.0;
  static const double _unit = _cellSize + _cellGap; // 16.0 per cell slot

  // 52 full weeks + partial current week = 53 columns max
  static const int _totalWeeks = 53;
  // 7 days per week (Sun → Sat)
  static const int _daysPerWeek = 7;

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Color _cellColor(int score) {
    if (score <= 0) return const Color(0xFFEBEDF0);
    if (score <= 10) return const Color(0xFF9BE9A8); // gh-green-1
    if (score <= 25) return const Color(0xFF40C463); // gh-green-2
    if (score <= 50) return const Color(0xFF30A14E); // gh-green-3
    return const Color(0xFF216E39); // gh-green-4
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Start from Sunday of the week that is 52 weeks before the current week
    // so that today falls in the last (rightmost) column.
    final todayWeekday = today.weekday % 7; // 0=Sun, 1=Mon, ..., 6=Sat
    final startOfCurrentWeek = today.subtract(Duration(days: todayWeekday));
    final startDate = startOfCurrentWeek.subtract(
      const Duration(days: (_totalWeeks - 1) * 7),
    );

    // Build month label positions (one per new month boundary)
    final List<_MonthLabel> monthLabels = [];
    {
      String? lastMonth;
      for (int col = 0; col < _totalWeeks; col++) {
        final d = startDate.add(Duration(days: col * 7));
        final m = DateFormat('MMM').format(d);
        if (m != lastMonth) {
          monthLabels.add(_MonthLabel(col: col, label: m));
          lastMonth = m;
        }
      }
    }

    // Width for day-of-week labels column
    const double dayLabelWidth = 28.0;
    // Total width of the cell grid — each cell is _unit wide; last column
    // still contributes half a gap on the right, so we don't subtract it.
    final double gridWidth = _totalWeeks * _unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable month-labels + grid section
        ClipRect(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Month labels row ──────────────────────────────────────
                SizedBox(
                  height: 18,
                  width: dayLabelWidth + gridWidth,
                  child: Stack(
                    children: monthLabels.map((ml) {
                      return Positioned(
                        left: dayLabelWidth + ml.col * _unit,
                        top: 0,
                        child: Text(
                          ml.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
                // ── Day labels + cell grid ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Day-of-week labels (GitHub style: Mon, Wed, Fri)
                    SizedBox(
                      width: dayLabelWidth,
                      child: Column(
                        children: List.generate(_daysPerWeek, (rowIndex) {
                          const labels = [
                            'Sun',
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                          ];
                          return SizedBox(
                            height: _unit,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                rowIndex == 1 || rowIndex == 3 || rowIndex == 5
                                    ? labels[rowIndex]
                                    : '',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Cell grid: 53 columns × 7 rows
                    SizedBox(
                      width: gridWidth,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_totalWeeks, (col) {
                          return Column(
                            children: List.generate(_daysPerWeek, (row) {
                              final date = startDate.add(
                                Duration(days: col * 7 + row),
                              );
                              final isFuture = date.isAfter(today);
                              final key = _dateKey(date);
                              final score = isFuture
                                  ? 0
                                  : (widget.activityMap[key] ?? 0);
                              final isToday = date == today;

                              return Tooltip(
                                message: isFuture
                                    ? ''
                                    : '${DateFormat('MMM d, yyyy').format(date)}'
                                          '${score > 0 ? ' — $score pts' : ' — no activity'}',
                                child: Container(
                                  width: _cellSize,
                                  height: _cellSize,
                                  margin: const EdgeInsets.all(_cellGap / 2),
                                  decoration: BoxDecoration(
                                    color: isFuture
                                        ? Colors.transparent
                                        : _cellColor(score),
                                    borderRadius: BorderRadius.circular(3),
                                    border: isToday
                                        ? Border.all(
                                            color: AppTheme.primary,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── Legend ─────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Less',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(width: 4),
            ...[0, 10, 25, 50, 80].map(
              (score) => Container(
                width: _cellSize,
                height: _cellSize,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _cellColor(score),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'More',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _MonthLabel {
  final int col;
  final String label;
  const _MonthLabel({required this.col, required this.label});
}
