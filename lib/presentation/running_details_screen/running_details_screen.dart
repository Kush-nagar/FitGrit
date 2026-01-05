/// Running Details Screen
/// Shows detailed statistics and charts for a specific run
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/strava_auth_service.dart';
import '../../services/strava_service.dart';
import '../../models/strava_activity.dart';

class RunningDetailsScreen extends StatefulWidget {
  const RunningDetailsScreen({super.key});

  @override
  State<RunningDetailsScreen> createState() => _RunningDetailsScreenState();
}

class _RunningDetailsScreenState extends State<RunningDetailsScreen> {
  final _authService = StravaAuthService();
  late final StravaService _stravaService;

  bool _isLoading = true;
  StravaActivityDetail? _activity;
  StravaActivityStreams? _streams;
  String? _errorMessage;

  int? _activityId;

  @override
  void initState() {
    super.initState();
    _stravaService = StravaService(_authService);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get activity ID from route arguments
    if (_activityId == null) {
      _activityId = ModalRoute.of(context)?.settings.arguments as int?;
      if (_activityId != null) {
        _loadActivityDetails();
      }
    }
  }

  Future<void> _loadActivityDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activity = await _stravaService.getActivityDetail(_activityId!);
      final streams = await _stravaService.getActivityStreams(_activityId!);

      setState(() {
        _activity = activity;
        _streams = streams;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading activity: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: _activity?.name ?? 'Run Details',
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView(theme);
    }

    if (_activity == null) {
      return _buildErrorView(theme, 'Activity not found');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(theme),
          const SizedBox(height: 16),
          _buildStatsGrid(theme),
          const SizedBox(height: 16),
          if (_streams != null) ...[
            _buildPaceChart(theme),
            const SizedBox(height: 16),
            _buildElevationChart(theme),
            const SizedBox(height: 16),
            if (_streams!.heartrate != null) ...[
              _buildHeartRateChart(theme),
              const SizedBox(height: 16),
            ],
            if (_streams!.cadence != null) ...[
              _buildCadenceChart(theme),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, [String? message]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? _errorMessage ?? 'An error occurred',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    final activity = _activity!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_run,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${activity.dateFormatted} • ${activity.timeFormatted}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activity.description != null &&
              activity.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              activity.description!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final activity = _activity!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Distance',
                '${activity.distanceKm} km',
                Icons.straighten,
                theme,
              ),
              _buildStatCard(
                'Duration',
                activity.durationFormatted,
                Icons.timer,
                theme,
              ),
              _buildStatCard(
                'Pace',
                '${activity.paceMinPerKm}/km',
                Icons.speed,
                theme,
              ),
              _buildStatCard(
                'Avg Speed',
                activity.averageSpeed != null
                    ? '${(activity.averageSpeed! * 3.6).toStringAsFixed(1)} km/h'
                    : 'N/A',
                Icons.trending_up,
                theme,
              ),
              if (activity.totalElevationGain != null)
                _buildStatCard(
                  'Elevation Gain',
                  '${activity.totalElevationGain!.toInt()} m',
                  Icons.terrain,
                  theme,
                ),
              if (activity.averageHeartrate != null)
                _buildStatCard(
                  'Avg Heart Rate',
                  '${activity.averageHeartrate!.toInt()} bpm',
                  Icons.favorite,
                  theme,
                ),
              if (activity.maxHeartrate != null)
                _buildStatCard(
                  'Max Heart Rate',
                  '${activity.maxHeartrate!.toInt()} bpm',
                  Icons.favorite,
                  theme,
                ),
              if (activity.averageCadence != null)
                _buildStatCard(
                  'Avg Cadence',
                  '${(activity.averageCadence! * 2).toInt()} spm',
                  Icons.directions_walk,
                  theme,
                ),
              if (activity.calories != null)
                _buildStatCard(
                  'Calories',
                  '${activity.calories} kcal',
                  Icons.local_fire_department,
                  theme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceChart(ThemeData theme) {
    if (_streams?.velocity == null) return const SizedBox.shrink();

    final paceData = _streams!.paceData;
    if (paceData == null || paceData.isEmpty) return const SizedBox.shrink();

    // Filter out invalid pace data (too slow or stopped)
    final validPaceData = paceData
        .asMap()
        .entries
        .where((entry) => entry.value > 0 && entry.value < 20)
        .toList();

    if (validPaceData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pace (min/km)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: validPaceData.length / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= validPaceData.length) {
                          return const Text('');
                        }
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: validPaceData
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationChart(ThemeData theme) {
    if (_streams?.altitude == null) return const SizedBox.shrink();

    final altitudeData = _streams!.altitude!.data;
    if (altitudeData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elevation (m)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: altitudeData.length / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= altitudeData.length) {
                          return const Text('');
                        }
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: altitudeData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(ThemeData theme) {
    if (_streams?.heartrate == null) return const SizedBox.shrink();

    final hrData = _streams!.heartrate!.data;
    if (hrData.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Heart Rate (bpm)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: hrData.length / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= hrData.length) {
                          return const Text('');
                        }
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: hrData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCadenceChart(ThemeData theme) {
    if (_streams?.cadence == null) return const SizedBox.shrink();

    final cadenceData = _streams!.cadence!.data;
    if (cadenceData.isEmpty) return const SizedBox.shrink();

    // Strava reports cadence as steps per second for one leg, multiply by 2 for SPM
    final spmData = cadenceData.map((c) => c * 2).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cadence (spm)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: spmData.length / 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= spmData.length) {
                          return const Text('');
                        }
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spmData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
