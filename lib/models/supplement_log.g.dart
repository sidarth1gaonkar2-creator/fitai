// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplement_log.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSupplementLogCollection on Isar {
  IsarCollection<SupplementLog> get supplementLogs => this.collection();
}

const SupplementLogSchema = CollectionSchema(
  name: r'SupplementLog',
  id: 874971769020898985,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'supplementId': PropertySchema(
      id: 1,
      name: r'supplementId',
      type: IsarType.long,
    ),
    r'taken': PropertySchema(
      id: 2,
      name: r'taken',
      type: IsarType.bool,
    ),
    r'timeTaken': PropertySchema(
      id: 3,
      name: r'timeTaken',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _supplementLogEstimateSize,
  serialize: _supplementLogSerialize,
  deserialize: _supplementLogDeserialize,
  deserializeProp: _supplementLogDeserializeProp,
  idName: r'id',
  indexes: {
    r'supplementId': IndexSchema(
      id: 4275019576947099120,
      name: r'supplementId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'supplementId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _supplementLogGetId,
  getLinks: _supplementLogGetLinks,
  attach: _supplementLogAttach,
  version: '3.1.0+1',
);

int _supplementLogEstimateSize(
  SupplementLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _supplementLogSerialize(
  SupplementLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.supplementId);
  writer.writeBool(offsets[2], object.taken);
  writer.writeDateTime(offsets[3], object.timeTaken);
}

SupplementLog _supplementLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SupplementLog();
  object.date = reader.readDateTime(offsets[0]);
  object.id = id;
  object.supplementId = reader.readLong(offsets[1]);
  object.taken = reader.readBool(offsets[2]);
  object.timeTaken = reader.readDateTimeOrNull(offsets[3]);
  return object;
}

P _supplementLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _supplementLogGetId(SupplementLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _supplementLogGetLinks(SupplementLog object) {
  return [];
}

void _supplementLogAttach(
    IsarCollection<dynamic> col, Id id, SupplementLog object) {
  object.id = id;
}

extension SupplementLogQueryWhereSort
    on QueryBuilder<SupplementLog, SupplementLog, QWhere> {
  QueryBuilder<SupplementLog, SupplementLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhere> anySupplementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'supplementId'),
      );
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension SupplementLogQueryWhere
    on QueryBuilder<SupplementLog, SupplementLog, QWhereClause> {
  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause>
      supplementIdEqualTo(int supplementId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'supplementId',
        value: [supplementId],
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause>
      supplementIdNotEqualTo(int supplementId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplementId',
              lower: [],
              upper: [supplementId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplementId',
              lower: [supplementId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplementId',
              lower: [supplementId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'supplementId',
              lower: [],
              upper: [supplementId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause>
      supplementIdGreaterThan(
    int supplementId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'supplementId',
        lower: [supplementId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause>
      supplementIdLessThan(
    int supplementId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'supplementId',
        lower: [],
        upper: [supplementId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause>
      supplementIdBetween(
    int lowerSupplementId,
    int upperSupplementId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'supplementId',
        lower: [lowerSupplementId],
        includeLower: includeLower,
        upper: [upperSupplementId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> dateNotEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SupplementLogQueryFilter
    on QueryBuilder<SupplementLog, SupplementLog, QFilterCondition> {
  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      supplementIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supplementId',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      supplementIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supplementId',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      supplementIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supplementId',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      supplementIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supplementId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      takenEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taken',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'timeTaken',
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'timeTaken',
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timeTaken',
        value: value,
      ));
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterFilterCondition>
      timeTakenBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timeTaken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SupplementLogQueryObject
    on QueryBuilder<SupplementLog, SupplementLog, QFilterCondition> {}

extension SupplementLogQueryLinks
    on QueryBuilder<SupplementLog, SupplementLog, QFilterCondition> {}

extension SupplementLogQuerySortBy
    on QueryBuilder<SupplementLog, SupplementLog, QSortBy> {
  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      sortBySupplementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplementId', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      sortBySupplementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplementId', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> sortByTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taken', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> sortByTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taken', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> sortByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      sortByTimeTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.desc);
    });
  }
}

extension SupplementLogQuerySortThenBy
    on QueryBuilder<SupplementLog, SupplementLog, QSortThenBy> {
  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      thenBySupplementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplementId', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      thenBySupplementIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'supplementId', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taken', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taken', Sort.desc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy> thenByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.asc);
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QAfterSortBy>
      thenByTimeTakenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timeTaken', Sort.desc);
    });
  }
}

extension SupplementLogQueryWhereDistinct
    on QueryBuilder<SupplementLog, SupplementLog, QDistinct> {
  QueryBuilder<SupplementLog, SupplementLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QDistinct>
      distinctBySupplementId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supplementId');
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QDistinct> distinctByTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taken');
    });
  }

  QueryBuilder<SupplementLog, SupplementLog, QDistinct> distinctByTimeTaken() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timeTaken');
    });
  }
}

extension SupplementLogQueryProperty
    on QueryBuilder<SupplementLog, SupplementLog, QQueryProperty> {
  QueryBuilder<SupplementLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SupplementLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<SupplementLog, int, QQueryOperations> supplementIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supplementId');
    });
  }

  QueryBuilder<SupplementLog, bool, QQueryOperations> takenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taken');
    });
  }

  QueryBuilder<SupplementLog, DateTime?, QQueryOperations> timeTakenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timeTaken');
    });
  }
}
