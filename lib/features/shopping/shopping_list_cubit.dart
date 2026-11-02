import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/shopping_list.dart';
import 'package:openreads/domain/repositories/book_repository.dart';
import 'package:openreads/domain/repositories/series_repository.dart';

sealed class ShoppingState {
  const ShoppingState();
}

class ShoppingLoading extends ShoppingState {
  const ShoppingLoading();
}

class ShoppingLoaded extends ShoppingState {
  final ShoppingList list;
  const ShoppingLoaded(this.list);
}

class ShoppingError extends ShoppingState {
  const ShoppingError();
}

/// The shopping list: wishlist plus the volumes missing from known series.
class ShoppingListCubit extends Cubit<ShoppingState> {
  final BookRepository _books;
  final SeriesRepository _series;

  ShoppingListCubit(this._books, this._series) : super(const ShoppingLoading());

  Future<void> load() async {
    try {
      final list = buildShoppingList(
        await _books.getAllBooks(),
        await _series.getAll(),
      );
      // The user may have left the screen while this was loading.
      if (!isClosed) emit(ShoppingLoaded(list));
    } catch (_) {
      if (!isClosed) emit(const ShoppingError());
    }
  }

  Future<void> setTotalVolumes(int seriesId, int? total) async {
    await _series.setTotalVolumes(seriesId, total);
    await load();
  }
}
