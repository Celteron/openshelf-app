import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/reading_calendar.dart';
import 'package:openreads/domain/repositories/reading_repository.dart';

sealed class ReadingCalendarState {
  const ReadingCalendarState();
}

class ReadingCalendarLoading extends ReadingCalendarState {
  const ReadingCalendarLoading();
}

class ReadingCalendarLoaded extends ReadingCalendarState {
  final ReadingCalendar calendar;
  const ReadingCalendarLoaded(this.calendar);
}

class ReadingCalendarError extends ReadingCalendarState {
  const ReadingCalendarError();
}

/// Keeps the reading calendar in step with the reading sessions.
class ReadingCalendarCubit extends Cubit<ReadingCalendarState> {
  final ReadingRepository _reading;
  StreamSubscription<Object?>? _subscription;

  ReadingCalendarCubit(this._reading) : super(const ReadingCalendarLoading());

  void load() {
    _subscription?.cancel();
    _subscription = _reading.watchAllSessions().listen(
      (sessions) => emit(ReadingCalendarLoaded(ReadingCalendar.of(sessions))),
      onError: (_) => emit(const ReadingCalendarError()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
