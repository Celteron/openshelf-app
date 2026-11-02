import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openreads/domain/models/book_metadata.dart';
import 'package:openreads/domain/services/metadata_aggregator_service.dart';

sealed class MetadataState {
  const MetadataState();
}

class MetadataIdle extends MetadataState {
  const MetadataIdle();
}

class MetadataLoading extends MetadataState {
  const MetadataLoading();
}

class MetadataLoaded extends MetadataState {
  final AggregatedMetadata result;
  const MetadataLoaded(this.result);
}

class MetadataError extends MetadataState {
  final String message;
  const MetadataError(this.message);
}

/// Runs the metadata lookup orchestration and exposes the merge preview
/// (spec §6.3).
class MetadataCubit extends Cubit<MetadataState> {
  final MetadataAggregatorService _aggregator;

  MetadataCubit(this._aggregator) : super(const MetadataIdle());

  Future<void> lookup(
    BookMetadata base, {
    Set<String> editedFields = const {},
  }) async {
    emit(const MetadataLoading());
    try {
      final result = await _aggregator.enrich(base, editedFields: editedFields);
      emit(MetadataLoaded(result));
    } catch (e) {
      emit(MetadataError(e.toString()));
    }
  }
}
