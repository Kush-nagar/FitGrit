/// Presidential Fitness Test Benchmarks
/// Contains age and gender-specific criteria for all fitness tests
import '../models/rep_counter.dart';

enum Gender { male, female }

/// Benchmark data for a specific exercise, age, and gender
class FitnessBenchmark {
  final int age;
  final Gender gender;
  final ExerciseType exerciseType;
  final double value;
  final String unit;

  FitnessBenchmark({
    required this.age,
    required this.gender,
    required this.exerciseType,
    required this.value,
    required this.unit,
  });
}

/// Result of comparing user performance against benchmark
class BenchmarkComparison {
  final bool passed;
  final double userValue;
  final double benchmarkValue;
  final double difference;
  final String differenceText;
  final String unit;

  BenchmarkComparison({
    required this.passed,
    required this.userValue,
    required this.benchmarkValue,
    required this.difference,
    required this.differenceText,
    required this.unit,
  });

  @override
  String toString() {
    if (passed) {
      return 'Passed! Exceeded benchmark by $differenceText';
    } else {
      return 'Not met. Need $differenceText more to pass';
    }
  }
}

/// Service for presidential fitness test benchmarks
class PresidentialFitnessBenchmarks {
  // Boys (Male) Benchmarks
  static final Map<int, Map<String, double>> _boysBenchmarks = {
    6: {
      'sitUps': 33,
      'shuttleRun': 12.1,
      'vSitReach': 3.5,
      'pullUps': 2,
      'pushUps': 9
    },
    7: {
      'sitUps': 36,
      'shuttleRun': 11.5,
      'vSitReach': 3.5,
      'pullUps': 4,
      'pushUps': 14
    },
    8: {
      'sitUps': 40,
      'shuttleRun': 11.1,
      'vSitReach': 3.0,
      'pullUps': 5,
      'pushUps': 17
    },
    9: {
      'sitUps': 41,
      'shuttleRun': 10.9,
      'vSitReach': 3.0,
      'pullUps': 5,
      'pushUps': 18
    },
    10: {
      'sitUps': 45,
      'shuttleRun': 10.3,
      'vSitReach': 4.0,
      'pullUps': 6,
      'pushUps': 22
    },
    11: {
      'sitUps': 47,
      'shuttleRun': 10.0,
      'vSitReach': 4.0,
      'pullUps': 6,
      'pushUps': 27
    },
    12: {
      'sitUps': 50,
      'shuttleRun': 9.8,
      'vSitReach': 4.0,
      'pullUps': 7,
      'pushUps': 31
    },
    13: {
      'sitUps': 53,
      'shuttleRun': 9.5,
      'vSitReach': 3.5,
      'pullUps': 7,
      'pushUps': 39
    },
    14: {
      'sitUps': 56,
      'shuttleRun': 9.1,
      'vSitReach': 4.5,
      'pullUps': 10,
      'pushUps': 40
    },
    15: {
      'sitUps': 57,
      'shuttleRun': 9.0,
      'vSitReach': 5.0,
      'pullUps': 11,
      'pushUps': 42
    },
    16: {
      'sitUps': 56,
      'shuttleRun': 8.7,
      'vSitReach': 6.0,
      'pullUps': 11,
      'pushUps': 44
    },
    17: {
      'sitUps': 55,
      'shuttleRun': 8.7,
      'vSitReach': 7.0,
      'pullUps': 13,
      'pushUps': 53
    },
  };

  // Girls (Female) Benchmarks
  static final Map<int, Map<String, double>> _girlsBenchmarks = {
    6: {
      'sitUps': 32,
      'shuttleRun': 12.4,
      'vSitReach': 5.5,
      'pullUps': 2,
      'pushUps': 9
    },
    7: {
      'sitUps': 34,
      'shuttleRun': 12.1,
      'vSitReach': 5.0,
      'pullUps': 2,
      'pushUps': 14
    },
    8: {
      'sitUps': 38,
      'shuttleRun': 11.8,
      'vSitReach': 4.5,
      'pullUps': 2,
      'pushUps': 17
    },
    9: {
      'sitUps': 39,
      'shuttleRun': 11.1,
      'vSitReach': 5.5,
      'pullUps': 2,
      'pushUps': 18
    },
    10: {
      'sitUps': 40,
      'shuttleRun': 10.8,
      'vSitReach': 6.0,
      'pullUps': 3,
      'pushUps': 20
    },
    11: {
      'sitUps': 42,
      'shuttleRun': 10.5,
      'vSitReach': 6.5,
      'pullUps': 3,
      'pushUps': 19
    },
    12: {
      'sitUps': 45,
      'shuttleRun': 10.4,
      'vSitReach': 7.0,
      'pullUps': 2,
      'pushUps': 20
    },
    13: {
      'sitUps': 46,
      'shuttleRun': 10.2,
      'vSitReach': 7.0,
      'pullUps': 2,
      'pushUps': 31
    },
    14: {
      'sitUps': 47,
      'shuttleRun': 10.1,
      'vSitReach': 8.0,
      'pullUps': 2,
      'pushUps': 20
    },
    15: {
      'sitUps': 48,
      'shuttleRun': 10.0,
      'vSitReach': 8.0,
      'pullUps': 2,
      'pushUps': 21
    },
    16: {
      'sitUps': 45,
      'shuttleRun': 10.1,
      'vSitReach': 9.0,
      'pullUps': 1,
      'pushUps': 24
    },
    17: {
      'sitUps': 44,
      'shuttleRun': 10.0,
      'vSitReach': 8.0,
      'pullUps': 1,
      'pushUps': 25
    },
  };

  /// Get benchmark value for a specific exercise, age, and gender
  static double? getBenchmark({
    required ExerciseType exerciseType,
    required int age,
    required Gender gender,
  }) {
    // Clamp age to valid range
    if (age < 6) age = 6;
    if (age > 17) age = 17;

    final benchmarks =
        gender == Gender.male ? _boysBenchmarks : _girlsBenchmarks;
    final ageBenchmarks = benchmarks[age];

    if (ageBenchmarks == null) return null;

    switch (exerciseType) {
      case ExerciseType.sitUp:
        return ageBenchmarks['sitUps'];
      case ExerciseType.shuttleRun:
        return ageBenchmarks['shuttleRun'];
      case ExerciseType.vSitAndReach:
      case ExerciseType.sitAndReach:
        return ageBenchmarks['vSitReach'];
      case ExerciseType.pullUp:
        return ageBenchmarks['pullUps'];
      case ExerciseType.pushUp:
        return ageBenchmarks['pushUps'];
      default:
        return null;
    }
  }

  /// Compare sit-ups performance against benchmark
  static BenchmarkComparison? compareSitUps({
    required int reps,
    required int age,
    required Gender gender,
  }) {
    final benchmark = getBenchmark(
      exerciseType: ExerciseType.sitUp,
      age: age,
      gender: gender,
    );

    if (benchmark == null) return null;

    final difference = reps - benchmark;
    final passed = reps >= benchmark;

    return BenchmarkComparison(
      passed: passed,
      userValue: reps.toDouble(),
      benchmarkValue: benchmark,
      difference: difference.abs(),
      differenceText: '${difference.abs().round()} reps',
      unit: 'reps',
    );
  }

  /// Compare pull-ups performance against benchmark
  static BenchmarkComparison? comparePullUps({
    required int reps,
    required int age,
    required Gender gender,
  }) {
    final benchmark = getBenchmark(
      exerciseType: ExerciseType.pullUp,
      age: age,
      gender: gender,
    );

    if (benchmark == null) return null;

    final difference = reps - benchmark;
    final passed = reps >= benchmark;

    return BenchmarkComparison(
      passed: passed,
      userValue: reps.toDouble(),
      benchmarkValue: benchmark,
      difference: difference.abs(),
      differenceText: '${difference.abs().round()} reps',
      unit: 'reps',
    );
  }

  /// Compare push-ups performance against benchmark
  static BenchmarkComparison? comparePushUps({
    required int reps,
    required int age,
    required Gender gender,
  }) {
    final benchmark = getBenchmark(
      exerciseType: ExerciseType.pushUp,
      age: age,
      gender: gender,
    );

    if (benchmark == null) return null;

    final difference = reps - benchmark;
    final passed = reps >= benchmark;

    return BenchmarkComparison(
      passed: passed,
      userValue: reps.toDouble(),
      benchmarkValue: benchmark,
      difference: difference.abs(),
      differenceText: '${difference.abs().round()} reps',
      unit: 'reps',
    );
  }

  /// Compare shuttle run performance against benchmark
  /// Note: Lower time is better for shuttle run
  static BenchmarkComparison? compareShuttleRun({
    required double timeInSeconds,
    required int age,
    required Gender gender,
  }) {
    final benchmark = getBenchmark(
      exerciseType: ExerciseType.shuttleRun,
      age: age,
      gender: gender,
    );

    if (benchmark == null) return null;

    // For shuttle run, lower is better
    final difference = benchmark - timeInSeconds;
    final passed = timeInSeconds <= benchmark;

    return BenchmarkComparison(
      passed: passed,
      userValue: timeInSeconds,
      benchmarkValue: benchmark,
      difference: difference.abs(),
      differenceText: '${difference.abs().toStringAsFixed(1)}s',
      unit: 'seconds',
    );
  }

  /// Compare flexibility test (V-Sit & Reach) against benchmark
  static BenchmarkComparison? compareFlexibility({
    required double reachInches,
    required int age,
    required Gender gender,
  }) {
    final benchmark = getBenchmark(
      exerciseType: ExerciseType.vSitAndReach,
      age: age,
      gender: gender,
    );

    if (benchmark == null) return null;

    final difference = reachInches - benchmark;
    final passed = reachInches >= benchmark;

    return BenchmarkComparison(
      passed: passed,
      userValue: reachInches,
      benchmarkValue: benchmark,
      difference: difference.abs(),
      differenceText: '${difference.abs().toStringAsFixed(1)} inches',
      unit: 'inches',
    );
  }

  /// Convert centimeters to inches for flexibility comparison
  static double cmToInches(double cm) {
    return cm / 2.54;
  }

  /// Convert inches to centimeters
  static double inchesToCm(double inches) {
    return inches * 2.54;
  }

  /// Get all benchmarks for a specific age and gender
  static Map<ExerciseType, double>? getAllBenchmarks({
    required int age,
    required Gender gender,
  }) {
    // Clamp age to valid range
    if (age < 6) age = 6;
    if (age > 17) age = 17;

    final benchmarks =
        gender == Gender.male ? _boysBenchmarks : _girlsBenchmarks;
    final ageBenchmarks = benchmarks[age];

    if (ageBenchmarks == null) return null;

    return {
      ExerciseType.sitUp: ageBenchmarks['sitUps']!,
      ExerciseType.shuttleRun: ageBenchmarks['shuttleRun']!,
      ExerciseType.vSitAndReach: ageBenchmarks['vSitReach']!,
      ExerciseType.pullUp: ageBenchmarks['pullUps']!,
      ExerciseType.pushUp: ageBenchmarks['pushUps']!,
    };
  }
}
