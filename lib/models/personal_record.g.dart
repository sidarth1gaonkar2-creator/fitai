// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPersonalRecordCollection on Isar {
  IsarCollection<PersonalRecord> get personalRecords => this.collection();
}

const PersonalRecordSchema = CollectionSchema(
  name: r'PersonalRecord',
  id: -5502306867987183745,
  properties: {
    r'bestReps': PropertySchema(
      id: 0,
      name: r'bestReps',
      type: IsarType.long,
    ),
    r'dateAchieved': PropertySchema(
      id: 1,
      name: r'dateAchieved',
      type: IsarType.dateTime,
    ),
    r'exerciseName': PropertySchema(
      id: 2,
      name: r'exerciseName',
      type: IsarType.string,
    ),
    r'muscleGroup': PropertySchema(
      id: 3,
      name: r'muscleGroup',
      type: IsarType.byte,
      enumMap: _PersonalRecordmuscleGroupEnumValueMap,
    ),
    r'weightKg': PropertySchema(
      id: 4,
      name: r'weightKg',
      type: IsarType.double,
    )
  },
  estimateSize: _personalRecordEstimateSize,
  serialize: _personalRecordSerialize,
  deserialize: _personalRecordDeserialize,
  deserializeProp: _personalRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'exerciseName': IndexSchema(
      id: 4205715828964724693,
      name: r'exerciseName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'exerciseName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _personalRecordGetId,
  getLinks: _personalRecordGetLinks,
  attach: _personalRecordAttach,
  version: '3.1.0+1',
);

int _personalRecordEstimateSize(
  PersonalRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseName.length * 3;
  return bytesCount;
}

void _personalRecordSerialize(
  PersonalRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bestReps);
  writer.writeDateTime(offsets[1], object.dateAchieved);
  writer.writeString(offsets[2], object.exerciseName);
  writer.writeByte(offsets[3], object.muscleGroup.index);
  writer.writeDouble(offsets[4], object.weightKg);
}

PersonalRecord _personalRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PersonalRecord();
  object.bestReps = reader.readLong(offsets[0]);
  object.dateAchieved = reader.readDateTime(offsets[1]);
  object.exerciseName = reader.readString(offsets[2]);
  object.id = id;
  object.muscleGroup = _PersonalRecordmuscleGroupValueEnumMap[
          reader.readByteOrNull(offsets[3])] ??
      MuscleGroup.chest;
  object.weightKg = reader.readDouble(offsets[4]);
  return object;
}

P _personalRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (_PersonalRecordmuscleGroupValueEnumMap[
              reader.readByteOrNull(offset)] ??
          MuscleGroup.chest) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PersonalRecordmuscleGroupEnumValueMap = {
  'chest': 0,
  'upperBack': 1,
  'lats': 2,
  'shoulders': 3,
  'biceps': 4,
  'triceps': 5,
  'forearms': 6,
  'quads': 7,
  'hamstrings': 8,
  'glutes': 9,
  'calves': 10,
  'abs': 11,
  'obliques': 12,
  'cardio': 13,
  'lowerBack': 14,
};
const _PersonalRecordmuscleGroupValueEnumMap = {
  0: MuscleGroup.chest,
  1: MuscleGroup.upperBack,
  2: MuscleGroup.lats,
  3: MuscleGroup.shoulders,
  4: MuscleGroup.biceps,
  5: MuscleGroup.triceps,
  6: MuscleGroup.forearms,
  7: MuscleGroup.quads,
  8: MuscleGroup.hamstrings,
  9: MuscleGroup.glutes,
  10: MuscleGroup.calves,
  11: MuscleGroup.abs,
  12: MuscleGroup.obliques,
  13: MuscleGroup.cardio,
  14: MuscleGroup.lowerBack,
};

Id _personalRecordGetId(PersonalRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _personalRecordGetLinks(PersonalRecord object) {
  return [];
}

void _personalRecordAttach(
    IsarCollection<dynamic> col, Id id, PersonalRecord object) {
  object.id = id;
}

extension PersonalRecordQueryWhereSort
    on QueryBuilder<PersonalRecord, PersonalRecord, QWhere> {
  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PersonalRecordQueryWhere
    on QueryBuilder<PersonalRecord, PersonalRecord, QWhereClause> {
  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause>
      exerciseNameEqualTo(String exerciseName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'exerciseName',
        value: [exerciseName],
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterWhereClause>
      exerciseNameNotEqualTo(String exerciseName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [],
              upper: [exerciseName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [exerciseName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [exerciseName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'exerciseName',
              lower: [],
              upper: [exerciseName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PersonalRecordQueryFilter
    on QueryBuilder<PersonalRecord, PersonalRecord, QFilterCondition> {
  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      bestRepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bestReps',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      bestRepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bestReps',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      bestRepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bestReps',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      bestRepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bestReps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      dateAchievedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dateAchieved',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      dateAchievedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dateAchieved',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      dateAchievedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dateAchieved',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      dateAchievedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dateAchieved',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      exerciseNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseName',
        value: '',
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
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

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      muscleGroupEqualTo(MuscleGroup value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'muscleGroup',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      muscleGroupGreaterThan(
    MuscleGroup value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'muscleGroup',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      muscleGroupLessThan(
    MuscleGroup value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'muscleGroup',
        value: value,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      muscleGroupBetween(
    MuscleGroup lower,
    MuscleGroup upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'muscleGroup',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      weightKgEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      weightKgGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      weightKgLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weightKg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterFilterCondition>
      weightKgBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weightKg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension PersonalRecordQueryObject
    on QueryBuilder<PersonalRecord, PersonalRecord, QFilterCondition> {}

extension PersonalRecordQueryLinks
    on QueryBuilder<PersonalRecord, PersonalRecord, QFilterCondition> {}

extension PersonalRecordQuerySortBy
    on QueryBuilder<PersonalRecord, PersonalRecord, QSortBy> {
  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> sortByBestReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestReps', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByBestRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestReps', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByDateAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAchieved', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByDateAchievedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAchieved', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByMuscleGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muscleGroup', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByMuscleGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muscleGroup', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> sortByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      sortByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension PersonalRecordQuerySortThenBy
    on QueryBuilder<PersonalRecord, PersonalRecord, QSortThenBy> {
  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> thenByBestReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestReps', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByBestRepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bestReps', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByDateAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAchieved', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByDateAchievedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dateAchieved', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByExerciseName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByExerciseNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exerciseName', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByMuscleGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muscleGroup', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByMuscleGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'muscleGroup', Sort.desc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy> thenByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.asc);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QAfterSortBy>
      thenByWeightKgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weightKg', Sort.desc);
    });
  }
}

extension PersonalRecordQueryWhereDistinct
    on QueryBuilder<PersonalRecord, PersonalRecord, QDistinct> {
  QueryBuilder<PersonalRecord, PersonalRecord, QDistinct> distinctByBestReps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bestReps');
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QDistinct>
      distinctByDateAchieved() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dateAchieved');
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QDistinct>
      distinctByExerciseName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exerciseName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QDistinct>
      distinctByMuscleGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'muscleGroup');
    });
  }

  QueryBuilder<PersonalRecord, PersonalRecord, QDistinct> distinctByWeightKg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weightKg');
    });
  }
}

extension PersonalRecordQueryProperty
    on QueryBuilder<PersonalRecord, PersonalRecord, QQueryProperty> {
  QueryBuilder<PersonalRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PersonalRecord, int, QQueryOperations> bestRepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bestReps');
    });
  }

  QueryBuilder<PersonalRecord, DateTime, QQueryOperations>
      dateAchievedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dateAchieved');
    });
  }

  QueryBuilder<PersonalRecord, String, QQueryOperations>
      exerciseNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exerciseName');
    });
  }

  QueryBuilder<PersonalRecord, MuscleGroup, QQueryOperations>
      muscleGroupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'muscleGroup');
    });
  }

  QueryBuilder<PersonalRecord, double, QQueryOperations> weightKgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weightKg');
    });
  }
}
