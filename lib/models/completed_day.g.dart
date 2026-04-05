// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'completed_day.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCompletedDayCollection on Isar {
  IsarCollection<CompletedDay> get completedDays => this.collection();
}

const CompletedDaySchema = CollectionSchema(
  name: r'CompletedDay',
  id: -4712079808047504299,
  properties: {
    r'calorieTarget': PropertySchema(
      id: 0,
      name: r'calorieTarget',
      type: IsarType.double,
    ),
    r'caloriesConsumed': PropertySchema(
      id: 1,
      name: r'caloriesConsumed',
      type: IsarType.double,
    ),
    r'carbsConsumed': PropertySchema(
      id: 2,
      name: r'carbsConsumed',
      type: IsarType.double,
    ),
    r'carbsTarget': PropertySchema(
      id: 3,
      name: r'carbsTarget',
      type: IsarType.double,
    ),
    r'completedAt': PropertySchema(
      id: 4,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(
      id: 5,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'fatConsumed': PropertySchema(
      id: 6,
      name: r'fatConsumed',
      type: IsarType.double,
    ),
    r'fatTarget': PropertySchema(
      id: 7,
      name: r'fatTarget',
      type: IsarType.double,
    ),
    r'macrosHit': PropertySchema(
      id: 8,
      name: r'macrosHit',
      type: IsarType.bool,
    ),
    r'proteinConsumed': PropertySchema(
      id: 9,
      name: r'proteinConsumed',
      type: IsarType.double,
    ),
    r'proteinTarget': PropertySchema(
      id: 10,
      name: r'proteinTarget',
      type: IsarType.double,
    )
  },
  estimateSize: _completedDayEstimateSize,
  serialize: _completedDaySerialize,
  deserialize: _completedDayDeserialize,
  deserializeProp: _completedDayDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
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
  getId: _completedDayGetId,
  getLinks: _completedDayGetLinks,
  attach: _completedDayAttach,
  version: '3.1.0+1',
);

int _completedDayEstimateSize(
  CompletedDay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _completedDaySerialize(
  CompletedDay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.calorieTarget);
  writer.writeDouble(offsets[1], object.caloriesConsumed);
  writer.writeDouble(offsets[2], object.carbsConsumed);
  writer.writeDouble(offsets[3], object.carbsTarget);
  writer.writeDateTime(offsets[4], object.completedAt);
  writer.writeDateTime(offsets[5], object.date);
  writer.writeDouble(offsets[6], object.fatConsumed);
  writer.writeDouble(offsets[7], object.fatTarget);
  writer.writeBool(offsets[8], object.macrosHit);
  writer.writeDouble(offsets[9], object.proteinConsumed);
  writer.writeDouble(offsets[10], object.proteinTarget);
}

CompletedDay _completedDayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CompletedDay();
  object.calorieTarget = reader.readDouble(offsets[0]);
  object.caloriesConsumed = reader.readDouble(offsets[1]);
  object.carbsConsumed = reader.readDouble(offsets[2]);
  object.carbsTarget = reader.readDouble(offsets[3]);
  object.completedAt = reader.readDateTime(offsets[4]);
  object.date = reader.readDateTime(offsets[5]);
  object.fatConsumed = reader.readDouble(offsets[6]);
  object.fatTarget = reader.readDouble(offsets[7]);
  object.id = id;
  object.macrosHit = reader.readBool(offsets[8]);
  object.proteinConsumed = reader.readDouble(offsets[9]);
  object.proteinTarget = reader.readDouble(offsets[10]);
  return object;
}

P _completedDayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _completedDayGetId(CompletedDay object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _completedDayGetLinks(CompletedDay object) {
  return [];
}

void _completedDayAttach(
    IsarCollection<dynamic> col, Id id, CompletedDay object) {
  object.id = id;
}

extension CompletedDayByIndex on IsarCollection<CompletedDay> {
  Future<CompletedDay?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  CompletedDay? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<CompletedDay?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<CompletedDay?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(CompletedDay object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(CompletedDay object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<CompletedDay> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<CompletedDay> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension CompletedDayQueryWhereSort
    on QueryBuilder<CompletedDay, CompletedDay, QWhere> {
  QueryBuilder<CompletedDay, CompletedDay, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension CompletedDayQueryWhere
    on QueryBuilder<CompletedDay, CompletedDay, QWhereClause> {
  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> idBetween(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> dateNotEqualTo(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> dateGreaterThan(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> dateLessThan(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterWhereClause> dateBetween(
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

extension CompletedDayQueryFilter
    on QueryBuilder<CompletedDay, CompletedDay, QFilterCondition> {
  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      calorieTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calorieTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      calorieTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calorieTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      calorieTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calorieTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      calorieTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calorieTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      caloriesConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      caloriesConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      caloriesConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      caloriesConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbsTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      carbsTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbsTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      completedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      completedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      completedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'completedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      completedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'completedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> dateLessThan(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> dateBetween(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fatTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fatTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fatTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      fatTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fatTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      macrosHitEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'macrosHit',
        value: value,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinConsumedEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinConsumedGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinConsumedLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinConsumedBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinTargetEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'proteinTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinTargetGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'proteinTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinTargetLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'proteinTarget',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterFilterCondition>
      proteinTargetBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'proteinTarget',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CompletedDayQueryObject
    on QueryBuilder<CompletedDay, CompletedDay, QFilterCondition> {}

extension CompletedDayQueryLinks
    on QueryBuilder<CompletedDay, CompletedDay, QFilterCondition> {}

extension CompletedDayQuerySortBy
    on QueryBuilder<CompletedDay, CompletedDay, QSortBy> {
  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCaloriesConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCarbsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByCarbsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCarbsTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByFatConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByFatTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByMacrosHit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macrosHit', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByMacrosHitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macrosHit', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByProteinConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> sortByProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      sortByProteinTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTarget', Sort.desc);
    });
  }
}

extension CompletedDayQuerySortThenBy
    on QueryBuilder<CompletedDay, CompletedDay, QSortThenBy> {
  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCalorieTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calorieTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCaloriesConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCarbsConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByCarbsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCarbsTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbsTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByFatConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByFatTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fatTarget', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByMacrosHit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macrosHit', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByMacrosHitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'macrosHit', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByProteinConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinConsumed', Sort.desc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy> thenByProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTarget', Sort.asc);
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QAfterSortBy>
      thenByProteinTargetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'proteinTarget', Sort.desc);
    });
  }
}

extension CompletedDayQueryWhereDistinct
    on QueryBuilder<CompletedDay, CompletedDay, QDistinct> {
  QueryBuilder<CompletedDay, CompletedDay, QDistinct>
      distinctByCalorieTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calorieTarget');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct>
      distinctByCaloriesConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesConsumed');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct>
      distinctByCarbsConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsConsumed');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByCarbsTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbsTarget');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByFatConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatConsumed');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByFatTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fatTarget');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct> distinctByMacrosHit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'macrosHit');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct>
      distinctByProteinConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinConsumed');
    });
  }

  QueryBuilder<CompletedDay, CompletedDay, QDistinct>
      distinctByProteinTarget() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'proteinTarget');
    });
  }
}

extension CompletedDayQueryProperty
    on QueryBuilder<CompletedDay, CompletedDay, QQueryProperty> {
  QueryBuilder<CompletedDay, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> calorieTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calorieTarget');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations>
      caloriesConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesConsumed');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> carbsConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsConsumed');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> carbsTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbsTarget');
    });
  }

  QueryBuilder<CompletedDay, DateTime, QQueryOperations> completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<CompletedDay, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> fatConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatConsumed');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> fatTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fatTarget');
    });
  }

  QueryBuilder<CompletedDay, bool, QQueryOperations> macrosHitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'macrosHit');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations>
      proteinConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinConsumed');
    });
  }

  QueryBuilder<CompletedDay, double, QQueryOperations> proteinTargetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'proteinTarget');
    });
  }
}
