import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_theme.dart';
import '../providers/history_provider.dart';
import 'daily_detail_page.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _selectedPeriod = 'weekly'; // 'weekly' or 'monthly'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() {
      _selectedPeriod = period;
    });
    ref.read(historyProvider.notifier).fetchHistory(period);
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Period Selector Pill Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onPeriodChanged('weekly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'weekly' ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Mingguan',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: _selectedPeriod == 'weekly' ? FontWeight.bold : FontWeight.w500,
                              color: _selectedPeriod == 'weekly' ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onPeriodChanged('monthly'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedPeriod == 'monthly' ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Bulanan',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: _selectedPeriod == 'monthly' ? FontWeight.bold : FontWeight.w500,
                              color: _selectedPeriod == 'monthly' ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (historyState.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                  ),
                  child: Text(
                    historyState.errorMessage!,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : historyState.items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod);
                          },
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            children: [
                              // Chart Card 1: Langkah (Steps)
                              _buildMetricChartCard(
                                title: 'LANGKAH',
                                averageLabel: 'rata-rata',
                                averageValue: _calculateAverageSteps(historyState.items).toString(),
                                suffix: 'langkah/hari',
                                items: historyState.items,
                                valueSelector: (it) => it.totalSteps.toDouble(),
                                maxSelector: (items) => _getMaxSteps(items).toDouble(),
                              ),
                              const SizedBox(height: 16),

                              // Chart Card 2: Jarak (Distance)
                              _buildMetricChartCard(
                                title: 'JARAK TEMPUH',
                                averageLabel: 'total jarak',
                                averageValue: (_calculateTotalDistance(historyState.items) / 1000.0).toStringAsFixed(1),
                                suffix: 'km',
                                items: historyState.items,
                                valueSelector: (it) => it.totalDistanceMeters.toDouble(),
                                maxSelector: (items) => _getMaxDistance(items).toDouble(),
                              ),
                              const SizedBox(height: 24),

                              // Daily List Title
                              Text(
                                'RINGKASAN HARIAN',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.08 * 11,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Daily List
                              ...historyState.items.reversed.map((item) => _buildDailyListItem(context, item)),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Riwayat Aktivitas',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Mulailah pelacakan atau refresh data.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChartCard({
    required String title,
    required String averageLabel,
    required String averageValue,
    required String suffix,
    required List<HistoryItem> items,
    required double Function(HistoryItem) valueSelector,
    required double Function(List<HistoryItem>) maxSelector,
  }) {
    final maxVal = maxSelector(items);
    final displayMaxVal = maxVal == 0 ? 100.0 : maxVal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                averageValue,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 6),
              Text(
                suffix,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                averageLabel,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom horizontal bar-row charts
          SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((it) {
                final double val = valueSelector(it);
                final double height = (val / displayMaxVal * 80).clamp(4.0, 80.0);
                final isToday = it.date == DateTime.now().toIso8601String().split('T')[0];

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    height: height,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.secondary : AppColors.secondaryPale,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyListItem(BuildContext context, HistoryItem item) {
    // Format tanggal
    final DateTime dt = DateTime.parse(item.date);
    final List<String> weekdays = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
    final weekdayLabel = weekdays[dt.weekday % 7];
    final dayNumber = dt.day.toString();

    // Jenis Aktivitas Dot Color
    Color activityColor = AppColors.textMuted;
    if (item.dominantActivityType == 'walking') {
      activityColor = AppColors.secondary;
    } else if (item.dominantActivityType == 'running') {
      activityColor = AppColors.warning;
    }

    final double displayDistanceKm = item.totalDistanceMeters / 1000.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DailyDetailPage(date: item.date)),
        );
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              // Kolom Tanggal
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weekdayLabel,
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                    Text(
                      dayNumber,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Horizontal fill progress bar
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (item.totalSteps / 10000.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary.withOpacity(0.6)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Steps & Distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.totalSteps.toString(),
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${displayDistanceKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Activity Type Dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: activityColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _calculateAverageSteps(List<HistoryItem> items) {
    if (items.isEmpty) return 0;
    final total = items.fold(0, (sum, item) => sum + item.totalSteps);
    return (total / items.length).round();
  }

  int _calculateTotalDistance(List<HistoryItem> items) {
    return items.fold(0, (sum, item) => sum + item.totalDistanceMeters);
  }

  int _getMaxSteps(List<HistoryItem> items) {
    if (items.isEmpty) return 10000;
    return items.map((it) => it.totalSteps).reduce((a, b) => a > b ? a : b);
  }

  int _getMaxDistance(List<HistoryItem> items) {
    if (items.isEmpty) return 5000;
    return items.map((it) => it.totalDistanceMeters).reduce((a, b) => a > b ? a : b);
  }
}
