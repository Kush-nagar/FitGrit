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
          timeInSeconds: metrics.totalTime / metrics.completedRuns,
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
}
