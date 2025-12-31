/// Strava activity data models
/// Models for activities, detailed activity data, and stream data
import 'package:intl/intl.dart';

/// Basic Strava activity summary
class StravaActivity {
  final int id;
  final String name;
  final String type;
  final DateTime startDate;
  final double distance; // meters
  final int movingTime; // seconds
  final int elapsedTime; // seconds
  final double? totalElevationGain; // meters
  final double? averageSpeed; // m/s
  final double? maxSpeed; // m/s
  final double? averageHeartrate;
  final double? maxHeartrate;
  final double? averageCadence;

  StravaActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.startDate,
    required this.distance,
    required this.movingTime,
    required this.elapsedTime,
    this.totalElevationGain,
    this.averageSpeed,
    this.maxSpeed,
    this.averageHeartrate,
    this.maxHeartrate,
    this.averageCadence,
  });

  factory StravaActivity.fromJson(Map<String, dynamic> json) {
    return StravaActivity(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Run',
      type: json['type'] as String? ?? 'Run',
      startDate: DateTime.parse(json['start_date'] as String),
      distance: (json['distance'] as num).toDouble(),
      movingTime: json['moving_time'] as int,
      elapsedTime: json['elapsed_time'] as int,
      totalElevationGain: (json['total_elevation_gain'] as num?)?.toDouble(),
      averageSpeed: (json['average_speed'] as num?)?.toDouble(),
      maxSpeed: (json['max_speed'] as num?)?.toDouble(),
      averageHeartrate: (json['average_heartrate'] as num?)?.toDouble(),
      maxHeartrate: (json['max_heartrate'] as num?)?.toDouble(),
      averageCadence: (json['average_cadence'] as num?)?.toDouble(),
    );
  }

  // Helper getters
  String get distanceKm => (distance / 1000).toStringAsFixed(2);
  String get distanceMiles => (distance / 1609.34).toStringAsFixed(2);

  String get durationFormatted {
    final hours = movingTime ~/ 3600;
    final minutes = (movingTime % 3600) ~/ 60;
    final seconds = movingTime % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  String get paceMinPerKm {
    if (distance == 0) return '--:--';
    final minPerKm = movingTime / 60 / (distance / 1000);
    final minutes = minPerKm.floor();
    final seconds = ((minPerKm - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get paceMinPerMile {
    if (distance == 0) return '--:--';
    final minPerMile = movingTime / 60 / (distance / 1609.34);
    final minutes = minPerMile.floor();
    final seconds = ((minPerMile - minutes) * 60).round();
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get dateFormatted => DateFormat('MMM d, yyyy').format(startDate);
  String get timeFormatted => DateFormat('h:mm a').format(startDate);
}

/// Detailed Strava activity with additional information
class StravaActivityDetail extends StravaActivity {
  final String? description;
  final List<double>? startLatLng;
  final List<double>? endLatLng;
  final double? elevationHigh;
  final double? elevationLow;
  final Map<String, dynamic>? splits;
  final int? calories;
  final bool hasHeartrate;

  StravaActivityDetail({
    required super.id,
    required super.name,
    required super.type,
    required super.startDate,
    required super.distance,
    required super.movingTime,
    required super.elapsedTime,
    super.totalElevationGain,
    super.averageSpeed,
    super.maxSpeed,
    super.averageHeartrate,
    super.maxHeartrate,
    super.averageCadence,
    this.description,
    this.startLatLng,
    this.endLatLng,
    this.elevationHigh,
    this.elevationLow,
    this.splits,
    this.calories,
    this.hasHeartrate = false,
  });

  factory StravaActivityDetail.fromJson(Map<String, dynamic> json) {
    return StravaActivityDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Run',
      type: json['type'] as String? ?? 'Run',
      startDate: DateTime.parse(json['start_date'] as String),
      distance: (json['distance'] as num).toDouble(),
      movingTime: json['moving_time'] as int,
      elapsedTime: json['elapsed_time'] as int,
      totalElevationGain: (json['total_elevation_gain'] as num?)?.toDouble(),
      averageSpeed: (json['average_speed'] as num?)?.toDouble(),
      maxSpeed: (json['max_speed'] as num?)?.toDouble(),
      averageHeartrate: (json['average_heartrate'] as num?)?.toDouble(),
      maxHeartrate: (json['max_heartrate'] as num?)?.toDouble(),
      averageCadence: (json['average_cadence'] as num?)?.toDouble(),
      description: json['description'] as String?,
      startLatLng: json['start_latlng'] != null
          ? List<double>.from(json['start_latlng'].map((x) => x.toDouble()))
          : null,
      endLatLng: json['end_latlng'] != null
          ? List<double>.from(json['end_latlng'].map((x) => x.toDouble()))
          : null,
      elevationHigh: (json['elev_high'] as num?)?.toDouble(),
      elevationLow: (json['elev_low'] as num?)?.toDouble(),
      splits: json['splits_metric'] as Map<String, dynamic>?,
      calories: (json['calories'] as num?)?.toInt(),
      hasHeartrate: json['has_heartrate'] as bool? ?? false,
    );
  }
}

/// Activity stream data (time series)
class StreamData {
  final List<int> data;
  final int originalSize;
  final String seriesType;

  StreamData({
    required this.data,
    required this.originalSize,
    required this.seriesType,
  });

  factory StreamData.fromJson(Map<String, dynamic> json) {
    return StreamData(
      data: List<int>.from(json['data']),
      originalSize: json['original_size'] as int,
      seriesType: json['series_type'] as String,
    );
  }
}

class DoubleStreamData {
  final List<double> data;
  final int originalSize;
  final String seriesType;

  DoubleStreamData({
    required this.data,
    required this.originalSize,
    required this.seriesType,
  });

  factory DoubleStreamData.fromJson(Map<String, dynamic> json) {
    return DoubleStreamData(
      data: List<double>.from(json['data'].map((x) => (x as num).toDouble())),
      originalSize: json['original_size'] as int,
      seriesType: json['series_type'] as String,
    );
  }
}

class LatLngStreamData {
  final List<List<double>> data;
  final int originalSize;
  final String seriesType;

  LatLngStreamData({
    required this.data,
    required this.originalSize,
    required this.seriesType,
  });

  factory LatLngStreamData.fromJson(Map<String, dynamic> json) {
    return LatLngStreamData(
      data: List<List<double>>.from(
        json['data'].map((x) => List<double>.from(x.map((y) => y.toDouble()))),
      ),
      originalSize: json['original_size'] as int,
      seriesType: json['series_type'] as String,
    );
  }
}

/// Collection of activity streams
class StravaActivityStreams {
  final StreamData? time;
  final DoubleStreamData? distance;
  final LatLngStreamData? latlng;
  final DoubleStreamData? altitude;
  final DoubleStreamData? velocity;
  final DoubleStreamData? heartrate;
  final DoubleStreamData? cadence;
  final DoubleStreamData? watts;
  final DoubleStreamData? temp;
  final DoubleStreamData? gradeSmooth;

  StravaActivityStreams({
    this.time,
    this.distance,
    this.latlng,
    this.altitude,
    this.velocity,
    this.heartrate,
    this.cadence,
    this.watts,
    this.temp,
    this.gradeSmooth,
  });

  factory StravaActivityStreams.fromJson(Map<String, dynamic> json) {
    return StravaActivityStreams(
      time: json['time'] != null ? StreamData.fromJson(json['time']) : null,
      distance: json['distance'] != null
          ? DoubleStreamData.fromJson(json['distance'])
          : null,
      latlng: json['latlng'] != null
          ? LatLngStreamData.fromJson(json['latlng'])
          : null,
      altitude: json['altitude'] != null
          ? DoubleStreamData.fromJson(json['altitude'])
          : null,
      velocity: json['velocity_smooth'] != null
          ? DoubleStreamData.fromJson(json['velocity_smooth'])
          : null,
      heartrate: json['heartrate'] != null
          ? DoubleStreamData.fromJson(json['heartrate'])
          : null,
      cadence: json['cadence'] != null
          ? DoubleStreamData.fromJson(json['cadence'])
          : null,
      watts: json['watts'] != null
          ? DoubleStreamData.fromJson(json['watts'])
          : null,
      temp:
          json['temp'] != null ? DoubleStreamData.fromJson(json['temp']) : null,
      gradeSmooth: json['grade_smooth'] != null
          ? DoubleStreamData.fromJson(json['grade_smooth'])
          : null,
    );
  }

  /// Get pace data (min/km) from velocity stream
  List<double>? get paceData {
    if (velocity == null) return null;
    return velocity!.data.map((v) {
      if (v == 0) return 0.0;
      return 1000 / (v * 60); // Convert m/s to min/km
    }).toList();
  }
}

/// Athlete statistics
class StravaAthleteStats {
  final RunTotals? recentRunTotals;
  final RunTotals? ytdRunTotals;
  final RunTotals? allRunTotals;

  StravaAthleteStats({
    this.recentRunTotals,
    this.ytdRunTotals,
    this.allRunTotals,
  });

  factory StravaAthleteStats.fromJson(Map<String, dynamic> json) {
    return StravaAthleteStats(
      recentRunTotals: json['recent_run_totals'] != null
          ? RunTotals.fromJson(json['recent_run_totals'])
          : null,
      ytdRunTotals: json['ytd_run_totals'] != null
          ? RunTotals.fromJson(json['ytd_run_totals'])
          : null,
      allRunTotals: json['all_run_totals'] != null
          ? RunTotals.fromJson(json['all_run_totals'])
          : null,
    );
  }
}

class RunTotals {
  final int count;
  final double distance; // meters
  final int movingTime; // seconds
  final int elapsedTime; // seconds
  final double elevationGain; // meters

  RunTotals({
    required this.count,
    required this.distance,
    required this.movingTime,
    required this.elapsedTime,
    required this.elevationGain,
  });

  factory RunTotals.fromJson(Map<String, dynamic> json) {
    return RunTotals(
      count: json['count'] as int,
      distance: (json['distance'] as num).toDouble(),
      movingTime: json['moving_time'] as int,
      elapsedTime: json['elapsed_time'] as int,
      elevationGain: (json['elevation_gain'] as num).toDouble(),
    );
  }

  String get distanceKm => (distance / 1000).toStringAsFixed(2);
}

/// Combined activity with streams for convenience
class StravaActivityWithStreams {
  final StravaActivityDetail activity;
  final StravaActivityStreams? streams;

  StravaActivityWithStreams({
    required this.activity,
    this.streams,
  });
}
