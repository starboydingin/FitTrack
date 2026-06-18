import 'dart:ui';
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
  String _selectedPeriod = 'weekly';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod == period) return;
    setState(() => _selectedPeriod = period);
    ref.read(historyProvider.notifier).fetchHistory(period);
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: DSColors.brandTealDeep,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.page, 16, DSSpacing.page, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Riwayat Aktivitas', style: DSText.screenTitle()),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: DSColors.onDarkMuted),
                    onPressed: () => ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DSRadius.pill),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                      border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        _buildPeriodTab('weekly', 'Mingguan'),
                        _buildPeriodTab('monthly', 'Bulanan'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (historyState.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DSColors.errorDark.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(DSRadius.control),
                    border: Border.all(color: DSColors.errorDark.withOpacity(0.3)),
                  ),
                  child: Text(historyState.errorMessage!,
                      style: GoogleFonts.inter(fontSize: 13, color: DSColors.errorDark, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: historyState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: DSColors.primaryDark))
                  : historyState.items.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async => ref.read(historyProvider.notifier).fetchHistory(_selectedPeriod),
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
                            children: [
                              _buildMetricChartCard(
                                title: 'LANGKAH', averageLabel: 'rata-rata',
                                averageValue: _calculateAverageSteps(historyState.items).toString(),
                                suffix: '/hari', items: historyState.items,
                                valueSelector: (it) => it.totalSteps.toDouble(),
                                maxSelector: (items) => _getMaxSteps(items).toDouble(),
                              ),
                              const SizedBox(height: 16),
                              _buildMetricChartCard(
                                title: 'JARAK TEMPUH', averageLabel: 'total jarak',
                                averageValue: (_calculateTotalDistance(historyState.items) / 1000.0).toStringAsFixed(1),
                                suffix: 'km', items: historyState.items,
                                valueSelector: (it) => it.totalDistanceMeters.toDouble(),
                                maxSelector: (items) => _getMaxDistance(items).toDouble(),
                              ),
                              const SizedBox(height: 24),
                              Text('RINGKASAN HARIAN', style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
                              const SizedBox(height: 12),
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

  Widget _buildPeriodTab(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? DSColors.primaryDark.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(DSRadius.pill),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? DSColors.onDark : DSColors.onDarkMuted)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(height: 300, alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.history_rounded, size: 64, color: DSColors.onDarkMuted),
          const SizedBox(height: 16),
          Text('Belum Ada Riwayat Aktivitas',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, color: DSColors.onDark)),
          const SizedBox(height: 6),
          Text('Mulailah pelacakan atau refresh data.', style: DSText.caption(color: DSColors.onDarkMuted)),
        ]),
      ),
    );
  }

  Widget _buildMetricChartCard({
    required String title, required String averageLabel, required String averageValue,
    required String suffix, required List<HistoryItem> items,
    required double Function(HistoryItem) valueSelector,
    required double Function(List<HistoryItem>) maxSelector,
  }) {
    final maxVal = maxSelector(items);
    final displayMaxVal = maxVal == 0 ? 100.0 : maxVal;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: DSText.sectionLabel(color: DSColors.onDarkMuted)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(averageValue,
              style: GoogleFonts.jetBrainsMono(fontSize: 28, fontWeight: FontWeight.w600, color: DSColors.onDark)),
          const SizedBox(width: 6),
          Text(suffix, style: DSText.caption(color: DSColors.onDarkMuted)),
          const Spacer(),
          Text(averageLabel, style: DSText.caption(color: DSColors.onDarkMuted)),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 80,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
            children: items.map((it) {
              final double val = valueSelector(it);
              final double height = (val / displayMaxVal * 80).clamp(4.0, 80.0);
              final isToday = it.date == DateTime.now().toIso8601String().split('T')[0];
              return Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2.0), height: height,
                  decoration: BoxDecoration(
                    color: isToday ? DSColors.primaryDark : Colors.white.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  )));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildDailyListItem(BuildContext context, HistoryItem item) {
    final DateTime dt = DateTime.parse(item.date);
    final List<String> weekdays = ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'];
    final weekdayLabel = weekdays[dt.weekday % 7];
    final dayNumber = dt.day.toString();
    Color activityColor = DSColors.onDarkMuted;
    if (item.dominantActivityType == 'walking') activityColor = DSColors.primaryDark;
    else if (item.dominantActivityType == 'running') activityColor = DSColors.accentOrange;
    final double displayDistanceKm = item.totalDistanceMeters / 1000.0;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailyDetailPage(date: item.date))),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06), width: 0.5))),
        child: Row(children: [
          SizedBox(width: 50, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(weekdayLabel, style: DSText.chipLabel(color: DSColors.onDarkMuted)),
            Text(dayNumber, style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.w600, color: DSColors.onDark)),
          ])),
          const SizedBox(width: 8),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(DSRadius.progressBar),
            child: LinearProgressIndicator(
              value: (item.totalSteps / 10000.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(DSColors.primaryDark.withOpacity(0.6)),
              minHeight: 6,
            ),
          )),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.totalSteps.toString(),
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: DSColors.onDark)),
            Text('${displayDistanceKm.toStringAsFixed(1)} km', style: DSText.caption(color: DSColors.onDarkMuted)),
          ]),
          const SizedBox(width: 16),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: activityColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: DSColors.onDarkMuted, size: 20),
        ]),
      ),
    );
  }

  int _calculateAverageSteps(List<HistoryItem> items) {
    if (items.isEmpty) return 0;
    return (items.fold(0, (sum, item) => sum + item.totalSteps) / items.length).round();
  }

  int _calculateTotalDistance(List<HistoryItem> items) => items.fold(0, (sum, item) => sum + item.totalDistanceMeters);

  int _getMaxSteps(List<HistoryItem> items) {
    if (items.isEmpty) return 10000;
    return items.map((it) => it.totalSteps).reduce((a, b) => a > b ? a : b);
  }

  int _getMaxDistance(List<HistoryItem> items) {
    if (items.isEmpty) return 5000;
    return items.map((it) => it.totalDistanceMeters).reduce((a, b) => a > b ? a : b);
  }
}
