// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocationsTable extends Locations
    with TableInfo<$LocationsTable, Location> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LocationType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LocationType>($LocationsTable.$convertertype);
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, type, parentId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Location> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Location map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Location(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $LocationsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $LocationsTable createAlias(String alias) {
    return $LocationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LocationType, String, String> $convertertype =
      const EnumNameConverter<LocationType>(LocationType.values);
}

class Location extends DataClass implements Insertable<Location> {
  final int id;
  final String name;
  final LocationType type;
  final int? parentId;
  final int sortOrder;
  const Location({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>(
        $LocationsTable.$convertertype.toSql(type),
      );
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  LocationsCompanion toCompanion(bool nullToAbsent) {
    return LocationsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      sortOrder: Value(sortOrder),
    );
  }

  factory Location.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Location(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $LocationsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      parentId: serializer.fromJson<int?>(json['parentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $LocationsTable.$convertertype.toJson(type),
      ),
      'parentId': serializer.toJson<int?>(parentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Location copyWith({
    int? id,
    String? name,
    LocationType? type,
    Value<int?> parentId = const Value.absent(),
    int? sortOrder,
  }) => Location(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    parentId: parentId.present ? parentId.value : this.parentId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Location copyWithCompanion(LocationsCompanion data) {
    return Location(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Location(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, parentId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Location &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.parentId == this.parentId &&
          other.sortOrder == this.sortOrder);
}

class LocationsCompanion extends UpdateCompanion<Location> {
  final Value<int> id;
  final Value<String> name;
  final Value<LocationType> type;
  final Value<int?> parentId;
  final Value<int> sortOrder;
  const LocationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  LocationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required LocationType type,
    this.parentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Location> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? parentId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (parentId != null) 'parent_id': parentId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  LocationsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<LocationType>? type,
    Value<int?>? parentId,
    Value<int>? sortOrder,
  }) {
    return LocationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $LocationsTable.$convertertype.toSql(type.value),
      );
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, Series> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _totalPlannedVolumesMeta =
      const VerificationMeta('totalPlannedVolumes');
  @override
  late final GeneratedColumn<int> totalPlannedVolumes = GeneratedColumn<int>(
    'total_planned_volumes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, totalPlannedVolumes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<Series> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_planned_volumes')) {
      context.handle(
        _totalPlannedVolumesMeta,
        totalPlannedVolumes.isAcceptableOrUnknown(
          data['total_planned_volumes']!,
          _totalPlannedVolumesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Series map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Series(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      totalPlannedVolumes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_planned_volumes'],
      ),
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class Series extends DataClass implements Insertable<Series> {
  final int id;
  final String name;
  final int? totalPlannedVolumes;
  const Series({
    required this.id,
    required this.name,
    this.totalPlannedVolumes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || totalPlannedVolumes != null) {
      map['total_planned_volumes'] = Variable<int>(totalPlannedVolumes);
    }
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      id: Value(id),
      name: Value(name),
      totalPlannedVolumes: totalPlannedVolumes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPlannedVolumes),
    );
  }

  factory Series.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Series(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      totalPlannedVolumes: serializer.fromJson<int?>(
        json['totalPlannedVolumes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'totalPlannedVolumes': serializer.toJson<int?>(totalPlannedVolumes),
    };
  }

  Series copyWith({
    int? id,
    String? name,
    Value<int?> totalPlannedVolumes = const Value.absent(),
  }) => Series(
    id: id ?? this.id,
    name: name ?? this.name,
    totalPlannedVolumes: totalPlannedVolumes.present
        ? totalPlannedVolumes.value
        : this.totalPlannedVolumes,
  );
  Series copyWithCompanion(SeriesTableCompanion data) {
    return Series(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      totalPlannedVolumes: data.totalPlannedVolumes.present
          ? data.totalPlannedVolumes.value
          : this.totalPlannedVolumes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Series(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('totalPlannedVolumes: $totalPlannedVolumes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, totalPlannedVolumes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Series &&
          other.id == this.id &&
          other.name == this.name &&
          other.totalPlannedVolumes == this.totalPlannedVolumes);
}

class SeriesTableCompanion extends UpdateCompanion<Series> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> totalPlannedVolumes;
  const SeriesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.totalPlannedVolumes = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.totalPlannedVolumes = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Series> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? totalPlannedVolumes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (totalPlannedVolumes != null)
        'total_planned_volumes': totalPlannedVolumes,
    });
  }

  SeriesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? totalPlannedVolumes,
  }) {
    return SeriesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      totalPlannedVolumes: totalPlannedVolumes ?? this.totalPlannedVolumes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalPlannedVolumes.present) {
      map['total_planned_volumes'] = Variable<int>(totalPlannedVolumes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('totalPlannedVolumes: $totalPlannedVolumes')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _isbn13Meta = const VerificationMeta('isbn13');
  @override
  late final GeneratedColumn<String> isbn13 = GeneratedColumn<String>(
    'isbn13',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _isbn10Meta = const VerificationMeta('isbn10');
  @override
  late final GeneratedColumn<String> isbn10 = GeneratedColumn<String>(
    'isbn10',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> authors =
      GeneratedColumn<String>(
        'authors',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($BooksTable.$converterauthors);
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedYearMeta = const VerificationMeta(
    'publishedYear',
  );
  @override
  late final GeneratedColumn<int> publishedYear = GeneratedColumn<int>(
    'published_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BookFormat?, String> format =
      GeneratedColumn<String>(
        'format',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<BookFormat?>($BooksTable.$converterformatn);
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<BookStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('unread'),
      ).withConverter<BookStatus>($BooksTable.$converterstatus);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<int> locationId = GeneratedColumn<int>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES locations (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES series (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _seriesVolumeMeta = const VerificationMeta(
    'seriesVolume',
  );
  @override
  late final GeneratedColumn<double> seriesVolume = GeneratedColumn<double>(
    'series_volume',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverLocalPathMeta = const VerificationMeta(
    'coverLocalPath',
  );
  @override
  late final GeneratedColumn<String> coverLocalPath = GeneratedColumn<String>(
    'cover_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MetadataSource?, String>
  metadataSource = GeneratedColumn<String>(
    'metadata_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<MetadataSource?>($BooksTable.$convertermetadataSourcen);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
  editedFields = GeneratedColumn<String>(
    'edited_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<String>>($BooksTable.$convertereditedFields);
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewMeta = const VerificationMeta('review');
  @override
  late final GeneratedColumn<String> review = GeneratedColumn<String>(
    'review',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _olidMeta = const VerificationMeta('olid');
  @override
  late final GeneratedColumn<String> olid = GeneratedColumn<String>(
    'olid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceCentsMeta = const VerificationMeta(
    'priceCents',
  );
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
    'price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _readingSecondsMeta = const VerificationMeta(
    'readingSeconds',
  );
  @override
  late final GeneratedColumn<int> readingSeconds = GeneratedColumn<int>(
    'reading_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReceivedAs?, int> receivedAs =
      GeneratedColumn<int>(
        'received_as',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<ReceivedAs?>($BooksTable.$converterreceivedAsn);
  static const VerificationMeta _coverNotFoundMeta = const VerificationMeta(
    'coverNotFound',
  );
  @override
  late final GeneratedColumn<bool> coverNotFound = GeneratedColumn<bool>(
    'cover_not_found',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cover_not_found" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    isbn13,
    isbn10,
    title,
    subtitle,
    authors,
    publisher,
    publishedYear,
    pageCount,
    format,
    language,
    status,
    rating,
    locationId,
    seriesId,
    seriesVolume,
    description,
    coverUrl,
    coverLocalPath,
    metadataSource,
    editedFields,
    currentPage,
    finishedAt,
    isFavorite,
    review,
    olid,
    deletedAt,
    genre,
    priceCents,
    receivedAt,
    readingSeconds,
    receivedAs,
    coverNotFound,
    parentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('isbn13')) {
      context.handle(
        _isbn13Meta,
        isbn13.isAcceptableOrUnknown(data['isbn13']!, _isbn13Meta),
      );
    }
    if (data.containsKey('isbn10')) {
      context.handle(
        _isbn10Meta,
        isbn10.isAcceptableOrUnknown(data['isbn10']!, _isbn10Meta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('published_year')) {
      context.handle(
        _publishedYearMeta,
        publishedYear.isAcceptableOrUnknown(
          data['published_year']!,
          _publishedYearMeta,
        ),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('series_volume')) {
      context.handle(
        _seriesVolumeMeta,
        seriesVolume.isAcceptableOrUnknown(
          data['series_volume']!,
          _seriesVolumeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('cover_local_path')) {
      context.handle(
        _coverLocalPathMeta,
        coverLocalPath.isAcceptableOrUnknown(
          data['cover_local_path']!,
          _coverLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('review')) {
      context.handle(
        _reviewMeta,
        review.isAcceptableOrUnknown(data['review']!, _reviewMeta),
      );
    }
    if (data.containsKey('olid')) {
      context.handle(
        _olidMeta,
        olid.isAcceptableOrUnknown(data['olid']!, _olidMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('price_cents')) {
      context.handle(
        _priceCentsMeta,
        priceCents.isAcceptableOrUnknown(data['price_cents']!, _priceCentsMeta),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('reading_seconds')) {
      context.handle(
        _readingSecondsMeta,
        readingSeconds.isAcceptableOrUnknown(
          data['reading_seconds']!,
          _readingSecondsMeta,
        ),
      );
    }
    if (data.containsKey('cover_not_found')) {
      context.handle(
        _coverNotFoundMeta,
        coverNotFound.isAcceptableOrUnknown(
          data['cover_not_found']!,
          _coverNotFoundMeta,
        ),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isbn13: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn13'],
      ),
      isbn10: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn10'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      authors: $BooksTable.$converterauthors.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}authors'],
        )!,
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      publishedYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}published_year'],
      ),
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      ),
      format: $BooksTable.$converterformatn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}format'],
        ),
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      status: $BooksTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}location_id'],
      ),
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      ),
      seriesVolume: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}series_volume'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      coverLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_local_path'],
      ),
      metadataSource: $BooksTable.$convertermetadataSourcen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}metadata_source'],
        ),
      ),
      editedFields: $BooksTable.$convertereditedFields.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}edited_fields'],
        )!,
      ),
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      review: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review'],
      ),
      olid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}olid'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      priceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_cents'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      ),
      readingSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_seconds'],
      ),
      receivedAs: $BooksTable.$converterreceivedAsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}received_as'],
        ),
      ),
      coverNotFound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cover_not_found'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterauthors =
      const StringListConverter();
  static JsonTypeConverter2<BookFormat, String, String> $converterformat =
      const EnumNameConverter<BookFormat>(BookFormat.values);
  static JsonTypeConverter2<BookFormat?, String?, String?> $converterformatn =
      JsonTypeConverter2.asNullable($converterformat);
  static JsonTypeConverter2<BookStatus, String, String> $converterstatus =
      const EnumNameConverter<BookStatus>(BookStatus.values);
  static JsonTypeConverter2<MetadataSource, String, String>
  $convertermetadataSource = const EnumNameConverter<MetadataSource>(
    MetadataSource.values,
  );
  static JsonTypeConverter2<MetadataSource?, String?, String?>
  $convertermetadataSourcen = JsonTypeConverter2.asNullable(
    $convertermetadataSource,
  );
  static TypeConverter<List<String>, String> $convertereditedFields =
      const StringListConverter();
  static TypeConverter<ReceivedAs, int> $converterreceivedAs =
      const ReceivedAsConverter();
  static TypeConverter<ReceivedAs?, int?> $converterreceivedAsn =
      NullAwareTypeConverter.wrap($converterreceivedAs);
}

class Book extends DataClass implements Insertable<Book> {
  final int id;
  final String? isbn13;
  final String? isbn10;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final BookFormat? format;
  final String? language;
  final BookStatus status;
  final double rating;
  final int? locationId;
  final int? seriesId;
  final double? seriesVolume;
  final String? description;
  final String? coverUrl;
  final String? coverLocalPath;
  final MetadataSource? metadataSource;
  final List<String> editedFields;

  /// Last page the reader reached (Phase 2, schema v2).
  final int currentPage;

  /// When the book last transitioned into `read` (Phase 2, schema v2).
  final DateTime? finishedAt;

  /// Favourite flag (Openreads `favourite`, Phase 2 schema v2).
  final bool isFavorite;

  /// The reader's own review text (Openreads `my_review`, schema v2).
  final String? review;

  /// Open Library ID (Openreads `olid`, schema v3).
  final String? olid;

  /// When the book was moved to the trash; `null` = in the library
  /// (Openreads soft delete, schema v3).
  final DateTime? deletedAt;

  /// Free-text genre; user-editable and never overwritten by imports
  /// (schema v4).
  final String? genre;

  /// Purchase price in euro cents (integer, so no float rounding); a currency
  /// column can be added later (schema v4).
  final int? priceCents;

  /// When the book was bought or received (schema v4).
  final DateTime? receivedAt;

  /// Reading time entered without any dated session (e.g. imported from a
  /// source that only knows a total). Added to the sessions' time (schema v5).
  final int? readingSeconds;

  /// How the book was received, as a pinned code (schema v6): at most
  /// one byte instead of text.
  final ReceivedAs? receivedAs;

  /// Every online source answered "no cover" (schema v6). Device state: never
  /// exported or imported; cleared when a cover is set or URL/ISBN change.
  final bool coverNotFound;

  /// The slipcase this book is a volume of (schema v6, ADR-0003). A book with
  /// volumes is a slipcase; one level only, enforced by the repository.
  final int? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Book({
    required this.id,
    this.isbn13,
    this.isbn10,
    required this.title,
    this.subtitle,
    required this.authors,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.format,
    this.language,
    required this.status,
    required this.rating,
    this.locationId,
    this.seriesId,
    this.seriesVolume,
    this.description,
    this.coverUrl,
    this.coverLocalPath,
    this.metadataSource,
    required this.editedFields,
    required this.currentPage,
    this.finishedAt,
    required this.isFavorite,
    this.review,
    this.olid,
    this.deletedAt,
    this.genre,
    this.priceCents,
    this.receivedAt,
    this.readingSeconds,
    this.receivedAs,
    required this.coverNotFound,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || isbn13 != null) {
      map['isbn13'] = Variable<String>(isbn13);
    }
    if (!nullToAbsent || isbn10 != null) {
      map['isbn10'] = Variable<String>(isbn10);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    {
      map['authors'] = Variable<String>(
        $BooksTable.$converterauthors.toSql(authors),
      );
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || publishedYear != null) {
      map['published_year'] = Variable<int>(publishedYear);
    }
    if (!nullToAbsent || pageCount != null) {
      map['page_count'] = Variable<int>(pageCount);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(
        $BooksTable.$converterformatn.toSql(format),
      );
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    {
      map['status'] = Variable<String>(
        $BooksTable.$converterstatus.toSql(status),
      );
    }
    map['rating'] = Variable<double>(rating);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<int>(locationId);
    }
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<int>(seriesId);
    }
    if (!nullToAbsent || seriesVolume != null) {
      map['series_volume'] = Variable<double>(seriesVolume);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || coverLocalPath != null) {
      map['cover_local_path'] = Variable<String>(coverLocalPath);
    }
    if (!nullToAbsent || metadataSource != null) {
      map['metadata_source'] = Variable<String>(
        $BooksTable.$convertermetadataSourcen.toSql(metadataSource),
      );
    }
    {
      map['edited_fields'] = Variable<String>(
        $BooksTable.$convertereditedFields.toSql(editedFields),
      );
    }
    map['current_page'] = Variable<int>(currentPage);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || review != null) {
      map['review'] = Variable<String>(review);
    }
    if (!nullToAbsent || olid != null) {
      map['olid'] = Variable<String>(olid);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || priceCents != null) {
      map['price_cents'] = Variable<int>(priceCents);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    if (!nullToAbsent || readingSeconds != null) {
      map['reading_seconds'] = Variable<int>(readingSeconds);
    }
    if (!nullToAbsent || receivedAs != null) {
      map['received_as'] = Variable<int>(
        $BooksTable.$converterreceivedAsn.toSql(receivedAs),
      );
    }
    map['cover_not_found'] = Variable<bool>(coverNotFound);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      isbn13: isbn13 == null && nullToAbsent
          ? const Value.absent()
          : Value(isbn13),
      isbn10: isbn10 == null && nullToAbsent
          ? const Value.absent()
          : Value(isbn10),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      authors: Value(authors),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      publishedYear: publishedYear == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedYear),
      pageCount: pageCount == null && nullToAbsent
          ? const Value.absent()
          : Value(pageCount),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      status: Value(status),
      rating: Value(rating),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      seriesVolume: seriesVolume == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesVolume),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      coverLocalPath: coverLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLocalPath),
      metadataSource: metadataSource == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataSource),
      editedFields: Value(editedFields),
      currentPage: Value(currentPage),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      isFavorite: Value(isFavorite),
      review: review == null && nullToAbsent
          ? const Value.absent()
          : Value(review),
      olid: olid == null && nullToAbsent ? const Value.absent() : Value(olid),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      priceCents: priceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCents),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      readingSeconds: readingSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(readingSeconds),
      receivedAs: receivedAs == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAs),
      coverNotFound: Value(coverNotFound),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      isbn13: serializer.fromJson<String?>(json['isbn13']),
      isbn10: serializer.fromJson<String?>(json['isbn10']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      authors: serializer.fromJson<List<String>>(json['authors']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      publishedYear: serializer.fromJson<int?>(json['publishedYear']),
      pageCount: serializer.fromJson<int?>(json['pageCount']),
      format: $BooksTable.$converterformatn.fromJson(
        serializer.fromJson<String?>(json['format']),
      ),
      language: serializer.fromJson<String?>(json['language']),
      status: $BooksTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      rating: serializer.fromJson<double>(json['rating']),
      locationId: serializer.fromJson<int?>(json['locationId']),
      seriesId: serializer.fromJson<int?>(json['seriesId']),
      seriesVolume: serializer.fromJson<double?>(json['seriesVolume']),
      description: serializer.fromJson<String?>(json['description']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      coverLocalPath: serializer.fromJson<String?>(json['coverLocalPath']),
      metadataSource: $BooksTable.$convertermetadataSourcen.fromJson(
        serializer.fromJson<String?>(json['metadataSource']),
      ),
      editedFields: serializer.fromJson<List<String>>(json['editedFields']),
      currentPage: serializer.fromJson<int>(json['currentPage']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      review: serializer.fromJson<String?>(json['review']),
      olid: serializer.fromJson<String?>(json['olid']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      genre: serializer.fromJson<String?>(json['genre']),
      priceCents: serializer.fromJson<int?>(json['priceCents']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      readingSeconds: serializer.fromJson<int?>(json['readingSeconds']),
      receivedAs: serializer.fromJson<ReceivedAs?>(json['receivedAs']),
      coverNotFound: serializer.fromJson<bool>(json['coverNotFound']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isbn13': serializer.toJson<String?>(isbn13),
      'isbn10': serializer.toJson<String?>(isbn10),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'authors': serializer.toJson<List<String>>(authors),
      'publisher': serializer.toJson<String?>(publisher),
      'publishedYear': serializer.toJson<int?>(publishedYear),
      'pageCount': serializer.toJson<int?>(pageCount),
      'format': serializer.toJson<String?>(
        $BooksTable.$converterformatn.toJson(format),
      ),
      'language': serializer.toJson<String?>(language),
      'status': serializer.toJson<String>(
        $BooksTable.$converterstatus.toJson(status),
      ),
      'rating': serializer.toJson<double>(rating),
      'locationId': serializer.toJson<int?>(locationId),
      'seriesId': serializer.toJson<int?>(seriesId),
      'seriesVolume': serializer.toJson<double?>(seriesVolume),
      'description': serializer.toJson<String?>(description),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'coverLocalPath': serializer.toJson<String?>(coverLocalPath),
      'metadataSource': serializer.toJson<String?>(
        $BooksTable.$convertermetadataSourcen.toJson(metadataSource),
      ),
      'editedFields': serializer.toJson<List<String>>(editedFields),
      'currentPage': serializer.toJson<int>(currentPage),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'review': serializer.toJson<String?>(review),
      'olid': serializer.toJson<String?>(olid),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'genre': serializer.toJson<String?>(genre),
      'priceCents': serializer.toJson<int?>(priceCents),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'readingSeconds': serializer.toJson<int?>(readingSeconds),
      'receivedAs': serializer.toJson<ReceivedAs?>(receivedAs),
      'coverNotFound': serializer.toJson<bool>(coverNotFound),
      'parentId': serializer.toJson<int?>(parentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Book copyWith({
    int? id,
    Value<String?> isbn13 = const Value.absent(),
    Value<String?> isbn10 = const Value.absent(),
    String? title,
    Value<String?> subtitle = const Value.absent(),
    List<String>? authors,
    Value<String?> publisher = const Value.absent(),
    Value<int?> publishedYear = const Value.absent(),
    Value<int?> pageCount = const Value.absent(),
    Value<BookFormat?> format = const Value.absent(),
    Value<String?> language = const Value.absent(),
    BookStatus? status,
    double? rating,
    Value<int?> locationId = const Value.absent(),
    Value<int?> seriesId = const Value.absent(),
    Value<double?> seriesVolume = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> coverLocalPath = const Value.absent(),
    Value<MetadataSource?> metadataSource = const Value.absent(),
    List<String>? editedFields,
    int? currentPage,
    Value<DateTime?> finishedAt = const Value.absent(),
    bool? isFavorite,
    Value<String?> review = const Value.absent(),
    Value<String?> olid = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<int?> priceCents = const Value.absent(),
    Value<DateTime?> receivedAt = const Value.absent(),
    Value<int?> readingSeconds = const Value.absent(),
    Value<ReceivedAs?> receivedAs = const Value.absent(),
    bool? coverNotFound,
    Value<int?> parentId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Book(
    id: id ?? this.id,
    isbn13: isbn13.present ? isbn13.value : this.isbn13,
    isbn10: isbn10.present ? isbn10.value : this.isbn10,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    authors: authors ?? this.authors,
    publisher: publisher.present ? publisher.value : this.publisher,
    publishedYear: publishedYear.present
        ? publishedYear.value
        : this.publishedYear,
    pageCount: pageCount.present ? pageCount.value : this.pageCount,
    format: format.present ? format.value : this.format,
    language: language.present ? language.value : this.language,
    status: status ?? this.status,
    rating: rating ?? this.rating,
    locationId: locationId.present ? locationId.value : this.locationId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    seriesVolume: seriesVolume.present ? seriesVolume.value : this.seriesVolume,
    description: description.present ? description.value : this.description,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    coverLocalPath: coverLocalPath.present
        ? coverLocalPath.value
        : this.coverLocalPath,
    metadataSource: metadataSource.present
        ? metadataSource.value
        : this.metadataSource,
    editedFields: editedFields ?? this.editedFields,
    currentPage: currentPage ?? this.currentPage,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    review: review.present ? review.value : this.review,
    olid: olid.present ? olid.value : this.olid,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    genre: genre.present ? genre.value : this.genre,
    priceCents: priceCents.present ? priceCents.value : this.priceCents,
    receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
    readingSeconds: readingSeconds.present
        ? readingSeconds.value
        : this.readingSeconds,
    receivedAs: receivedAs.present ? receivedAs.value : this.receivedAs,
    coverNotFound: coverNotFound ?? this.coverNotFound,
    parentId: parentId.present ? parentId.value : this.parentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      isbn13: data.isbn13.present ? data.isbn13.value : this.isbn13,
      isbn10: data.isbn10.present ? data.isbn10.value : this.isbn10,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      authors: data.authors.present ? data.authors.value : this.authors,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      publishedYear: data.publishedYear.present
          ? data.publishedYear.value
          : this.publishedYear,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      format: data.format.present ? data.format.value : this.format,
      language: data.language.present ? data.language.value : this.language,
      status: data.status.present ? data.status.value : this.status,
      rating: data.rating.present ? data.rating.value : this.rating,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seriesVolume: data.seriesVolume.present
          ? data.seriesVolume.value
          : this.seriesVolume,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverLocalPath: data.coverLocalPath.present
          ? data.coverLocalPath.value
          : this.coverLocalPath,
      metadataSource: data.metadataSource.present
          ? data.metadataSource.value
          : this.metadataSource,
      editedFields: data.editedFields.present
          ? data.editedFields.value
          : this.editedFields,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      review: data.review.present ? data.review.value : this.review,
      olid: data.olid.present ? data.olid.value : this.olid,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      genre: data.genre.present ? data.genre.value : this.genre,
      priceCents: data.priceCents.present
          ? data.priceCents.value
          : this.priceCents,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      readingSeconds: data.readingSeconds.present
          ? data.readingSeconds.value
          : this.readingSeconds,
      receivedAs: data.receivedAs.present
          ? data.receivedAs.value
          : this.receivedAs,
      coverNotFound: data.coverNotFound.present
          ? data.coverNotFound.value
          : this.coverNotFound,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('isbn13: $isbn13, ')
          ..write('isbn10: $isbn10, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('authors: $authors, ')
          ..write('publisher: $publisher, ')
          ..write('publishedYear: $publishedYear, ')
          ..write('pageCount: $pageCount, ')
          ..write('format: $format, ')
          ..write('language: $language, ')
          ..write('status: $status, ')
          ..write('rating: $rating, ')
          ..write('locationId: $locationId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seriesVolume: $seriesVolume, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('metadataSource: $metadataSource, ')
          ..write('editedFields: $editedFields, ')
          ..write('currentPage: $currentPage, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('review: $review, ')
          ..write('olid: $olid, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('genre: $genre, ')
          ..write('priceCents: $priceCents, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('receivedAs: $receivedAs, ')
          ..write('coverNotFound: $coverNotFound, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    isbn13,
    isbn10,
    title,
    subtitle,
    authors,
    publisher,
    publishedYear,
    pageCount,
    format,
    language,
    status,
    rating,
    locationId,
    seriesId,
    seriesVolume,
    description,
    coverUrl,
    coverLocalPath,
    metadataSource,
    editedFields,
    currentPage,
    finishedAt,
    isFavorite,
    review,
    olid,
    deletedAt,
    genre,
    priceCents,
    receivedAt,
    readingSeconds,
    receivedAs,
    coverNotFound,
    parentId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.isbn13 == this.isbn13 &&
          other.isbn10 == this.isbn10 &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.authors == this.authors &&
          other.publisher == this.publisher &&
          other.publishedYear == this.publishedYear &&
          other.pageCount == this.pageCount &&
          other.format == this.format &&
          other.language == this.language &&
          other.status == this.status &&
          other.rating == this.rating &&
          other.locationId == this.locationId &&
          other.seriesId == this.seriesId &&
          other.seriesVolume == this.seriesVolume &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverLocalPath == this.coverLocalPath &&
          other.metadataSource == this.metadataSource &&
          other.editedFields == this.editedFields &&
          other.currentPage == this.currentPage &&
          other.finishedAt == this.finishedAt &&
          other.isFavorite == this.isFavorite &&
          other.review == this.review &&
          other.olid == this.olid &&
          other.deletedAt == this.deletedAt &&
          other.genre == this.genre &&
          other.priceCents == this.priceCents &&
          other.receivedAt == this.receivedAt &&
          other.readingSeconds == this.readingSeconds &&
          other.receivedAs == this.receivedAs &&
          other.coverNotFound == this.coverNotFound &&
          other.parentId == this.parentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String?> isbn13;
  final Value<String?> isbn10;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<List<String>> authors;
  final Value<String?> publisher;
  final Value<int?> publishedYear;
  final Value<int?> pageCount;
  final Value<BookFormat?> format;
  final Value<String?> language;
  final Value<BookStatus> status;
  final Value<double> rating;
  final Value<int?> locationId;
  final Value<int?> seriesId;
  final Value<double?> seriesVolume;
  final Value<String?> description;
  final Value<String?> coverUrl;
  final Value<String?> coverLocalPath;
  final Value<MetadataSource?> metadataSource;
  final Value<List<String>> editedFields;
  final Value<int> currentPage;
  final Value<DateTime?> finishedAt;
  final Value<bool> isFavorite;
  final Value<String?> review;
  final Value<String?> olid;
  final Value<DateTime?> deletedAt;
  final Value<String?> genre;
  final Value<int?> priceCents;
  final Value<DateTime?> receivedAt;
  final Value<int?> readingSeconds;
  final Value<ReceivedAs?> receivedAs;
  final Value<bool> coverNotFound;
  final Value<int?> parentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.isbn13 = const Value.absent(),
    this.isbn10 = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.authors = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedYear = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.format = const Value.absent(),
    this.language = const Value.absent(),
    this.status = const Value.absent(),
    this.rating = const Value.absent(),
    this.locationId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seriesVolume = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.metadataSource = const Value.absent(),
    this.editedFields = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.review = const Value.absent(),
    this.olid = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.genre = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.readingSeconds = const Value.absent(),
    this.receivedAs = const Value.absent(),
    this.coverNotFound = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    this.isbn13 = const Value.absent(),
    this.isbn10 = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    required List<String> authors,
    this.publisher = const Value.absent(),
    this.publishedYear = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.format = const Value.absent(),
    this.language = const Value.absent(),
    this.status = const Value.absent(),
    this.rating = const Value.absent(),
    this.locationId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seriesVolume = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.metadataSource = const Value.absent(),
    required List<String> editedFields,
    this.currentPage = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.review = const Value.absent(),
    this.olid = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.genre = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.readingSeconds = const Value.absent(),
    this.receivedAs = const Value.absent(),
    this.coverNotFound = const Value.absent(),
    this.parentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       authors = Value(authors),
       editedFields = Value(editedFields);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? isbn13,
    Expression<String>? isbn10,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? authors,
    Expression<String>? publisher,
    Expression<int>? publishedYear,
    Expression<int>? pageCount,
    Expression<String>? format,
    Expression<String>? language,
    Expression<String>? status,
    Expression<double>? rating,
    Expression<int>? locationId,
    Expression<int>? seriesId,
    Expression<double>? seriesVolume,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverLocalPath,
    Expression<String>? metadataSource,
    Expression<String>? editedFields,
    Expression<int>? currentPage,
    Expression<DateTime>? finishedAt,
    Expression<bool>? isFavorite,
    Expression<String>? review,
    Expression<String>? olid,
    Expression<DateTime>? deletedAt,
    Expression<String>? genre,
    Expression<int>? priceCents,
    Expression<DateTime>? receivedAt,
    Expression<int>? readingSeconds,
    Expression<int>? receivedAs,
    Expression<bool>? coverNotFound,
    Expression<int>? parentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isbn13 != null) 'isbn13': isbn13,
      if (isbn10 != null) 'isbn10': isbn10,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (authors != null) 'authors': authors,
      if (publisher != null) 'publisher': publisher,
      if (publishedYear != null) 'published_year': publishedYear,
      if (pageCount != null) 'page_count': pageCount,
      if (format != null) 'format': format,
      if (language != null) 'language': language,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (locationId != null) 'location_id': locationId,
      if (seriesId != null) 'series_id': seriesId,
      if (seriesVolume != null) 'series_volume': seriesVolume,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverLocalPath != null) 'cover_local_path': coverLocalPath,
      if (metadataSource != null) 'metadata_source': metadataSource,
      if (editedFields != null) 'edited_fields': editedFields,
      if (currentPage != null) 'current_page': currentPage,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (review != null) 'review': review,
      if (olid != null) 'olid': olid,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (genre != null) 'genre': genre,
      if (priceCents != null) 'price_cents': priceCents,
      if (receivedAt != null) 'received_at': receivedAt,
      if (readingSeconds != null) 'reading_seconds': readingSeconds,
      if (receivedAs != null) 'received_as': receivedAs,
      if (coverNotFound != null) 'cover_not_found': coverNotFound,
      if (parentId != null) 'parent_id': parentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<String?>? isbn13,
    Value<String?>? isbn10,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<List<String>>? authors,
    Value<String?>? publisher,
    Value<int?>? publishedYear,
    Value<int?>? pageCount,
    Value<BookFormat?>? format,
    Value<String?>? language,
    Value<BookStatus>? status,
    Value<double>? rating,
    Value<int?>? locationId,
    Value<int?>? seriesId,
    Value<double?>? seriesVolume,
    Value<String?>? description,
    Value<String?>? coverUrl,
    Value<String?>? coverLocalPath,
    Value<MetadataSource?>? metadataSource,
    Value<List<String>>? editedFields,
    Value<int>? currentPage,
    Value<DateTime?>? finishedAt,
    Value<bool>? isFavorite,
    Value<String?>? review,
    Value<String?>? olid,
    Value<DateTime?>? deletedAt,
    Value<String?>? genre,
    Value<int?>? priceCents,
    Value<DateTime?>? receivedAt,
    Value<int?>? readingSeconds,
    Value<ReceivedAs?>? receivedAs,
    Value<bool>? coverNotFound,
    Value<int?>? parentId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      isbn13: isbn13 ?? this.isbn13,
      isbn10: isbn10 ?? this.isbn10,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      publisher: publisher ?? this.publisher,
      publishedYear: publishedYear ?? this.publishedYear,
      pageCount: pageCount ?? this.pageCount,
      format: format ?? this.format,
      language: language ?? this.language,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      locationId: locationId ?? this.locationId,
      seriesId: seriesId ?? this.seriesId,
      seriesVolume: seriesVolume ?? this.seriesVolume,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      metadataSource: metadataSource ?? this.metadataSource,
      editedFields: editedFields ?? this.editedFields,
      currentPage: currentPage ?? this.currentPage,
      finishedAt: finishedAt ?? this.finishedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      review: review ?? this.review,
      olid: olid ?? this.olid,
      deletedAt: deletedAt ?? this.deletedAt,
      genre: genre ?? this.genre,
      priceCents: priceCents ?? this.priceCents,
      receivedAt: receivedAt ?? this.receivedAt,
      readingSeconds: readingSeconds ?? this.readingSeconds,
      receivedAs: receivedAs ?? this.receivedAs,
      coverNotFound: coverNotFound ?? this.coverNotFound,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isbn13.present) {
      map['isbn13'] = Variable<String>(isbn13.value);
    }
    if (isbn10.present) {
      map['isbn10'] = Variable<String>(isbn10.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(
        $BooksTable.$converterauthors.toSql(authors.value),
      );
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (publishedYear.present) {
      map['published_year'] = Variable<int>(publishedYear.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(
        $BooksTable.$converterformatn.toSql(format.value),
      );
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $BooksTable.$converterstatus.toSql(status.value),
      );
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<int>(locationId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seriesVolume.present) {
      map['series_volume'] = Variable<double>(seriesVolume.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverLocalPath.present) {
      map['cover_local_path'] = Variable<String>(coverLocalPath.value);
    }
    if (metadataSource.present) {
      map['metadata_source'] = Variable<String>(
        $BooksTable.$convertermetadataSourcen.toSql(metadataSource.value),
      );
    }
    if (editedFields.present) {
      map['edited_fields'] = Variable<String>(
        $BooksTable.$convertereditedFields.toSql(editedFields.value),
      );
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (review.present) {
      map['review'] = Variable<String>(review.value);
    }
    if (olid.present) {
      map['olid'] = Variable<String>(olid.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (readingSeconds.present) {
      map['reading_seconds'] = Variable<int>(readingSeconds.value);
    }
    if (receivedAs.present) {
      map['received_as'] = Variable<int>(
        $BooksTable.$converterreceivedAsn.toSql(receivedAs.value),
      );
    }
    if (coverNotFound.present) {
      map['cover_not_found'] = Variable<bool>(coverNotFound.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('isbn13: $isbn13, ')
          ..write('isbn10: $isbn10, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('authors: $authors, ')
          ..write('publisher: $publisher, ')
          ..write('publishedYear: $publishedYear, ')
          ..write('pageCount: $pageCount, ')
          ..write('format: $format, ')
          ..write('language: $language, ')
          ..write('status: $status, ')
          ..write('rating: $rating, ')
          ..write('locationId: $locationId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seriesVolume: $seriesVolume, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('metadataSource: $metadataSource, ')
          ..write('editedFields: $editedFields, ')
          ..write('currentPage: $currentPage, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('review: $review, ')
          ..write('olid: $olid, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('genre: $genre, ')
          ..write('priceCents: $priceCents, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readingSeconds: $readingSeconds, ')
          ..write('receivedAs: $receivedAs, ')
          ..write('coverNotFound: $coverNotFound, ')
          ..write('parentId: $parentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LendingTable extends Lending with TableInfo<$LendingTable, LendingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LendingTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _borrowerNameMeta = const VerificationMeta(
    'borrowerName',
  );
  @override
  late final GeneratedColumn<String> borrowerName = GeneratedColumn<String>(
    'borrower_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lentAtMeta = const VerificationMeta('lentAt');
  @override
  late final GeneratedColumn<DateTime> lentAt = GeneratedColumn<DateTime>(
    'lent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedReturnMeta = const VerificationMeta(
    'expectedReturn',
  );
  @override
  late final GeneratedColumn<DateTime> expectedReturn =
      GeneratedColumn<DateTime>(
        'expected_return',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> returnedAt = GeneratedColumn<DateTime>(
    'returned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    borrowerName,
    lentAt,
    expectedReturn,
    returnedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lending';
  @override
  VerificationContext validateIntegrity(
    Insertable<LendingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('borrower_name')) {
      context.handle(
        _borrowerNameMeta,
        borrowerName.isAcceptableOrUnknown(
          data['borrower_name']!,
          _borrowerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_borrowerNameMeta);
    }
    if (data.containsKey('lent_at')) {
      context.handle(
        _lentAtMeta,
        lentAt.isAcceptableOrUnknown(data['lent_at']!, _lentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lentAtMeta);
    }
    if (data.containsKey('expected_return')) {
      context.handle(
        _expectedReturnMeta,
        expectedReturn.isAcceptableOrUnknown(
          data['expected_return']!,
          _expectedReturnMeta,
        ),
      );
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LendingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LendingData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      borrowerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrower_name'],
      )!,
      lentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lent_at'],
      )!,
      expectedReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_return'],
      ),
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}returned_at'],
      ),
    );
  }

  @override
  $LendingTable createAlias(String alias) {
    return $LendingTable(attachedDatabase, alias);
  }
}

class LendingData extends DataClass implements Insertable<LendingData> {
  final int id;
  final int bookId;
  final String borrowerName;
  final DateTime lentAt;
  final DateTime? expectedReturn;
  final DateTime? returnedAt;
  const LendingData({
    required this.id,
    required this.bookId,
    required this.borrowerName,
    required this.lentAt,
    this.expectedReturn,
    this.returnedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['borrower_name'] = Variable<String>(borrowerName);
    map['lent_at'] = Variable<DateTime>(lentAt);
    if (!nullToAbsent || expectedReturn != null) {
      map['expected_return'] = Variable<DateTime>(expectedReturn);
    }
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<DateTime>(returnedAt);
    }
    return map;
  }

  LendingCompanion toCompanion(bool nullToAbsent) {
    return LendingCompanion(
      id: Value(id),
      bookId: Value(bookId),
      borrowerName: Value(borrowerName),
      lentAt: Value(lentAt),
      expectedReturn: expectedReturn == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedReturn),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
    );
  }

  factory LendingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LendingData(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      borrowerName: serializer.fromJson<String>(json['borrowerName']),
      lentAt: serializer.fromJson<DateTime>(json['lentAt']),
      expectedReturn: serializer.fromJson<DateTime?>(json['expectedReturn']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'borrowerName': serializer.toJson<String>(borrowerName),
      'lentAt': serializer.toJson<DateTime>(lentAt),
      'expectedReturn': serializer.toJson<DateTime?>(expectedReturn),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
    };
  }

  LendingData copyWith({
    int? id,
    int? bookId,
    String? borrowerName,
    DateTime? lentAt,
    Value<DateTime?> expectedReturn = const Value.absent(),
    Value<DateTime?> returnedAt = const Value.absent(),
  }) => LendingData(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    borrowerName: borrowerName ?? this.borrowerName,
    lentAt: lentAt ?? this.lentAt,
    expectedReturn: expectedReturn.present
        ? expectedReturn.value
        : this.expectedReturn,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
  );
  LendingData copyWithCompanion(LendingCompanion data) {
    return LendingData(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      borrowerName: data.borrowerName.present
          ? data.borrowerName.value
          : this.borrowerName,
      lentAt: data.lentAt.present ? data.lentAt.value : this.lentAt,
      expectedReturn: data.expectedReturn.present
          ? data.expectedReturn.value
          : this.expectedReturn,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LendingData(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('lentAt: $lentAt, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('returnedAt: $returnedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, borrowerName, lentAt, expectedReturn, returnedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LendingData &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.borrowerName == this.borrowerName &&
          other.lentAt == this.lentAt &&
          other.expectedReturn == this.expectedReturn &&
          other.returnedAt == this.returnedAt);
}

class LendingCompanion extends UpdateCompanion<LendingData> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> borrowerName;
  final Value<DateTime> lentAt;
  final Value<DateTime?> expectedReturn;
  final Value<DateTime?> returnedAt;
  const LendingCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.borrowerName = const Value.absent(),
    this.lentAt = const Value.absent(),
    this.expectedReturn = const Value.absent(),
    this.returnedAt = const Value.absent(),
  });
  LendingCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String borrowerName,
    required DateTime lentAt,
    this.expectedReturn = const Value.absent(),
    this.returnedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       borrowerName = Value(borrowerName),
       lentAt = Value(lentAt);
  static Insertable<LendingData> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? borrowerName,
    Expression<DateTime>? lentAt,
    Expression<DateTime>? expectedReturn,
    Expression<DateTime>? returnedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (borrowerName != null) 'borrower_name': borrowerName,
      if (lentAt != null) 'lent_at': lentAt,
      if (expectedReturn != null) 'expected_return': expectedReturn,
      if (returnedAt != null) 'returned_at': returnedAt,
    });
  }

  LendingCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? borrowerName,
    Value<DateTime>? lentAt,
    Value<DateTime?>? expectedReturn,
    Value<DateTime?>? returnedAt,
  }) {
    return LendingCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      borrowerName: borrowerName ?? this.borrowerName,
      lentAt: lentAt ?? this.lentAt,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      returnedAt: returnedAt ?? this.returnedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (borrowerName.present) {
      map['borrower_name'] = Variable<String>(borrowerName.value);
    }
    if (lentAt.present) {
      map['lent_at'] = Variable<DateTime>(lentAt.value);
    }
    if (expectedReturn.present) {
      map['expected_return'] = Variable<DateTime>(expectedReturn.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LendingCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('lentAt: $lentAt, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('returnedAt: $returnedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endPageMeta = const VerificationMeta(
    'endPage',
  );
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
    'end_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    startedAt,
    endedAt,
    durationSeconds,
    startPage,
    endPage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    }
    if (data.containsKey('end_page')) {
      context.handle(
        _endPageMeta,
        endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      endPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_page'],
      ),
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final int id;
  final int bookId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int startPage;
  final int? endPage;
  const ReadingSession({
    required this.id,
    required this.bookId,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.startPage,
    this.endPage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['start_page'] = Variable<int>(startPage);
    if (!nullToAbsent || endPage != null) {
      map['end_page'] = Variable<int>(endPage);
    }
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: Value(durationSeconds),
      startPage: Value(startPage),
      endPage: endPage == null && nullToAbsent
          ? const Value.absent()
          : Value(endPage),
    );
  }

  factory ReadingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      startPage: serializer.fromJson<int>(json['startPage']),
      endPage: serializer.fromJson<int?>(json['endPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'startPage': serializer.toJson<int>(startPage),
      'endPage': serializer.toJson<int?>(endPage),
    };
  }

  ReadingSession copyWith({
    int? id,
    int? bookId,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? durationSeconds,
    int? startPage,
    Value<int?> endPage = const Value.absent(),
  }) => ReadingSession(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    startPage: startPage ?? this.startPage,
    endPage: endPage.present ? endPage.value : this.endPage,
  );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    startedAt,
    endedAt,
    durationSeconds,
    startPage,
    endPage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> durationSeconds;
  final Value<int> startPage;
  final Value<int?> endPage;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
  }) : bookId = Value(bookId),
       startedAt = Value(startedAt);
  static Insertable<ReadingSession> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<int>? startPage,
    Expression<int>? endPage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? durationSeconds,
    Value<int>? startPage,
    Value<int?>? endPage,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage')
          ..write(')'))
        .toString();
  }
}

class $BookNotesTable extends BookNotes
    with TableInfo<$BookNotesTable, BookNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NoteKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NoteKind>($BookNotesTable.$converterkind);
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    kind,
    content,
    pageNumber,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      kind: $BookNotesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BookNotesTable createAlias(String alias) {
    return $BookNotesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NoteKind, String, String> $converterkind =
      const EnumNameConverter<NoteKind>(NoteKind.values);
}

class BookNote extends DataClass implements Insertable<BookNote> {
  final int id;
  final int bookId;
  final NoteKind kind;
  final String content;
  final int? pageNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BookNote({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.content,
    this.pageNumber,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    {
      map['kind'] = Variable<String>(
        $BookNotesTable.$converterkind.toSql(kind),
      );
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || pageNumber != null) {
      map['page_number'] = Variable<int>(pageNumber);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BookNotesCompanion toCompanion(bool nullToAbsent) {
    return BookNotesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      kind: Value(kind),
      content: Value(content),
      pageNumber: pageNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(pageNumber),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookNote(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      kind: $BookNotesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      content: serializer.fromJson<String>(json['content']),
      pageNumber: serializer.fromJson<int?>(json['pageNumber']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'kind': serializer.toJson<String>(
        $BookNotesTable.$converterkind.toJson(kind),
      ),
      'content': serializer.toJson<String>(content),
      'pageNumber': serializer.toJson<int?>(pageNumber),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BookNote copyWith({
    int? id,
    int? bookId,
    NoteKind? kind,
    String? content,
    Value<int?> pageNumber = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BookNote(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    kind: kind ?? this.kind,
    content: content ?? this.content,
    pageNumber: pageNumber.present ? pageNumber.value : this.pageNumber,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookNote copyWithCompanion(BookNotesCompanion data) {
    return BookNote(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      kind: data.kind.present ? data.kind.value : this.kind,
      content: data.content.present ? data.content.value : this.content,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookNote(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, kind, content, pageNumber, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookNote &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.kind == this.kind &&
          other.content == this.content &&
          other.pageNumber == this.pageNumber &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BookNotesCompanion extends UpdateCompanion<BookNote> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<NoteKind> kind;
  final Value<String> content;
  final Value<int?> pageNumber;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BookNotesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.kind = const Value.absent(),
    this.content = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BookNotesCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required NoteKind kind,
    required String content,
    this.pageNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       kind = Value(kind),
       content = Value(content);
  static Insertable<BookNote> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? kind,
    Expression<String>? content,
    Expression<int>? pageNumber,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (kind != null) 'kind': kind,
      if (content != null) 'content': content,
      if (pageNumber != null) 'page_number': pageNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BookNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<NoteKind>? kind,
    Value<String>? content,
    Value<int?>? pageNumber,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BookNotesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $BookNotesTable.$converterkind.toSql(kind.value),
      );
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookNotesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('kind: $kind, ')
          ..write('content: $content, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), name: Value(name));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({int? id, String? name}) =>
      Tag(id: id ?? this.id, name: name ?? this.name);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> name;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return TagsCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $BookTagsTable extends BookTags with TableInfo<$BookTagsTable, BookTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, tagId};
  @override
  BookTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookTag(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $BookTagsTable createAlias(String alias) {
    return $BookTagsTable(attachedDatabase, alias);
  }
}

class BookTag extends DataClass implements Insertable<BookTag> {
  final int bookId;
  final int tagId;
  const BookTag({required this.bookId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  BookTagsCompanion toCompanion(bool nullToAbsent) {
    return BookTagsCompanion(bookId: Value(bookId), tagId: Value(tagId));
  }

  factory BookTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookTag(
      bookId: serializer.fromJson<int>(json['bookId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  BookTag copyWith({int? bookId, int? tagId}) =>
      BookTag(bookId: bookId ?? this.bookId, tagId: tagId ?? this.tagId);
  BookTag copyWithCompanion(BookTagsCompanion data) {
    return BookTag(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookTag(')
          ..write('bookId: $bookId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookTag &&
          other.bookId == this.bookId &&
          other.tagId == this.tagId);
}

class BookTagsCompanion extends UpdateCompanion<BookTag> {
  final Value<int> bookId;
  final Value<int> tagId;
  final Value<int> rowid;
  const BookTagsCompanion({
    this.bookId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookTagsCompanion.insert({
    required int bookId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       tagId = Value(tagId);
  static Insertable<BookTag> custom({
    Expression<int>? bookId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookTagsCompanion copyWith({
    Value<int>? bookId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return BookTagsCompanion(
      bookId: bookId ?? this.bookId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookTagsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingGoalsTable extends ReadingGoals
    with TableInfo<$ReadingGoalsTable, ReadingGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetBooksMeta = const VerificationMeta(
    'targetBooks',
  );
  @override
  late final GeneratedColumn<int> targetBooks = GeneratedColumn<int>(
    'target_books',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPagesMeta = const VerificationMeta(
    'targetPages',
  );
  @override
  late final GeneratedColumn<int> targetPages = GeneratedColumn<int>(
    'target_pages',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [year, targetBooks, targetPages];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('target_books')) {
      context.handle(
        _targetBooksMeta,
        targetBooks.isAcceptableOrUnknown(
          data['target_books']!,
          _targetBooksMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetBooksMeta);
    }
    if (data.containsKey('target_pages')) {
      context.handle(
        _targetPagesMeta,
        targetPages.isAcceptableOrUnknown(
          data['target_pages']!,
          _targetPagesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year};
  @override
  ReadingGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingGoal(
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      targetBooks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_books'],
      )!,
      targetPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_pages'],
      ),
    );
  }

  @override
  $ReadingGoalsTable createAlias(String alias) {
    return $ReadingGoalsTable(attachedDatabase, alias);
  }
}

class ReadingGoal extends DataClass implements Insertable<ReadingGoal> {
  final int year;
  final int targetBooks;

  /// Optional page goal (Openreads `YearlyChallenge.pages`).
  final int? targetPages;
  const ReadingGoal({
    required this.year,
    required this.targetBooks,
    this.targetPages,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['target_books'] = Variable<int>(targetBooks);
    if (!nullToAbsent || targetPages != null) {
      map['target_pages'] = Variable<int>(targetPages);
    }
    return map;
  }

  ReadingGoalsCompanion toCompanion(bool nullToAbsent) {
    return ReadingGoalsCompanion(
      year: Value(year),
      targetBooks: Value(targetBooks),
      targetPages: targetPages == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPages),
    );
  }

  factory ReadingGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingGoal(
      year: serializer.fromJson<int>(json['year']),
      targetBooks: serializer.fromJson<int>(json['targetBooks']),
      targetPages: serializer.fromJson<int?>(json['targetPages']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'targetBooks': serializer.toJson<int>(targetBooks),
      'targetPages': serializer.toJson<int?>(targetPages),
    };
  }

  ReadingGoal copyWith({
    int? year,
    int? targetBooks,
    Value<int?> targetPages = const Value.absent(),
  }) => ReadingGoal(
    year: year ?? this.year,
    targetBooks: targetBooks ?? this.targetBooks,
    targetPages: targetPages.present ? targetPages.value : this.targetPages,
  );
  ReadingGoal copyWithCompanion(ReadingGoalsCompanion data) {
    return ReadingGoal(
      year: data.year.present ? data.year.value : this.year,
      targetBooks: data.targetBooks.present
          ? data.targetBooks.value
          : this.targetBooks,
      targetPages: data.targetPages.present
          ? data.targetPages.value
          : this.targetPages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingGoal(')
          ..write('year: $year, ')
          ..write('targetBooks: $targetBooks, ')
          ..write('targetPages: $targetPages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(year, targetBooks, targetPages);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingGoal &&
          other.year == this.year &&
          other.targetBooks == this.targetBooks &&
          other.targetPages == this.targetPages);
}

class ReadingGoalsCompanion extends UpdateCompanion<ReadingGoal> {
  final Value<int> year;
  final Value<int> targetBooks;
  final Value<int?> targetPages;
  const ReadingGoalsCompanion({
    this.year = const Value.absent(),
    this.targetBooks = const Value.absent(),
    this.targetPages = const Value.absent(),
  });
  ReadingGoalsCompanion.insert({
    this.year = const Value.absent(),
    required int targetBooks,
    this.targetPages = const Value.absent(),
  }) : targetBooks = Value(targetBooks);
  static Insertable<ReadingGoal> custom({
    Expression<int>? year,
    Expression<int>? targetBooks,
    Expression<int>? targetPages,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (targetBooks != null) 'target_books': targetBooks,
      if (targetPages != null) 'target_pages': targetPages,
    });
  }

  ReadingGoalsCompanion copyWith({
    Value<int>? year,
    Value<int>? targetBooks,
    Value<int?>? targetPages,
  }) {
    return ReadingGoalsCompanion(
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      targetPages: targetPages ?? this.targetPages,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (targetBooks.present) {
      map['target_books'] = Variable<int>(targetBooks.value);
    }
    if (targetPages.present) {
      map['target_pages'] = Variable<int>(targetPages.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingGoalsCompanion(')
          ..write('year: $year, ')
          ..write('targetBooks: $targetBooks, ')
          ..write('targetPages: $targetPages')
          ..write(')'))
        .toString();
  }
}

class $StatTilesTable extends StatTiles
    with TableInfo<$StatTilesTable, StatTile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatTilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionMeta = const VerificationMeta(
    'definition',
  );
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
    'definition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    position,
    title,
    definition,
    pinned,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stat_tiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatTile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('definition')) {
      context.handle(
        _definitionMeta,
        definition.isAcceptableOrUnknown(data['definition']!, _definitionMeta),
      );
    } else if (isInserting) {
      context.missing(_definitionMeta);
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatTile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatTile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      definition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition'],
      )!,
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StatTilesTable createAlias(String alias) {
    return $StatTilesTable(attachedDatabase, alias);
  }
}

class StatTile extends DataClass implements Insertable<StatTile> {
  final int id;

  /// Order on the statistics screen, ascending.
  final int position;
  final String title;

  /// `StatDefinition.toJson()`.
  final String definition;

  /// Shown on the home tab too (at most three, enforced by the repository).
  final bool pinned;
  final DateTime createdAt;
  const StatTile({
    required this.id,
    required this.position,
    required this.title,
    required this.definition,
    required this.pinned,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['position'] = Variable<int>(position);
    map['title'] = Variable<String>(title);
    map['definition'] = Variable<String>(definition);
    map['pinned'] = Variable<bool>(pinned);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StatTilesCompanion toCompanion(bool nullToAbsent) {
    return StatTilesCompanion(
      id: Value(id),
      position: Value(position),
      title: Value(title),
      definition: Value(definition),
      pinned: Value(pinned),
      createdAt: Value(createdAt),
    );
  }

  factory StatTile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatTile(
      id: serializer.fromJson<int>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      title: serializer.fromJson<String>(json['title']),
      definition: serializer.fromJson<String>(json['definition']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'position': serializer.toJson<int>(position),
      'title': serializer.toJson<String>(title),
      'definition': serializer.toJson<String>(definition),
      'pinned': serializer.toJson<bool>(pinned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StatTile copyWith({
    int? id,
    int? position,
    String? title,
    String? definition,
    bool? pinned,
    DateTime? createdAt,
  }) => StatTile(
    id: id ?? this.id,
    position: position ?? this.position,
    title: title ?? this.title,
    definition: definition ?? this.definition,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt ?? this.createdAt,
  );
  StatTile copyWithCompanion(StatTilesCompanion data) {
    return StatTile(
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      title: data.title.present ? data.title.value : this.title,
      definition: data.definition.present
          ? data.definition.value
          : this.definition,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatTile(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('definition: $definition, ')
          ..write('pinned: $pinned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, position, title, definition, pinned, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatTile &&
          other.id == this.id &&
          other.position == this.position &&
          other.title == this.title &&
          other.definition == this.definition &&
          other.pinned == this.pinned &&
          other.createdAt == this.createdAt);
}

class StatTilesCompanion extends UpdateCompanion<StatTile> {
  final Value<int> id;
  final Value<int> position;
  final Value<String> title;
  final Value<String> definition;
  final Value<bool> pinned;
  final Value<DateTime> createdAt;
  const StatTilesCompanion({
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.title = const Value.absent(),
    this.definition = const Value.absent(),
    this.pinned = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StatTilesCompanion.insert({
    this.id = const Value.absent(),
    required int position,
    required String title,
    required String definition,
    this.pinned = const Value.absent(),
    required DateTime createdAt,
  }) : position = Value(position),
       title = Value(title),
       definition = Value(definition),
       createdAt = Value(createdAt);
  static Insertable<StatTile> custom({
    Expression<int>? id,
    Expression<int>? position,
    Expression<String>? title,
    Expression<String>? definition,
    Expression<bool>? pinned,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (title != null) 'title': title,
      if (definition != null) 'definition': definition,
      if (pinned != null) 'pinned': pinned,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StatTilesCompanion copyWith({
    Value<int>? id,
    Value<int>? position,
    Value<String>? title,
    Value<String>? definition,
    Value<bool>? pinned,
    Value<DateTime>? createdAt,
  }) {
    return StatTilesCompanion(
      id: id ?? this.id,
      position: position ?? this.position,
      title: title ?? this.title,
      definition: definition ?? this.definition,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatTilesCompanion(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('definition: $definition, ')
          ..write('pinned: $pinned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocationsTable locations = $LocationsTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $LendingTable lending = $LendingTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $BookNotesTable bookNotes = $BookNotesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $BookTagsTable bookTags = $BookTagsTable(this);
  late final $ReadingGoalsTable readingGoals = $ReadingGoalsTable(this);
  late final $StatTilesTable statTiles = $StatTilesTable(this);
  late final Index idxBooksIsbn10 = Index(
    'idx_books_isbn10',
    'CREATE INDEX idx_books_isbn10 ON books (isbn10)',
  );
  late final Index idxBooksLocation = Index(
    'idx_books_location',
    'CREATE INDEX idx_books_location ON books (location_id)',
  );
  late final Index idxBooksStatus = Index(
    'idx_books_status',
    'CREATE INDEX idx_books_status ON books (status)',
  );
  late final Index idxBooksSeries = Index(
    'idx_books_series',
    'CREATE INDEX idx_books_series ON books (series_id)',
  );
  late final Index idxLendingBook = Index(
    'idx_lending_book',
    'CREATE INDEX idx_lending_book ON lending (book_id)',
  );
  late final Index idxReadingSessionsBook = Index(
    'idx_reading_sessions_book',
    'CREATE INDEX idx_reading_sessions_book ON reading_sessions (book_id)',
  );
  late final Index idxBookNotesBook = Index(
    'idx_book_notes_book',
    'CREATE INDEX idx_book_notes_book ON book_notes (book_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locations,
    seriesTable,
    books,
    lending,
    readingSessions,
    bookNotes,
    tags,
    bookTags,
    readingGoals,
    statTiles,
    idxBooksIsbn10,
    idxBooksLocation,
    idxBooksStatus,
    idxBooksSeries,
    idxLendingBook,
    idxReadingSessionsBook,
    idxBookNotesBook,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'locations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('books', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('books', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('books', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lending', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_notes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocationsTableCreateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      required String name,
      required LocationType type,
      Value<int?> parentId,
      Value<int> sortOrder,
    });
typedef $$LocationsTableUpdateCompanionBuilder =
    LocationsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<LocationType> type,
      Value<int?> parentId,
      Value<int> sortOrder,
    });

final class $$LocationsTableReferences
    extends BaseReferences<_$AppDatabase, $LocationsTable, Location> {
  $$LocationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocationsTable _parentIdTable(_$AppDatabase db) =>
      db.locations.createAlias('locations__parent_id__locations__id');

  $$LocationsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$LocationsTableTableManager(
      $_db,
      $_db.locations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BooksTable, List<Book>> _booksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.books,
    aliasName: 'locations__id__books__location_id',
  );

  $$BooksTableProcessedTableManager get booksRefs {
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.locationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LocationType, LocationType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$LocationsTableFilterComposer get parentId {
    final $$LocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableFilterComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> booksRefs(
    Expression<bool> Function($$BooksTableFilterComposer f) f,
  ) {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocationsTableOrderingComposer get parentId {
    final $$LocationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableOrderingComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationsTable> {
  $$LocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LocationType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$LocationsTableAnnotationComposer get parentId {
    final $$LocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> booksRefs<T extends Object>(
    Expression<T> Function($$BooksTableAnnotationComposer a) f,
  ) {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.locationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationsTable,
          Location,
          $$LocationsTableFilterComposer,
          $$LocationsTableOrderingComposer,
          $$LocationsTableAnnotationComposer,
          $$LocationsTableCreateCompanionBuilder,
          $$LocationsTableUpdateCompanionBuilder,
          (Location, $$LocationsTableReferences),
          Location,
          PrefetchHooks Function({bool parentId, bool booksRefs})
        > {
  $$LocationsTableTableManager(_$AppDatabase db, $LocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<LocationType> type = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => LocationsCompanion(
                id: id,
                name: name,
                type: type,
                parentId: parentId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required LocationType type,
                Value<int?> parentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => LocationsCompanion.insert(
                id: id,
                name: name,
                type: type,
                parentId: parentId,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationsTable, Location>(table),
                  $$LocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, booksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (booksRefs) db.books],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable: $$LocationsTableReferences
                                    ._parentIdTable(db),
                                referencedColumn: $$LocationsTableReferences
                                    ._parentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (booksRefs)
                    await $_getPrefetchedData<Location, $LocationsTable, Book>(
                      currentTable: table,
                      referencedTable: $$LocationsTableReferences
                          ._booksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocationsTableReferences(db, table, p0).booksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.locationId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationsTable,
      Location,
      $$LocationsTableFilterComposer,
      $$LocationsTableOrderingComposer,
      $$LocationsTableAnnotationComposer,
      $$LocationsTableCreateCompanionBuilder,
      $$LocationsTableUpdateCompanionBuilder,
      (Location, $$LocationsTableReferences),
      Location,
      PrefetchHooks Function({bool parentId, bool booksRefs})
    >;
typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> totalPlannedVolumes,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> totalPlannedVolumes,
    });

final class $$SeriesTableTableReferences
    extends BaseReferences<_$AppDatabase, $SeriesTableTable, Series> {
  $$SeriesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BooksTable, List<Book>> _booksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.books,
    aliasName: 'series__id__books__series_id',
  );

  $$BooksTableProcessedTableManager get booksRefs {
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPlannedVolumes => $composableBuilder(
    column: $table.totalPlannedVolumes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> booksRefs(
    Expression<bool> Function($$BooksTableFilterComposer f) f,
  ) {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPlannedVolumes => $composableBuilder(
    column: $table.totalPlannedVolumes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalPlannedVolumes => $composableBuilder(
    column: $table.totalPlannedVolumes,
    builder: (column) => column,
  );

  Expression<T> booksRefs<T extends Object>(
    Expression<T> Function($$BooksTableAnnotationComposer a) f,
  ) {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          Series,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (Series, $$SeriesTableTableReferences),
          Series,
          PrefetchHooks Function({bool booksRefs})
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> totalPlannedVolumes = const Value.absent(),
              }) => SeriesTableCompanion(
                id: id,
                name: name,
                totalPlannedVolumes: totalPlannedVolumes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> totalPlannedVolumes = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                id: id,
                name: name,
                totalPlannedVolumes: totalPlannedVolumes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeriesTableTable, Series>(table),
                  $$SeriesTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({booksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (booksRefs) db.books],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (booksRefs)
                    await $_getPrefetchedData<Series, $SeriesTableTable, Book>(
                      currentTable: table,
                      referencedTable: $$SeriesTableTableReferences
                          ._booksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SeriesTableTableReferences(db, table, p0).booksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.seriesId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      Series,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (Series, $$SeriesTableTableReferences),
      Series,
      PrefetchHooks Function({bool booksRefs})
    >;
typedef $$BooksTableCreateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      Value<String?> isbn13,
      Value<String?> isbn10,
      required String title,
      Value<String?> subtitle,
      required List<String> authors,
      Value<String?> publisher,
      Value<int?> publishedYear,
      Value<int?> pageCount,
      Value<BookFormat?> format,
      Value<String?> language,
      Value<BookStatus> status,
      Value<double> rating,
      Value<int?> locationId,
      Value<int?> seriesId,
      Value<double?> seriesVolume,
      Value<String?> description,
      Value<String?> coverUrl,
      Value<String?> coverLocalPath,
      Value<MetadataSource?> metadataSource,
      required List<String> editedFields,
      Value<int> currentPage,
      Value<DateTime?> finishedAt,
      Value<bool> isFavorite,
      Value<String?> review,
      Value<String?> olid,
      Value<DateTime?> deletedAt,
      Value<String?> genre,
      Value<int?> priceCents,
      Value<DateTime?> receivedAt,
      Value<int?> readingSeconds,
      Value<ReceivedAs?> receivedAs,
      Value<bool> coverNotFound,
      Value<int?> parentId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BooksTableUpdateCompanionBuilder =
    BooksCompanion Function({
      Value<int> id,
      Value<String?> isbn13,
      Value<String?> isbn10,
      Value<String> title,
      Value<String?> subtitle,
      Value<List<String>> authors,
      Value<String?> publisher,
      Value<int?> publishedYear,
      Value<int?> pageCount,
      Value<BookFormat?> format,
      Value<String?> language,
      Value<BookStatus> status,
      Value<double> rating,
      Value<int?> locationId,
      Value<int?> seriesId,
      Value<double?> seriesVolume,
      Value<String?> description,
      Value<String?> coverUrl,
      Value<String?> coverLocalPath,
      Value<MetadataSource?> metadataSource,
      Value<List<String>> editedFields,
      Value<int> currentPage,
      Value<DateTime?> finishedAt,
      Value<bool> isFavorite,
      Value<String?> review,
      Value<String?> olid,
      Value<DateTime?> deletedAt,
      Value<String?> genre,
      Value<int?> priceCents,
      Value<DateTime?> receivedAt,
      Value<int?> readingSeconds,
      Value<ReceivedAs?> receivedAs,
      Value<bool> coverNotFound,
      Value<int?> parentId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocationsTable _locationIdTable(_$AppDatabase db) =>
      db.locations.createAlias('books__location_id__locations__id');

  $$LocationsTableProcessedTableManager? get locationId {
    final $_column = $_itemColumn<int>('location_id');
    if ($_column == null) return null;
    final manager = $$LocationsTableTableManager(
      $_db,
      $_db.locations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_locationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SeriesTableTable _seriesIdTable(_$AppDatabase db) =>
      db.seriesTable.createAlias('books__series_id__series__id');

  $$SeriesTableTableProcessedTableManager? get seriesId {
    final $_column = $_itemColumn<int>('series_id');
    if ($_column == null) return null;
    final manager = $$SeriesTableTableTableManager(
      $_db,
      $_db.seriesTable,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BooksTable _parentIdTable(_$AppDatabase db) =>
      db.books.createAlias('books__parent_id__books__id');

  $$BooksTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LendingTable, List<LendingData>>
  _lendingRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lending,
    aliasName: 'books__id__lending__book_id',
  );

  $$LendingTableProcessedTableManager get lendingRefs {
    final manager = $$LendingTableTableManager(
      $_db,
      $_db.lending,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lendingRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
  _readingSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingSessions,
    aliasName: 'books__id__reading_sessions__book_id',
  );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookNotesTable, List<BookNote>>
  _bookNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookNotes,
    aliasName: 'books__id__book_notes__book_id',
  );

  $$BookNotesTableProcessedTableManager get bookNotesRefs {
    final manager = $$BookNotesTableTableManager(
      $_db,
      $_db.bookNotes,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookNotesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookTagsTable, List<BookTag>> _bookTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bookTags,
    aliasName: 'books__id__book_tags__book_id',
  );

  $$BookTagsTableProcessedTableManager get bookTagsRefs {
    final manager = $$BookTagsTableTableManager(
      $_db,
      $_db.bookTags,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn13 => $composableBuilder(
    column: $table.isbn13,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn10 => $composableBuilder(
    column: $table.isbn10,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publishedYear => $composableBuilder(
    column: $table.publishedYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BookFormat?, BookFormat, String> get format =>
      $composableBuilder(
        column: $table.format,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BookStatus, BookStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get seriesVolume => $composableBuilder(
    column: $table.seriesVolume,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MetadataSource?, MetadataSource, String>
  get metadataSource => $composableBuilder(
    column: $table.metadataSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get editedFields => $composableBuilder(
    column: $table.editedFields,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get olid => $composableBuilder(
    column: $table.olid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReceivedAs?, ReceivedAs, int> get receivedAs =>
      $composableBuilder(
        column: $table.receivedAs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get coverNotFound => $composableBuilder(
    column: $table.coverNotFound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocationsTableFilterComposer get locationId {
    final $$LocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableFilterComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeriesTableTableFilterComposer get seriesId {
    final $$SeriesTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableFilterComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableFilterComposer get parentId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> lendingRefs(
    Expression<bool> Function($$LendingTableFilterComposer f) f,
  ) {
    final $$LendingTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lending,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingTableFilterComposer(
            $db: $db,
            $table: $db.lending,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookNotesRefs(
    Expression<bool> Function($$BookNotesTableFilterComposer f) f,
  ) {
    final $$BookNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNotes,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNotesTableFilterComposer(
            $db: $db,
            $table: $db.bookNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookTagsRefs(
    Expression<bool> Function($$BookTagsTableFilterComposer f) f,
  ) {
    final $$BookTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableFilterComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn13 => $composableBuilder(
    column: $table.isbn13,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn10 => $composableBuilder(
    column: $table.isbn10,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publishedYear => $composableBuilder(
    column: $table.publishedYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get seriesVolume => $composableBuilder(
    column: $table.seriesVolume,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataSource => $composableBuilder(
    column: $table.metadataSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editedFields => $composableBuilder(
    column: $table.editedFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get review => $composableBuilder(
    column: $table.review,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get olid => $composableBuilder(
    column: $table.olid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedAs => $composableBuilder(
    column: $table.receivedAs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get coverNotFound => $composableBuilder(
    column: $table.coverNotFound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocationsTableOrderingComposer get locationId {
    final $$LocationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableOrderingComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeriesTableTableOrderingComposer get seriesId {
    final $$SeriesTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableOrderingComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableOrderingComposer get parentId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get isbn13 =>
      $composableBuilder(column: $table.isbn13, builder: (column) => column);

  GeneratedColumn<String> get isbn10 =>
      $composableBuilder(column: $table.isbn10, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<int> get publishedYear => $composableBuilder(
    column: $table.publishedYear,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BookFormat?, String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BookStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<double> get seriesVolume => $composableBuilder(
    column: $table.seriesVolume,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MetadataSource?, String>
  get metadataSource => $composableBuilder(
    column: $table.metadataSource,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get editedFields =>
      $composableBuilder(
        column: $table.editedFields,
        builder: (column) => column,
      );

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get review =>
      $composableBuilder(column: $table.review, builder: (column) => column);

  GeneratedColumn<String> get olid =>
      $composableBuilder(column: $table.olid, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
    column: $table.priceCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get readingSeconds => $composableBuilder(
    column: $table.readingSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReceivedAs?, int> get receivedAs =>
      $composableBuilder(
        column: $table.receivedAs,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get coverNotFound => $composableBuilder(
    column: $table.coverNotFound,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LocationsTableAnnotationComposer get locationId {
    final $$LocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.locationId,
      referencedTable: $db.locations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.locations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeriesTableTableAnnotationComposer get seriesId {
    final $$SeriesTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.seriesTable,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableTableAnnotationComposer(
            $db: $db,
            $table: $db.seriesTable,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BooksTableAnnotationComposer get parentId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> lendingRefs<T extends Object>(
    Expression<T> Function($$LendingTableAnnotationComposer a) f,
  ) {
    final $$LendingTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lending,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LendingTableAnnotationComposer(
            $db: $db,
            $table: $db.lending,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookNotesRefs<T extends Object>(
    Expression<T> Function($$BookNotesTableAnnotationComposer a) f,
  ) {
    final $$BookNotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookNotes,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookNotesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookTagsRefs<T extends Object>(
    Expression<T> Function($$BookTagsTableAnnotationComposer a) f,
  ) {
    final $$BookTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, $$BooksTableReferences),
          Book,
          PrefetchHooks Function({
            bool locationId,
            bool seriesId,
            bool parentId,
            bool lendingRefs,
            bool readingSessionsRefs,
            bool bookNotesRefs,
            bool bookTagsRefs,
          })
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> isbn13 = const Value.absent(),
                Value<String?> isbn10 = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<List<String>> authors = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<int?> publishedYear = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<BookFormat?> format = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<BookStatus> status = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<double?> seriesVolume = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                Value<MetadataSource?> metadataSource = const Value.absent(),
                Value<List<String>> editedFields = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> review = const Value.absent(),
                Value<String?> olid = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                Value<int?> readingSeconds = const Value.absent(),
                Value<ReceivedAs?> receivedAs = const Value.absent(),
                Value<bool> coverNotFound = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                isbn13: isbn13,
                isbn10: isbn10,
                title: title,
                subtitle: subtitle,
                authors: authors,
                publisher: publisher,
                publishedYear: publishedYear,
                pageCount: pageCount,
                format: format,
                language: language,
                status: status,
                rating: rating,
                locationId: locationId,
                seriesId: seriesId,
                seriesVolume: seriesVolume,
                description: description,
                coverUrl: coverUrl,
                coverLocalPath: coverLocalPath,
                metadataSource: metadataSource,
                editedFields: editedFields,
                currentPage: currentPage,
                finishedAt: finishedAt,
                isFavorite: isFavorite,
                review: review,
                olid: olid,
                deletedAt: deletedAt,
                genre: genre,
                priceCents: priceCents,
                receivedAt: receivedAt,
                readingSeconds: readingSeconds,
                receivedAs: receivedAs,
                coverNotFound: coverNotFound,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> isbn13 = const Value.absent(),
                Value<String?> isbn10 = const Value.absent(),
                required String title,
                Value<String?> subtitle = const Value.absent(),
                required List<String> authors,
                Value<String?> publisher = const Value.absent(),
                Value<int?> publishedYear = const Value.absent(),
                Value<int?> pageCount = const Value.absent(),
                Value<BookFormat?> format = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<BookStatus> status = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int?> locationId = const Value.absent(),
                Value<int?> seriesId = const Value.absent(),
                Value<double?> seriesVolume = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                Value<MetadataSource?> metadataSource = const Value.absent(),
                required List<String> editedFields,
                Value<int> currentPage = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> review = const Value.absent(),
                Value<String?> olid = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<int?> priceCents = const Value.absent(),
                Value<DateTime?> receivedAt = const Value.absent(),
                Value<int?> readingSeconds = const Value.absent(),
                Value<ReceivedAs?> receivedAs = const Value.absent(),
                Value<bool> coverNotFound = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                isbn13: isbn13,
                isbn10: isbn10,
                title: title,
                subtitle: subtitle,
                authors: authors,
                publisher: publisher,
                publishedYear: publishedYear,
                pageCount: pageCount,
                format: format,
                language: language,
                status: status,
                rating: rating,
                locationId: locationId,
                seriesId: seriesId,
                seriesVolume: seriesVolume,
                description: description,
                coverUrl: coverUrl,
                coverLocalPath: coverLocalPath,
                metadataSource: metadataSource,
                editedFields: editedFields,
                currentPage: currentPage,
                finishedAt: finishedAt,
                isFavorite: isFavorite,
                review: review,
                olid: olid,
                deletedAt: deletedAt,
                genre: genre,
                priceCents: priceCents,
                receivedAt: receivedAt,
                readingSeconds: readingSeconds,
                receivedAs: receivedAs,
                coverNotFound: coverNotFound,
                parentId: parentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  $$BooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                locationId = false,
                seriesId = false,
                parentId = false,
                lendingRefs = false,
                readingSessionsRefs = false,
                bookNotesRefs = false,
                bookTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lendingRefs) db.lending,
                    if (readingSessionsRefs) db.readingSessions,
                    if (bookNotesRefs) db.bookNotes,
                    if (bookTagsRefs) db.bookTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (locationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.locationId,
                                    referencedTable: $$BooksTableReferences
                                        ._locationIdTable(db),
                                    referencedColumn: $$BooksTableReferences
                                        ._locationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (seriesId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.seriesId,
                                    referencedTable: $$BooksTableReferences
                                        ._seriesIdTable(db),
                                    referencedColumn: $$BooksTableReferences
                                        ._seriesIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$BooksTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn: $$BooksTableReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lendingRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          LendingData
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._lendingRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(db, table, p0).lendingRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          Book,
                          $BooksTable,
                          ReadingSession
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookNotesRefs)
                        await $_getPrefetchedData<Book, $BooksTable, BookNote>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookNotesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookNotesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookTagsRefs)
                        await $_getPrefetchedData<Book, $BooksTable, BookTag>(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, $$BooksTableReferences),
      Book,
      PrefetchHooks Function({
        bool locationId,
        bool seriesId,
        bool parentId,
        bool lendingRefs,
        bool readingSessionsRefs,
        bool bookNotesRefs,
        bool bookTagsRefs,
      })
    >;
typedef $$LendingTableCreateCompanionBuilder =
    LendingCompanion Function({
      Value<int> id,
      required int bookId,
      required String borrowerName,
      required DateTime lentAt,
      Value<DateTime?> expectedReturn,
      Value<DateTime?> returnedAt,
    });
typedef $$LendingTableUpdateCompanionBuilder =
    LendingCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<String> borrowerName,
      Value<DateTime> lentAt,
      Value<DateTime?> expectedReturn,
      Value<DateTime?> returnedAt,
    });

final class $$LendingTableReferences
    extends BaseReferences<_$AppDatabase, $LendingTable, LendingData> {
  $$LendingTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('lending__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LendingTableFilterComposer
    extends Composer<_$AppDatabase, $LendingTable> {
  $$LendingTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lentAt => $composableBuilder(
    column: $table.lentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingTableOrderingComposer
    extends Composer<_$AppDatabase, $LendingTable> {
  $$LendingTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lentAt => $composableBuilder(
    column: $table.lentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingTableAnnotationComposer
    extends Composer<_$AppDatabase, $LendingTable> {
  $$LendingTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lentAt =>
      $composableBuilder(column: $table.lentAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LendingTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LendingTable,
          LendingData,
          $$LendingTableFilterComposer,
          $$LendingTableOrderingComposer,
          $$LendingTableAnnotationComposer,
          $$LendingTableCreateCompanionBuilder,
          $$LendingTableUpdateCompanionBuilder,
          (LendingData, $$LendingTableReferences),
          LendingData,
          PrefetchHooks Function({bool bookId})
        > {
  $$LendingTableTableManager(_$AppDatabase db, $LendingTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LendingTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LendingTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LendingTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> borrowerName = const Value.absent(),
                Value<DateTime> lentAt = const Value.absent(),
                Value<DateTime?> expectedReturn = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
              }) => LendingCompanion(
                id: id,
                bookId: bookId,
                borrowerName: borrowerName,
                lentAt: lentAt,
                expectedReturn: expectedReturn,
                returnedAt: returnedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String borrowerName,
                required DateTime lentAt,
                Value<DateTime?> expectedReturn = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
              }) => LendingCompanion.insert(
                id: id,
                bookId: bookId,
                borrowerName: borrowerName,
                lentAt: lentAt,
                expectedReturn: expectedReturn,
                returnedAt: returnedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LendingTable, LendingData>(table),
                  $$LendingTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$LendingTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$LendingTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LendingTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LendingTable,
      LendingData,
      $$LendingTableFilterComposer,
      $$LendingTableOrderingComposer,
      $$LendingTableAnnotationComposer,
      $$LendingTableCreateCompanionBuilder,
      $$LendingTableUpdateCompanionBuilder,
      (LendingData, $$LendingTableReferences),
      LendingData,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      required int bookId,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationSeconds,
      Value<int> startPage,
      Value<int?> endPage,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationSeconds,
      Value<int> startPage,
      Value<int?> endPage,
    });

final class $$ReadingSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSession> {
  $$ReadingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('reading_sessions__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSessionsTable,
          ReadingSession,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (ReadingSession, $$ReadingSessionsTableReferences),
          ReadingSession,
          PrefetchHooks Function({bool bookId})
        > {
  $$ReadingSessionsTableTableManager(
    _$AppDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int?> endPage = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                bookId: bookId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                startPage: startPage,
                endPage: endPage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int?> endPage = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                bookId: bookId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                startPage: startPage,
                endPage: endPage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingSessionsTable, ReadingSession>(table),
                  $$ReadingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable:
                                    $$ReadingSessionsTableReferences
                                        ._bookIdTable(db),
                                referencedColumn:
                                    $$ReadingSessionsTableReferences
                                        ._bookIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSessionsTable,
      ReadingSession,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (ReadingSession, $$ReadingSessionsTableReferences),
      ReadingSession,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$BookNotesTableCreateCompanionBuilder =
    BookNotesCompanion Function({
      Value<int> id,
      required int bookId,
      required NoteKind kind,
      required String content,
      Value<int?> pageNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BookNotesTableUpdateCompanionBuilder =
    BookNotesCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<NoteKind> kind,
      Value<String> content,
      Value<int?> pageNumber,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BookNotesTableReferences
    extends BaseReferences<_$AppDatabase, $BookNotesTable, BookNote> {
  $$BookNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('book_notes__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookNotesTableFilterComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NoteKind, NoteKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookNotesTable,
          BookNote,
          $$BookNotesTableFilterComposer,
          $$BookNotesTableOrderingComposer,
          $$BookNotesTableAnnotationComposer,
          $$BookNotesTableCreateCompanionBuilder,
          $$BookNotesTableUpdateCompanionBuilder,
          (BookNote, $$BookNotesTableReferences),
          BookNote,
          PrefetchHooks Function({bool bookId})
        > {
  $$BookNotesTableTableManager(_$AppDatabase db, $BookNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<NoteKind> kind = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int?> pageNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BookNotesCompanion(
                id: id,
                bookId: bookId,
                kind: kind,
                content: content,
                pageNumber: pageNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required NoteKind kind,
                required String content,
                Value<int?> pageNumber = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BookNotesCompanion.insert(
                id: id,
                bookId: bookId,
                kind: kind,
                content: content,
                pageNumber: pageNumber,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookNotesTable, BookNote>(table),
                  $$BookNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$BookNotesTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$BookNotesTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookNotesTable,
      BookNote,
      $$BookNotesTableFilterComposer,
      $$BookNotesTableOrderingComposer,
      $$BookNotesTableAnnotationComposer,
      $$BookNotesTableCreateCompanionBuilder,
      $$BookNotesTableUpdateCompanionBuilder,
      (BookNote, $$BookNotesTableReferences),
      BookNote,
      PrefetchHooks Function({bool bookId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({Value<int> id, required String name});
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({Value<int> id, Value<String> name});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookTagsTable, List<BookTag>> _bookTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bookTags,
    aliasName: 'tags__id__book_tags__tag_id',
  );

  $$BookTagsTableProcessedTableManager get bookTagsRefs {
    final manager = $$BookTagsTableTableManager(
      $_db,
      $_db.bookTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookTagsRefs(
    Expression<bool> Function($$BookTagsTableFilterComposer f) f,
  ) {
    final $$BookTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableFilterComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> bookTagsRefs<T extends Object>(
    Expression<T> Function($$BookTagsTableAnnotationComposer a) f,
  ) {
    final $$BookTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.bookTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool bookTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
              }) => TagsCompanion(id: id, name: name),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String name}) =>
                  TagsCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (bookTagsRefs) db.bookTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, BookTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._bookTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).bookTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool bookTagsRefs})
    >;
typedef $$BookTagsTableCreateCompanionBuilder =
    BookTagsCompanion Function({
      required int bookId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$BookTagsTableUpdateCompanionBuilder =
    BookTagsCompanion Function({
      Value<int> bookId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$BookTagsTableReferences
    extends BaseReferences<_$AppDatabase, $BookTagsTable, BookTag> {
  $$BookTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('book_tags__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('book_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookTagsTableFilterComposer
    extends Composer<_$AppDatabase, $BookTagsTable> {
  $$BookTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookTagsTable> {
  $$BookTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookTagsTable> {
  $$BookTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookTagsTable,
          BookTag,
          $$BookTagsTableFilterComposer,
          $$BookTagsTableOrderingComposer,
          $$BookTagsTableAnnotationComposer,
          $$BookTagsTableCreateCompanionBuilder,
          $$BookTagsTableUpdateCompanionBuilder,
          (BookTag, $$BookTagsTableReferences),
          BookTag,
          PrefetchHooks Function({bool bookId, bool tagId})
        > {
  $$BookTagsTableTableManager(_$AppDatabase db, $BookTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  BookTagsCompanion(bookId: bookId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required int bookId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => BookTagsCompanion.insert(
                bookId: bookId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookTagsTable, BookTag>(table),
                  $$BookTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$BookTagsTableReferences
                                    ._bookIdTable(db),
                                referencedColumn: $$BookTagsTableReferences
                                    ._bookIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$BookTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$BookTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookTagsTable,
      BookTag,
      $$BookTagsTableFilterComposer,
      $$BookTagsTableOrderingComposer,
      $$BookTagsTableAnnotationComposer,
      $$BookTagsTableCreateCompanionBuilder,
      $$BookTagsTableUpdateCompanionBuilder,
      (BookTag, $$BookTagsTableReferences),
      BookTag,
      PrefetchHooks Function({bool bookId, bool tagId})
    >;
typedef $$ReadingGoalsTableCreateCompanionBuilder =
    ReadingGoalsCompanion Function({
      Value<int> year,
      required int targetBooks,
      Value<int?> targetPages,
    });
typedef $$ReadingGoalsTableUpdateCompanionBuilder =
    ReadingGoalsCompanion Function({
      Value<int> year,
      Value<int> targetBooks,
      Value<int?> targetPages,
    });

class $$ReadingGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingGoalsTable> {
  $$ReadingGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetBooks => $composableBuilder(
    column: $table.targetBooks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetPages => $composableBuilder(
    column: $table.targetPages,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingGoalsTable> {
  $$ReadingGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetBooks => $composableBuilder(
    column: $table.targetBooks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetPages => $composableBuilder(
    column: $table.targetPages,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingGoalsTable> {
  $$ReadingGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get targetBooks => $composableBuilder(
    column: $table.targetBooks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetPages => $composableBuilder(
    column: $table.targetPages,
    builder: (column) => column,
  );
}

class $$ReadingGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingGoalsTable,
          ReadingGoal,
          $$ReadingGoalsTableFilterComposer,
          $$ReadingGoalsTableOrderingComposer,
          $$ReadingGoalsTableAnnotationComposer,
          $$ReadingGoalsTableCreateCompanionBuilder,
          $$ReadingGoalsTableUpdateCompanionBuilder,
          (
            ReadingGoal,
            BaseReferences<_$AppDatabase, $ReadingGoalsTable, ReadingGoal>,
          ),
          ReadingGoal,
          PrefetchHooks Function()
        > {
  $$ReadingGoalsTableTableManager(_$AppDatabase db, $ReadingGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<int> targetBooks = const Value.absent(),
                Value<int?> targetPages = const Value.absent(),
              }) => ReadingGoalsCompanion(
                year: year,
                targetBooks: targetBooks,
                targetPages: targetPages,
              ),
          createCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                required int targetBooks,
                Value<int?> targetPages = const Value.absent(),
              }) => ReadingGoalsCompanion.insert(
                year: year,
                targetBooks: targetBooks,
                targetPages: targetPages,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingGoalsTable, ReadingGoal>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadingGoalsTable,
                    ReadingGoal
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingGoalsTable,
      ReadingGoal,
      $$ReadingGoalsTableFilterComposer,
      $$ReadingGoalsTableOrderingComposer,
      $$ReadingGoalsTableAnnotationComposer,
      $$ReadingGoalsTableCreateCompanionBuilder,
      $$ReadingGoalsTableUpdateCompanionBuilder,
      (
        ReadingGoal,
        BaseReferences<_$AppDatabase, $ReadingGoalsTable, ReadingGoal>,
      ),
      ReadingGoal,
      PrefetchHooks Function()
    >;
typedef $$StatTilesTableCreateCompanionBuilder =
    StatTilesCompanion Function({
      Value<int> id,
      required int position,
      required String title,
      required String definition,
      Value<bool> pinned,
      required DateTime createdAt,
    });
typedef $$StatTilesTableUpdateCompanionBuilder =
    StatTilesCompanion Function({
      Value<int> id,
      Value<int> position,
      Value<String> title,
      Value<String> definition,
      Value<bool> pinned,
      Value<DateTime> createdAt,
    });

class $$StatTilesTableFilterComposer
    extends Composer<_$AppDatabase, $StatTilesTable> {
  $$StatTilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StatTilesTableOrderingComposer
    extends Composer<_$AppDatabase, $StatTilesTable> {
  $$StatTilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StatTilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatTilesTable> {
  $$StatTilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StatTilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatTilesTable,
          StatTile,
          $$StatTilesTableFilterComposer,
          $$StatTilesTableOrderingComposer,
          $$StatTilesTableAnnotationComposer,
          $$StatTilesTableCreateCompanionBuilder,
          $$StatTilesTableUpdateCompanionBuilder,
          (StatTile, BaseReferences<_$AppDatabase, $StatTilesTable, StatTile>),
          StatTile,
          PrefetchHooks Function()
        > {
  $$StatTilesTableTableManager(_$AppDatabase db, $StatTilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatTilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatTilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatTilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> definition = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StatTilesCompanion(
                id: id,
                position: position,
                title: title,
                definition: definition,
                pinned: pinned,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int position,
                required String title,
                required String definition,
                Value<bool> pinned = const Value.absent(),
                required DateTime createdAt,
              }) => StatTilesCompanion.insert(
                id: id,
                position: position,
                title: title,
                definition: definition,
                pinned: pinned,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StatTilesTable, StatTile>(table),
                  BaseReferences<_$AppDatabase, $StatTilesTable, StatTile>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StatTilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatTilesTable,
      StatTile,
      $$StatTilesTableFilterComposer,
      $$StatTilesTableOrderingComposer,
      $$StatTilesTableAnnotationComposer,
      $$StatTilesTableCreateCompanionBuilder,
      $$StatTilesTableUpdateCompanionBuilder,
      (StatTile, BaseReferences<_$AppDatabase, $StatTilesTable, StatTile>),
      StatTile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocationsTableTableManager get locations =>
      $$LocationsTableTableManager(_db, _db.locations);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$LendingTableTableManager get lending =>
      $$LendingTableTableManager(_db, _db.lending);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$BookNotesTableTableManager get bookNotes =>
      $$BookNotesTableTableManager(_db, _db.bookNotes);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$BookTagsTableTableManager get bookTags =>
      $$BookTagsTableTableManager(_db, _db.bookTags);
  $$ReadingGoalsTableTableManager get readingGoals =>
      $$ReadingGoalsTableTableManager(_db, _db.readingGoals);
  $$StatTilesTableTableManager get statTiles =>
      $$StatTilesTableTableManager(_db, _db.statTiles);
}
