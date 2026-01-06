import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rep_counter.dart';
import './shuttle_run_metrics_calculator.dart';
import './flexibility_metrics_calculator.dart';
import './presidential_fitness_benchmarks.dart';

/// Firebase service for storing and retrieving fitness analysis data
///
/// Firestore Structure:
/// users/{userId}/fitness_analyses/{analysisId}/
///   - exerciseType: string (pushUp, pullUp, sitUp, shuttleRun, sitAndReach, vSitAndReach)
///   - date: timestamp
///   - videoPath: string (optional)
///
///   For rep-based exercises (pushUp, pullUp, sitUp):
///   - reps: int
///
///   For shuttle run:
///   - totalDistance: double (meters)
///   - totalTime: double (seconds)
///   - completedRuns: int
///   - averageRunTime: double (seconds)
///   - averageSpeed: double (m/s)
///   - maxSpeed: double (m/s)
///   - peakSpeedTime: double (seconds)
///   - runTimes: List<double>
///   - speedProfile: List<double>
///   - shuttleDistance: double (meters)
///   - directionChanges: int
///   - averageTurnTime: double (seconds)
///
///   For flexibility tests (sitAndReach, vSitAndReach):
///   - reachDistance: double (cm)
///   - maxReachDistance: double (cm)
///   - flexibilityScore: double (0-100)
///   - hamstringFlexibility: double (degrees)
///   - lowerBackFlexibility: double (degrees)
///   - hipFlexibility: double (degrees)
///   - rating: string
///   - reachProfile: List<double>
///   - reps: int (number of attempts)
class FirebaseFitnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // For now, using a default user ID. In production, use Firebase Auth
  String get userId =>
      'default_user'; // TODO: Replace with Firebase Auth user ID

  /// Save rep-based exercise analysis (pushUp, pullUp, sitUp)
  Future<String?> saveRepExercise({
    required ExerciseType exerciseType,
    required int reps,
    String? videoPath,
    int? userAge,
    Gender? userGender,
  }) async {
    try {
      print('💪 Saving rep-based exercise: $exerciseType with $reps reps');

      final analysisRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .doc();

      final data = <String, dynamic>{
        'exerciseType': exerciseType.toString().split('.').last,
        'reps': reps,
        'date': FieldValue.serverTimestamp(),
        'videoPath': videoPath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add benchmark comparison if age and gender are provided
      if (userAge != null && userGender != null) {
        BenchmarkComparison? comparison;
        if (exerciseType == ExerciseType.sitUp) {
          comparison = PresidentialFitnessBenchmarks.compareSitUps(
            reps: reps,
            age: userAge,
            gender: userGender,
          );
        } else if (exerciseType == ExerciseType.pullUp) {
          comparison = PresidentialFitnessBenchmarks.comparePullUps(
            reps: reps,
            age: userAge,
            gender: userGender,
          );
        }

        if (comparison != null) {
          data['benchmarkPassed'] = comparison.passed;
          data['benchmarkValue'] = comparison.benchmarkValue;
          data['userValue'] = comparison.userValue;
          data['difference'] = comparison.difference;
          data['differenceText'] = comparison.differenceText;
        }
      }

      await analysisRef.set(data);

      print('✅ Successfully saved rep exercise with ID: ${analysisRef.id}');
      return analysisRef.id;
    } catch (e) {
      print('❌ Error saving rep exercise: $e');
      return null;
    }
  }

  /// Save shuttle run analysis
  Future<String?> saveShuttleRun({
    required ShuttleRunPerformanceMetrics metrics,
    String? videoPath,
    int? userAge,
    Gender? userGender,
  }) async {
    try {
      print('🏃 Saving shuttle run analysis');

      final analysisRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .doc();

      final data = <String, dynamic>{
        'exerciseType': 'shuttleRun',
        'totalDistance': metrics.totalDistance,
        'totalTime': metrics.totalTime,
        'completedRuns': metrics.completedRuns,
        'averageRunTime': metrics.averageRunTime,
        'averageSpeed': metrics.averageSpeed,
        'maxSpeed': metrics.maxSpeed,
        'peakSpeedTime': metrics.peakSpeedTime,
        'runTimes': metrics.runTimes,
        'speedProfile': metrics.speedProfile,
        'shuttleDistance': metrics.shuttleDistance,
        'directionChanges': metrics.directionChanges,
        'averageTurnTime': metrics.averageTurnTime,
        'date': FieldValue.serverTimestamp(),
        'videoPath': videoPath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add benchmark comparison if age and gender are provided
      if (userAge != null && userGender != null) {
        final comparison = PresidentialFitnessBenchmarks.compareShuttleRun(
          timeInSeconds: metrics.totalTime,
          age: userAge,
          gender: userGender,
        );

        if (comparison != null) {
          data['benchmarkPassed'] = comparison.passed;
          data['benchmarkValue'] = comparison.benchmarkValue;
          data['userValue'] = comparison.userValue;
          data['difference'] = comparison.difference;
          data['differenceText'] = comparison.differenceText;
        }
      }

      await analysisRef.set(data);

      print('✅ Successfully saved shuttle run with ID: ${analysisRef.id}');
      return analysisRef.id;
    } catch (e) {
      print('❌ Error saving shuttle run: $e');
      return null;
    }
  }

  /// Save flexibility test analysis (sitAndReach, vSitAndReach)
  Future<String?> saveFlexibilityTest({
    required FlexibilityMetrics metrics,
    required int reps,
    String? videoPath,
    int? userAge,
    Gender? userGender,
  }) async {
    try {
      print('🧘 Saving flexibility test: ${metrics.testType}');

      final analysisRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .doc();

      final data = <String, dynamic>{
        'exerciseType': metrics.testType.toString().split('.').last,
        'reachDistance': metrics.reachDistance,
        'maxReachDistance': metrics.maxReachDistance,
        'flexibilityScore': metrics.flexibilityScore,
        'hamstringFlexibility': metrics.hamstringFlexibility,
        'lowerBackFlexibility': metrics.lowerBackFlexibility,
        'hipFlexibility': metrics.hipFlexibility,
        'rating': metrics.rating,
        'reachProfile': metrics.reachProfile,
        'reps': reps,
        'date': FieldValue.serverTimestamp(),
        'videoPath': videoPath,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add benchmark comparison if age and gender are provided
      if (userAge != null && userGender != null) {
        // Convert cm to inches for comparison
        final reachInches = PresidentialFitnessBenchmarks.cmToInches(
          metrics.maxReachDistance,
        );

        final comparison = PresidentialFitnessBenchmarks.compareFlexibility(
          reachInches: reachInches,
          age: userAge,
          gender: userGender,
        );

        if (comparison != null) {
          data['benchmarkPassed'] = comparison.passed;
          data['benchmarkValue'] = comparison.benchmarkValue;
          data['userValue'] = comparison.userValue;
          data['difference'] = comparison.difference;
          data['differenceText'] = comparison.differenceText;
        }
      }

      await analysisRef.set(data);

      print('✅ Successfully saved flexibility test with ID: ${analysisRef.id}');
      return analysisRef.id;
    } catch (e) {
      print('❌ Error saving flexibility test: $e');
      return null;
    }
  }

  /// Get all fitness analyses for the current user
  Future<List<Map<String, dynamic>>> getAllAnalyses({
    int? limit,
    ExerciseType? filterByExercise,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .orderBy('date', descending: true);

      if (filterByExercise != null) {
        query = query.where('exerciseType',
            isEqualTo: filterByExercise.toString().split('.').last);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching analyses: $e');
      return [];
    }
  }

  /// Get analyses for a specific date
  Future<List<Map<String, dynamic>>> getAnalysesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching analyses by date: $e');
      return [];
    }
  }

  /// Get a specific analysis by ID
  Future<Map<String, dynamic>?> getAnalysisById(String analysisId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .doc(analysisId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Error fetching analysis: $e');
      return null;
    }
  }

  /// Delete a specific analysis
  Future<bool> deleteAnalysis(String analysisId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .doc(analysisId)
          .delete();

      print('✅ Successfully deleted analysis: $analysisId');
      return true;
    } catch (e) {
      print('❌ Error deleting analysis: $e');
      return false;
    }
  }

  /// Get statistics for a specific exercise type
  Future<Map<String, dynamic>> getExerciseStats(
      ExerciseType exerciseType) async {
    try {
      final analyses = await getAllAnalyses(filterByExercise: exerciseType);

      if (analyses.isEmpty) {
        return {
          'totalSessions': 0,
          'averageReps': 0,
          'maxReps': 0,
          'lastSessionDate': null,
        };
      }

      int totalReps = 0;
      int maxReps = 0;

      for (var analysis in analyses) {
        final reps = analysis['reps'] as int? ?? 0;
        totalReps += reps;
        if (reps > maxReps) maxReps = reps;
      }

      return {
        'totalSessions': analyses.length,
        'averageReps': totalReps / analyses.length,
        'maxReps': maxReps,
        'lastSessionDate': analyses.first['date'],
      };
    } catch (e) {
      print('❌ Error calculating exercise stats: $e');
      return {
        'totalSessions': 0,
        'averageReps': 0,
        'maxReps': 0,
        'lastSessionDate': null,
      };
    }
  }

  /// Get fitness data for the past week grouped by exercise type
  /// Returns a map of exercise types to their daily values and benchmarks
  Future<Map<String, WeeklyFitnessData>> getWeeklyFitnessData({
    int? userAge,
    Gender? userGender,
  }) async {
    try {
      // Get data from the past 7 days
      final now = DateTime.now();
      final startOfWeek = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fitness_analyses')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .get();

      // Initialize map for all exercise types
      final Map<String, WeeklyFitnessData> weeklyData = {};

      // Process each exercise type
      for (final exerciseType in [
        ExerciseType.pushUp,
        ExerciseType.pullUp,
        ExerciseType.sitUp,
        ExerciseType.shuttleRun,
        ExerciseType.vSitAndReach,
      ]) {
        final exerciseTypeStr = exerciseType.toString().split('.').last;

        // Initialize daily values (7 days)
        final List<double?> dailyValues = List.filled(7, null);

        // Get benchmark value
        double? benchmarkValue;
        if (userAge != null && userGender != null) {
          benchmarkValue = PresidentialFitnessBenchmarks.getBenchmark(
            exerciseType: exerciseType,
            age: userAge,
            gender: userGender,
          );
        }

        // Fill in data for each day
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final docExerciseType = data['exerciseType'] as String?;

          if (docExerciseType == exerciseTypeStr) {
            final timestamp = data['date'] as Timestamp?;
            if (timestamp != null) {
              final date = timestamp.toDate();
              final dayIndex = date.difference(startOfWeek).inDays;

              if (dayIndex >= 0 && dayIndex < 7) {
                // Get the performance value based on exercise type
                double? value;
                if (exerciseType == ExerciseType.pushUp ||
                    exerciseType == ExerciseType.pullUp ||
                    exerciseType == ExerciseType.sitUp) {
                  value = (data['reps'] as int?)?.toDouble();
                } else if (exerciseType == ExerciseType.shuttleRun) {
                  // For shuttle run, use total time
                  value = (data['totalTime'] as num?)?.toDouble();
                } else if (exerciseType == ExerciseType.vSitAndReach) {
                  // For flexibility, use max reach distance in inches
                  final reachCm =
                      (data['maxReachDistance'] as num?)?.toDouble();
                  if (reachCm != null) {
                    value = PresidentialFitnessBenchmarks.cmToInches(reachCm);
                  }
                }

                // If multiple entries for same day, keep the best one
                if (value != null) {
                  if (dailyValues[dayIndex] == null) {
                    dailyValues[dayIndex] = value;
                  } else {
                    // For shuttle run, lower is better
                    if (exerciseType == ExerciseType.shuttleRun) {
                      dailyValues[dayIndex] = value < dailyValues[dayIndex]!
                          ? value
                          : dailyValues[dayIndex];
                    } else {
                      // For others, higher is better
                      dailyValues[dayIndex] = value > dailyValues[dayIndex]!
                          ? value
                          : dailyValues[dayIndex];
                    }
                  }
                }
              }
            }
          }
        }

        weeklyData[exerciseTypeStr] = WeeklyFitnessData(
          exerciseType: exerciseType,
          dailyValues: dailyValues,
          benchmarkValue: benchmarkValue,
          unit: _getUnitForExercise(exerciseType),
        );
      }

      return weeklyData;
    } catch (e) {
      print('❌ Error fetching weekly fitness data: $e');
      return {};
    }
  }

  /// Get unit label for exercise type
  String _getUnitForExercise(ExerciseType exerciseType) {
    switch (exerciseType) {
      case ExerciseType.pushUp:
      case ExerciseType.pullUp:
      case ExerciseType.sitUp:
        return 'reps';
      case ExerciseType.shuttleRun:
        return 'seconds';
      case ExerciseType.vSitAndReach:
      case ExerciseType.sitAndReach:
        return 'inches';
      default:
        return '';
    }
  }
}

/// Weekly fitness data model
class WeeklyFitnessData {
  final ExerciseType exerciseType;
  final List<double?> dailyValues; // 7 days, null if no data
  final double? benchmarkValue;
  final String unit;

  WeeklyFitnessData({
    required this.exerciseType,
    required this.dailyValues,
    this.benchmarkValue,
    required this.unit,
  });

  String get exerciseName {
    switch (exerciseType) {
      case ExerciseType.pushUp:
        return 'Push Ups';
      case ExerciseType.pullUp:
        return 'Pull Ups';
      case ExerciseType.sitUp:
        return 'Sit Ups';
      case ExerciseType.shuttleRun:
        return 'Shuttle Run';
      case ExerciseType.vSitAndReach:
        return 'V-Sit & Reach';
      default:
        return '';
    }
  }

  bool get hasData => dailyValues.any((value) => value != null);
}
