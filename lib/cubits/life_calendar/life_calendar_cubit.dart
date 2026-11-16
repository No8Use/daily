import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/data/data_utils/life_calendar_calculator.dart';
import 'package:daily/data/models/life_calendar_models.dart';
import 'package:daily/data/repositories/life_calendar_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LifeCalendarCubit extends Cubit<LifeCalendarState> {
  LifeCalendarCubit(
      this.repository, {
        LifeCalendarCalculator? calculator,
      })  : _calculator = calculator ?? LifeCalendarCalculator(),
        super(const LifeCalendarInitial());

  final LifeCalendarRepository repository;
  final LifeCalendarCalculator _calculator;

  int _loadRequestId = 0;

  Future<void> load({
    bool showLoading = true,
  }) async {
    final requestId = ++_loadRequestId;

    if (showLoading) {
      emit(const LifeCalendarLoading());
    }

    try {
      final settings = await repository.getSettings();

      if (isClosed || requestId != _loadRequestId) return;

      if (settings == null) {
        emit(const LifeCalendarSetupRequired());
        return;
      }

      final today = AppDateUtils.today;

      final calendarData = await repository.getCalendarData(
        from: settings.startedAt,
        to: today,
      );

      if (isClosed || requestId != _loadRequestId) return;

      final result = _calculator.calculate(
        birthDate: settings.birthDate,
        startedAt: settings.startedAt,
        targetAge: settings.targetAge,
        today: today,
        data: calendarData,
      );

      emit(
        LifeCalendarLoaded(
          settings: settings,
          totalWeeks: result.totalWeeks,
          currentWeekIndex: result.currentWeekIndex,
          trackingStartWeekIndex:
          result.trackingStartWeekIndex,
          weeklyScores: result.weeklyScores,
          weeklyProductivity: result.weeklyProductivity,
          weeklyReviews: result.weeklyReviews,
        ),
      );
    } catch (error) {
      if (!isClosed && requestId == _loadRequestId) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }

  Future<void> refresh() {
    return load(showLoading: false);
  }

  Future<void> configure({
    required DateTime birthDate,
    required int targetAge,
  }) async {
    try {
      _calculator.validateConfiguration(
        birthDate: birthDate,
        targetAge: targetAge,
        today: AppDateUtils.today,
      );

      await repository.saveSettings(
        birthDate: birthDate,
        targetAge: targetAge,
      );

      if (isClosed) return;

      await load();
    } catch (error) {
      if (!isClosed) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }

  Future<void> updateTargetAge(int targetAge) async {
    try {
      final currentState = state;

      if (currentState is! LifeCalendarLoaded) {
        throw StateError(
          'Life calendar has not been configured.',
        );
      }

      _calculator.validateTargetAge(
        birthDate: currentState.settings.birthDate,
        targetAge: targetAge,
        today: AppDateUtils.today,
      );

      await repository.updateTargetAge(targetAge);

      if (isClosed) return;

      await load();
    } catch (error) {
      if (!isClosed) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }

  DateTime getWeekStart(int weekIndex) {
    final currentState = state;

    if (currentState is! LifeCalendarLoaded) {
      throw StateError('Life calendar is not loaded.');
    }

    if (weekIndex < 0 || weekIndex >= currentState.totalWeeks) {
      throw RangeError.index(
        weekIndex,
        List<int>.generate(currentState.totalWeeks, (i) => i),
        'weekIndex',
      );
    }

    return _calculator.getWeekStart(
      birthDate: currentState.settings.birthDate,
      weekIndex: weekIndex,
    );
  }

  WeekProductivity getWeekProductivity(int weekIndex) {
    final currentState = state;

    if (currentState is! LifeCalendarLoaded) {
      return WeekProductivity.empty;
    }

    return currentState.weeklyProductivity[weekIndex] ??
        WeekProductivity.empty;
  }

  WeeklyReviewData? getWeeklyReview(int weekIndex) {
    final currentState = state;

    if (currentState is! LifeCalendarLoaded) {
      return null;
    }

    return currentState.weeklyReviews[weekIndex];
  }

  bool canAddWeeklyReview(int weekIndex) {
    final currentState = state;

    if (currentState is! LifeCalendarLoaded) {
      return false;
    }

    final weekStart = _calculator.getWeekStart(
      birthDate: currentState.settings.birthDate,
      weekIndex: weekIndex,
    );

    return _calculator.isReviewAvailable(
      weekStart: weekStart,
      startedAt: currentState.settings.startedAt,
      today: AppDateUtils.today,
    );
  }

  Future<void> saveWeeklyReview({
    required int weekIndex,
    required int rating,
    required String description,
  }) async {
    final currentState = state;

    if (currentState is! LifeCalendarLoaded) {
      throw StateError('Life calendar is not loaded.');
    }

    if (rating < 1 || rating > 10) {
      throw ArgumentError(
        'Rating must be between 1 and 10.',
      );
    }

    if (!canAddWeeklyReview(weekIndex)) {
      throw StateError(
        'A review can only be added to a completed tracked week.',
      );
    }

    final weekStart = getWeekStart(weekIndex);

    await repository.saveWeeklyReview(
      weekStart: weekStart,
      rating: rating,
      description: description,
    );

    if (isClosed) return;

    // Refreshes the calendar data and recalculates all affected scores.
    // The UI remains visible because loading is not emitted.
    await load(showLoading: false);
  }
}