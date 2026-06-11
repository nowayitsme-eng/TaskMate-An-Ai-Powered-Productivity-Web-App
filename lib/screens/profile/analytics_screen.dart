import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final ActivityService _activityService = ActivityService();

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().user?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: userId == null 
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, int>>(
              stream: _activityService.streamSubjectMinutes(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final subjectMinutes = snapshot.data ?? {};
                
                if (subjectMinutes.isEmpty) {
                  return _buildEmptyState();
                }
                
                return _buildContent(subjectMinutes);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 64)),
            SizedBox(height: 24),
            Text('No Analytics Yet',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              'Start a Pomodoro session while a task is focused to begin tracking your study time by subject.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, int> subjectMinutes) {
    final total = subjectMinutes.values.fold(0, (a, b) => a + b);
    final sortedEntries = subjectMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Generate colors from a nice palette
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.accent,
      const Color(0xFFEC4899),
      const Color(0xFF3B82F6),
      const Color(0xFF14B8A6),
      const Color(0xFFF97316),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total summary card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.primaryDark.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 48)),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Study Time', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    Text(
                      _formatMinutes(total),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${subjectMinutes.length} subject${subjectMinutes.length != 1 ? 's' : ''} tracked',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Pie Chart
          const Text('Time Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          SizedBox(
            height: 260,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 50,
                      sections: sortedEntries.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        final pct = e.value / total * 100;
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: colors[idx % colors.length],
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          radius: 80,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedEntries.asMap().entries.take(7).map((entry) {
                      final idx = entry.key;
                      final e = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[idx % colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Bar Chart breakdown
          const Text('Hours by Subject',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (sortedEntries.first.value / 60).ceil().toDouble() + 1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sortedEntries.length) return const SizedBox();
                        final label = sortedEntries[idx].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label.length > 6 ? '${label.substring(0, 6)}..' : label,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.textPrimary.withValues(alpha: 0.05), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: e.value / 60,
                        color: colors[idx % colors.length],
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}
