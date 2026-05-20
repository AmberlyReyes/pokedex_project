import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsRadarChart extends StatelessWidget {
  //lista de nombre de estadisticas y sus valores
  final Map<String, int> data;
  // valor maximo para la escala del radar
  final int maxValue;

  const StatsRadarChart({
    super.key,
    required this.data,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final stats = data.entries.toList();
    final values = stats.map((e) => e.value.toDouble()).toList();
    final labels = stats.map((e) => e.key).toList();

    return RadarChartWidget(
      values: values,
      labels: labels,
      maxValue: maxValue.toDouble(),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double maxValue;

  const RadarChartWidget({
    super.key,
    required this.values,
    required this.labels,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: values
                .map((value) => RadarEntry(value: value))
                .toList(),
            borderColor: Theme.of(context).colorScheme.primary,
            fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            borderWidth: 2,
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1,
        ),
        gridBorderData: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
        titlePositionPercentageOffset: 0.15,
        getTitle: (index, angle) {
          return RadarChartTitle(
            // nombre de la estadisticas
            text: _formatStatName(labels[index]),
            angle: angle,
            positionPercentageOffset: 0.15,
          );
        },
      ),
    );
  }

  String _formatStatName(String statName) {
    switch (statName.toLowerCase()) {
      case 'hp':
        return 'HP';
      case 'attack':
        return 'ATK';
      case 'defense':
        return 'DEF';
      case 'special-attack':
        return 'SpA';
      case 'special-defense':
        return 'SpD';
      case 'speed':
        return 'SPE';
      default:
        return statName.toUpperCase();
    }
  }
}