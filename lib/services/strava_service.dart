/// Strava API service for fetching activity data
/// Retrieves running activities, detailed metrics, and stream data
import 'package:dio/dio.dart';
import 'strava_auth_service.dart';
import '../models/strava_activity.dart';

class StravaService {
  final StravaAuthService _authService;
  final Dio _dio;

  static const String baseUrl = 'https://www.strava.com/api/v3';

  StravaService(this._authService)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        ) {
    // Add interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 unauthorized - token might be expired
          if (error.response?.statusCode == 401) {
            try {
              await _authService.refreshToken();
              // Retry the request
              final token = await _authService.getAccessToken();
              if (token != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              print('Error refreshing token: $e');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Fetch athlete's activities
  /// [page] - Page number (default 1)
  /// [perPage] - Activities per page (default 30, max 200)
  /// [before] - Unix timestamp to fetch activities before
  /// [after] - Unix timestamp to fetch activities after
  Future<List<StravaActivity>> getActivities({
    int page = 1,
    int perPage = 30,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (before != null) {
        queryParams['before'] = before.millisecondsSinceEpoch ~/ 1000;
      }
      if (after != null) {
        queryParams['after'] = after.millisecondsSinceEpoch ~/ 1000;
      }

      final response = await _dio.get(
        '/athlete/activities',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((json) => StravaActivity.fromJson(json))
            .where((activity) => activity.type == 'Run')
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching activities: $e');
      rethrow;
    }
  }

  /// Fetch detailed activity data
  Future<StravaActivityDetail?> getActivityDetail(int activityId) async {
    try {
      final response = await _dio.get('/activities/$activityId');

      if (response.statusCode == 200) {
        return StravaActivityDetail.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching activity detail: $e');
      rethrow;
    }
  }

  /// Fetch activity streams (time series data)
  /// Available stream types: time, distance, latlng, altitude, velocity_smooth,
  /// heartrate, cadence, watts, temp, moving, grade_smooth
  Future<StravaActivityStreams?> getActivityStreams(
    int activityId, {
    List<String> types = const [
      'time',
      'distance',
      'altitude',
      'velocity_smooth',
      'heartrate',
      'cadence',
    ],
  }) async {
    try {
      final typesString = types.join(',');
      final response = await _dio.get(
        '/activities/$activityId/streams',
        queryParameters: {
          'keys': typesString,
          'key_by_type': true,
        },
      );

      if (response.statusCode == 200) {
        return StravaActivityStreams.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching activity streams: $e');
      // Return null if streams don't exist (not all activities have all streams)
      return null;
    }
  }

  /// Get athlete stats
  Future<StravaAthleteStats?> getAthleteStats() async {
    try {
      final athleteId = await _authService.getAthleteId();
      if (athleteId == null) return null;

      final response = await _dio.get('/athletes/$athleteId/stats');

      if (response.statusCode == 200) {
        return StravaAthleteStats.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error fetching athlete stats: $e');
      return null;
    }
  }

  /// Get all running activities with full details
  /// This is a convenience method that fetches activities and their details
  Future<List<StravaActivityWithStreams>> getRunningActivitiesWithDetails({
    int limit = 10,
    DateTime? after,
  }) async {
    try {
      final activities = await getActivities(
        perPage: limit,
        after: after,
      );

      final activitiesWithStreams = <StravaActivityWithStreams>[];

      for (final activity in activities) {
        final detail = await getActivityDetail(activity.id);
        final streams = await getActivityStreams(activity.id);

        if (detail != null) {
          activitiesWithStreams.add(
            StravaActivityWithStreams(
              activity: detail,
              streams: streams,
            ),
          );
        }
      }

      return activitiesWithStreams;
    } catch (e) {
      print('Error fetching running activities with details: $e');
      rethrow;
    }
  }
}
