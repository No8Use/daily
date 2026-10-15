import 'package:daily/data/database/app_database.dart';
import 'package:equatable/equatable.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final DailyReview? review;
  final DateTime date;
  final bool isEditable;

  const ReviewsLoaded({
    required this.review,
    required this.date,
    required this.isEditable,
  });

  @override
  List<Object?> get props => [review, date, isEditable];
}

class ReviewsError extends ReviewsState {
  final String message;

  const ReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}
