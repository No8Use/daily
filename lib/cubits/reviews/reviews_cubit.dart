import 'dart:async';

import 'package:daily/cubits/reviews/reviews_state.dart';
import 'package:daily/data/repositories/reviews_repository.dart';
import 'package:daily/utils/date_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  final ReviewsRepository repository;
  StreamSubscription? _reviewSub;

  ReviewsCubit(this.repository) : super(ReviewsInitial());

  /// Loads review for specified date (defaults to today).
  void loadReviewForDate([DateTime? date]) {
    final targetDate = AppDateUtils.normalizeDate(date ?? AppDateUtils.today);
    final isEditable = AppDateUtils.isSameDay(targetDate, AppDateUtils.today);

    emit(ReviewsLoading());

    _reviewSub?.cancel();
    _reviewSub = repository.watchReviewForDate(targetDate).listen((review) {
      emit(ReviewsLoaded(
        review: review,
        date: targetDate,
        isEditable: isEditable,
      ));
    }, onError: (e) {
      emit(ReviewsError('Ошибка загрузки отзыва: $e'));
    });
  }

  /// Saves or updates review. Enforces `date == today` requirement.
  Future<void> saveReview(DateTime date, String description, int rating) async {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    if (!AppDateUtils.isSameDay(normalizedDate, AppDateUtils.today)) {
      emit(const ReviewsError('Отзыв можно редактировать только в текущий день!'));
      return;
    }

    try {
      await repository.saveReview(normalizedDate, description, rating);
    } catch (e) {
      emit(ReviewsError('Не удалось сохранить отзыв: $e'));
    }
  }

  @override
  Future<void> close() {
    _reviewSub?.cancel();
    return super.close();
  }
}
