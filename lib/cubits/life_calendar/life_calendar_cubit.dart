import 'package:daily/cubits/life_calendar/life_calendar_state.dart';
import 'package:daily/data/repositories/life_calendar_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LifeCalendarCubit extends Cubit<LifeCalendarState> {
  LifeCalendarCubit(this.repository) : super(LifeCalendarInitial());

  final LifeCalendarRepository repository;

  Future<void> load() async {
    emit(LifeCalendarLoading());

    try {
      final settings = await repository.getSettings();

      if (isClosed) return;

      if (settings == null) {
        emit(LifeCalendarSetupRequired());
        return;
      }

      emit(LifeCalendarLoaded(settings: settings));
    } catch (error) {
      if (!isClosed) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }

  Future<void> configure({
    required int startAge,
    required int targetAge,
  }) async {
    try {
      await repository.saveSettings(
        startAge: startAge,
        targetAge: targetAge,
      );

      await load();
    } catch (error) {
      if (!isClosed) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }

  Future<void> updateTargetAge(int age) async {
    try {
      await repository.updateTargetAge(age);
      await load();
    } catch (error) {
      if (!isClosed) {
        emit(LifeCalendarError(error.toString()));
      }
    }
  }
}