import 'package:flutter/material.dart';
import 'package:footheroes/theme/app_theme.dart';

/// Standings table widget for tournament bracket tab.
class StandingsTableWidget extends StatelessWidget {
  final List<dynamic> standings;

  const StandingsTableWidget({super.key, required this.standings});

  @override
  Widget build(BuildContext context) {
    if (standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 48, color: AppTheme.gold),
            const SizedBox(height: 16),
            Text('No standings available yet',
                style: AppTheme.bodyReg, textAlign: TextAlign.center),
            Text('Standings will appear once matches start',
                style: AppTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(),
          ...standings.asMap().entries.map((e) => _buildRow(e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _headerCell('#', flex: 1),
          _headerCell('TEAM', flex: 3),
          _headerCell('P', flex: 1),
          _headerCell('W', flex: 1),
          _headerCell('D', flex: 1),
          _headerCell('L', flex: 1),
          _headerCell('GD', flex: 1),
          _headerCell('PTS', flex: 1),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.gold,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildRow(int rank, dynamic team) {
    final name = team['name']?.toString() ?? 'Team';
    final played = team['played'] ?? 0;
    final won = team['won'] ?? 0;
    final drawn = team['drawn'] ?? 0;
    final lost = team['lost'] ?? 0;
    final gd = team['goalDifference'] ?? 0;
    final pts = team['points'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$rank',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? AppTheme.navy : AppTheme.gold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(name,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.parchment,
                )),
          ),
          Expanded(flex: 1, child: _statCell('$played')),
          Expanded(flex: 1, child: _statCell('$won')),
          Expanded(flex: 1, child: _statCell('$drawn')),
          Expanded(flex: 1, child: _statCell('$lost')),
          Expanded(flex: 1, child: _statCell('${gd > 0 ? '+' : ''}$gd')),
          Expanded(flex: 1, child: _statCell('$pts', highlight: true)),
        ],
      ),
    );
  }

  Widget _statCell(String text, {bool highlight = false}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: highlight ? AppTheme.navy : AppTheme.parchment,
      ),
      textAlign: TextAlign.center,
    );
  }
}