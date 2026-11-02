import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/year_review.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';

sealed class YearReviewState {
  const YearReviewState();
}

class YearReviewLoading extends YearReviewState {
  const YearReviewLoading();
}

class YearReviewLoaded extends YearReviewState {
  final YearReview review;
  const YearReviewLoaded(this.review);
}

class YearReviewError extends YearReviewState {
  const YearReviewError();
}

/// Loads the library once and computes the review of [year]. A review is a
/// snapshot to page through, so it does not follow later changes.
class YearReviewCubit extends Cubit<YearReviewState> {
  final BookRepository _books;
  final ReadingRepository _reading;
  final int year;

  YearReviewCubit(this._books, this._reading, {required this.year})
    : super(const YearReviewLoading());

  Future<void> load() async {
    try {
      final review = YearReview.of(
        year,
        await _books.getAllBooks(),
        await _reading.watchAllSessions().first,
      );
      // The user may have left the screen while this was loading.
      if (!isClosed) emit(YearReviewLoaded(review));
    } catch (_) {
      if (!isClosed) emit(const YearReviewError());
    }
  }
}
