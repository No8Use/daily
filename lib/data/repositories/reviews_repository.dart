import 'package:daily/data/database/app_database.dart';
import 'package:daily/utils/date_utils.dart';

class ReviewsRepository {
  final AppDatabase db;

  ReviewsRepository(this.db);

  /// Gets review for a specific date.
  Future<DailyReview?> getReviewForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.dailyReviews)
          ..where((tbl) => tbl.date.equals(normalizedDate)))
        .getSingleOrNull();
  }

  /// Streams review for a specific date.
  Stream<DailyReview?> watchReviewForDate(DateTime date) {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    return (db.select(db.dailyReviews)
          ..where((tbl) => tbl.date.equals(normalizedDate)))
        .watchSingleOrNull();
  }

  /// Gets all daily reviews.
  Future<List<DailyReview>> getAllReviews() {
    return db.select(db.dailyReviews).get();
  }

  /// Saves or updates daily review for a specific date.
  /// Throws Exception if trying to edit/save for a past date (`date < today`).
  Future<void> saveReview(DateTime date, String description, int rating) async {
    final normalizedDate = AppDateUtils.normalizeDate(date);
    final today = AppDateUtils.today;

    if (normalizedDate.isBefore(today)) {
      throw Exception('Нельзя редактировать отзыв за прошедшие дни.');
    }

    await db.into(db.dailyReviews).insertOnConflictUpdate(
          DailyReviewsCompanion.insert(
            date: normalizedDate,
            description: description,
            rating: rating.clamp(1, 10),
          ),
        );
  }
}
