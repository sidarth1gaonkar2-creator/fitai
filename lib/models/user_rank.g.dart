// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_rank.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserRankCollection on Isar {
  IsarCollection<UserRank> get userRanks => this.collection();
}

const UserRankSchema = CollectionSchema(
  name: r'UserRank',
  id: 8159085820773878832,
  properties: {
    r'bodyWeightAtCalculation': PropertySchema(
      id: 0,
      name: r'bodyWeightAtCalculation',
      type: IsarType.double,
    ),
    r'lastCalculatedAt': PropertySchema(
      id: 1,
      name: r'lastCalculatedAt',
      type: IsarType.dateTime,
    ),
    r'overallRankIndex': PropertySchema(
      id: 2,
      name: r'overallRankIndex',
      type: IsarType.long,
    ),
    r'overallScore': PropertySchema(
      id: 3,
      name: r'overallScore',
      type: IsarType.double,
    ),
    r'perExerciseScores': PropertySchema(
      id: 4,
      name: r'perExerciseScores',
      type: IsarType.objectList,
      target: r'ExerciseScore',
    ),
    r'perMuscleGroupRanks': PropertySchema(
      id: 5,
      name: r'perMuscleGroupRanks',
      type: IsarType.objectList,
      target: r'MuscleGroupRankEntry',
    ),
    r'rankHistory': PropertySchema(
      id: 6,
      name: r'rankHistory',
      type: IsarType.objectList,
      target: r'RankSnapshot',
    )
  },
  estimateSize: _userRankEstimateSize,
  serialize: _userRankSerialize,
  deserialize: _userRankDeserialize,
  deserializeProp: _userRankDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {
    r'ExerciseScore': ExerciseScoreSchema,
    r'MuscleGroupRankEntry': MuscleGroupRankEntrySchema,
    r'RankSnapshot': RankSnapshotSchema
  },
  getId: _userRankGetId,
  getLinks: _userRankGetLinks,
  attach: _userRankAttach,
  version: '3.1.0+1',
);

int _userRankEstimateSize(
  UserRank object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.perExerciseScores.length * 3;
  {
    final offsets = allOffsets[ExerciseScore]!;
    for (var i = 0; i < object.perExerciseScores.length; i++) {
      final value = object.perExerciseScores[i];
      bytesCount +=
          ExerciseScoreSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.perMuscleGroupRanks.length * 3;
  {
    final offsets = allOffsets[MuscleGroupRankEntry]!;
    for (var i = 0; i < object.perMuscleGroupRanks.length; i++) {
      final value = object.perMuscleGroupRanks[i];
      bytesCount +=
          MuscleGroupRankEntrySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.rankHistory.length * 3;
  {
    final offsets = allOffsets[RankSnapshot]!;
    for (var i = 0; i < object.rankHistory.length; i++) {
      final value = object.rankHistory[i];
      bytesCount += RankSnapshotSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _userRankSerialize(
  UserRank object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.bodyWeightAtCalculation);
  writer.writeDateTime(offsets[1], object.lastCalculatedAt);
  writer.writeLong(offsets[2], object.overallRankIndex);
  writer.writeDouble(offsets[3], object.overallScore);
  writer.writeObjectList<ExerciseScore>(
    offsets[4],
    allOffsets,
    ExerciseScoreSchema.serialize,
    object.perExerciseScores,
  );
  writer.writeObjectList<MuscleGroupRankEntry>(
    offsets[5],
    allOffsets,
    MuscleGroupRankEntrySchema.serialize,
    object.perMuscleGroupRanks,
  );
  writer.writeObjectList<RankSnapshot>(
    offsets[6],
    allOffsets,
    RankSnapshotSchema.serialize,
    object.rankHistory,
  );
}

UserRank _userRankDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserRank();
  object.bodyWeightAtCalculation = reader.readDouble(offsets[0]);
  object.id = id;
  object.lastCalculatedAt = reader.readDateTime(offsets[1]);
  object.overallRankIndex = reader.readLong(offsets[2]);
  object.overallScore = reader.readDouble(offsets[3]);
  object.perExerciseScores = reader.readObjectList<ExerciseScore>(
        offsets[4],
        ExerciseScoreSchema.deserialize,
        allOffsets,
        ExerciseScore(),
      ) ??
      [];
  object.perMuscleGroupRanks = reader.readObjectList<MuscleGroupRankEntry>(
        offsets[5],
        MuscleGroupRankEntrySchema.deserialize,
        allOffsets,
        MuscleGroupRankEntry(),
      ) ??
      [];
  object.rankHistory = reader.readObjectList<RankSnapshot>(
        offsets[6],
        RankSnapshotSchema.deserialize,
        allOffsets,
        RankSnapshot(),
      ) ??
      [];
  return object;
}

P _userRankDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readObjectList<ExerciseScore>(
            offset,
            ExerciseScoreSchema.deserialize,
            allOffsets,
            ExerciseScore(),
          ) ??
          []) as P;
    case 5:
      return (reader.readObjectList<MuscleGroupRankEntry>(
            offset,
            MuscleGroupRankEntrySchema.deserialize,
            allOffsets,
            MuscleGroupRankEntry(),
          ) ??
          []) as P;
    case 6:
      return (reader.readObjectList<RankSnapshot>(
            offset,
            RankSnapshotSchema.deserialize,
            allOffsets,
            RankSnapshot(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userRankGetId(UserRank object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userRankGetLinks(UserRank object) {
  return [];
}

void _userRankAttach(IsarCollection<dynamic> col, Id id, UserRank object) {
  object.id = id;
}

extension UserRankQueryWhereSort on QueryBuilder<UserRank, UserRank, QWhere> {
  QueryBuilder<UserRank, UserRank, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserRankQueryWhere on QueryBuilder<UserRank, UserRank, QWhereClause> {
  QueryBuilder<UserRank, UserRank, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UserRank, UserRank, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterWhereClause> idBetween(
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
}

extension UserRankQueryFilter
    on QueryBuilder<UserRank, UserRank, QFilterCondition> {
  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      bodyWeightAtCalculationEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyWeightAtCalculation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      bodyWeightAtCalculationGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyWeightAtCalculation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      bodyWeightAtCalculationLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyWeightAtCalculation',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      bodyWeightAtCalculationBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyWeightAtCalculation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      lastCalculatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastCalculatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      lastCalculatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastCalculatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      lastCalculatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastCalculatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      lastCalculatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastCalculatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      overallRankIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overallRankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      overallRankIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overallRankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      overallRankIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overallRankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      overallRankIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overallRankIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> overallScoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      overallScoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> overallScoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'overallScore',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> overallScoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'overallScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perExerciseScores',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'perMuscleGroupRanks',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      rankHistoryLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> rankHistoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      rankHistoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      rankHistoryLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      rankHistoryLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      rankHistoryLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'rankHistory',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension UserRankQueryObject
    on QueryBuilder<UserRank, UserRank, QFilterCondition> {
  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perExerciseScoresElement(FilterQuery<ExerciseScore> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'perExerciseScores');
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition>
      perMuscleGroupRanksElement(FilterQuery<MuscleGroupRankEntry> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'perMuscleGroupRanks');
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterFilterCondition> rankHistoryElement(
      FilterQuery<RankSnapshot> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'rankHistory');
    });
  }
}

extension UserRankQueryLinks
    on QueryBuilder<UserRank, UserRank, QFilterCondition> {}

extension UserRankQuerySortBy on QueryBuilder<UserRank, UserRank, QSortBy> {
  QueryBuilder<UserRank, UserRank, QAfterSortBy>
      sortByBodyWeightAtCalculation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWeightAtCalculation', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy>
      sortByBodyWeightAtCalculationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWeightAtCalculation', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByLastCalculatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCalculatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByLastCalculatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCalculatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByOverallRankIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallRankIndex', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByOverallRankIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallRankIndex', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> sortByOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.desc);
    });
  }
}

extension UserRankQuerySortThenBy
    on QueryBuilder<UserRank, UserRank, QSortThenBy> {
  QueryBuilder<UserRank, UserRank, QAfterSortBy>
      thenByBodyWeightAtCalculation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWeightAtCalculation', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy>
      thenByBodyWeightAtCalculationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyWeightAtCalculation', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByLastCalculatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCalculatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByLastCalculatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastCalculatedAt', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByOverallRankIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallRankIndex', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByOverallRankIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallRankIndex', Sort.desc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.asc);
    });
  }

  QueryBuilder<UserRank, UserRank, QAfterSortBy> thenByOverallScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overallScore', Sort.desc);
    });
  }
}

extension UserRankQueryWhereDistinct
    on QueryBuilder<UserRank, UserRank, QDistinct> {
  QueryBuilder<UserRank, UserRank, QDistinct>
      distinctByBodyWeightAtCalculation() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyWeightAtCalculation');
    });
  }

  QueryBuilder<UserRank, UserRank, QDistinct> distinctByLastCalculatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastCalculatedAt');
    });
  }

  QueryBuilder<UserRank, UserRank, QDistinct> distinctByOverallRankIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overallRankIndex');
    });
  }

  QueryBuilder<UserRank, UserRank, QDistinct> distinctByOverallScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overallScore');
    });
  }
}

extension UserRankQueryProperty
    on QueryBuilder<UserRank, UserRank, QQueryProperty> {
  QueryBuilder<UserRank, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserRank, double, QQueryOperations>
      bodyWeightAtCalculationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyWeightAtCalculation');
    });
  }

  QueryBuilder<UserRank, DateTime, QQueryOperations>
      lastCalculatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastCalculatedAt');
    });
  }

  QueryBuilder<UserRank, int, QQueryOperations> overallRankIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overallRankIndex');
    });
  }

  QueryBuilder<UserRank, double, QQueryOperations> overallScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overallScore');
    });
  }

  QueryBuilder<UserRank, List<ExerciseScore>, QQueryOperations>
      perExerciseScoresProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perExerciseScores');
    });
  }

  QueryBuilder<UserRank, List<MuscleGroupRankEntry>, QQueryOperations>
      perMuscleGroupRanksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'perMuscleGroupRanks');
    });
  }

  QueryBuilder<UserRank, List<RankSnapshot>, QQueryOperations>
      rankHistoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rankHistory');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ExerciseScoreSchema = Schema(
  name: r'ExerciseScore',
  id: -7620848917661487509,
  properties: {
    r'exerciseId': PropertySchema(
      id: 0,
      name: r'exerciseId',
      type: IsarType.string,
    ),
    r'score': PropertySchema(
      id: 1,
      name: r'score',
      type: IsarType.double,
    )
  },
  estimateSize: _exerciseScoreEstimateSize,
  serialize: _exerciseScoreSerialize,
  deserialize: _exerciseScoreDeserialize,
  deserializeProp: _exerciseScoreDeserializeProp,
);

int _exerciseScoreEstimateSize(
  ExerciseScore object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.exerciseId.length * 3;
  return bytesCount;
}

void _exerciseScoreSerialize(
  ExerciseScore object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.exerciseId);
  writer.writeDouble(offsets[1], object.score);
}

ExerciseScore _exerciseScoreDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ExerciseScore(
    exerciseId: reader.readStringOrNull(offsets[0]) ?? '',
    score: reader.readDoubleOrNull(offsets[1]) ?? 0,
  );
  return object;
}

P _exerciseScoreDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readDoubleOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ExerciseScoreQueryFilter
    on QueryBuilder<ExerciseScore, ExerciseScore, QFilterCondition> {
  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exerciseId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'exerciseId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'exerciseId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      exerciseIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'exerciseId',
        value: '',
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      scoreEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'score',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      scoreGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'score',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      scoreLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'score',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ExerciseScore, ExerciseScore, QAfterFilterCondition>
      scoreBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'score',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension ExerciseScoreQueryObject
    on QueryBuilder<ExerciseScore, ExerciseScore, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const MuscleGroupRankEntrySchema = Schema(
  name: r'MuscleGroupRankEntry',
  id: 49103164416290176,
  properties: {
    r'group': PropertySchema(
      id: 0,
      name: r'group',
      type: IsarType.string,
    ),
    r'rank': PropertySchema(
      id: 1,
      name: r'rank',
      type: IsarType.long,
    )
  },
  estimateSize: _muscleGroupRankEntryEstimateSize,
  serialize: _muscleGroupRankEntrySerialize,
  deserialize: _muscleGroupRankEntryDeserialize,
  deserializeProp: _muscleGroupRankEntryDeserializeProp,
);

int _muscleGroupRankEntryEstimateSize(
  MuscleGroupRankEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.group.length * 3;
  return bytesCount;
}

void _muscleGroupRankEntrySerialize(
  MuscleGroupRankEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.group);
  writer.writeLong(offsets[1], object.rank);
}

MuscleGroupRankEntry _muscleGroupRankEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = MuscleGroupRankEntry(
    group: reader.readStringOrNull(offsets[0]) ?? '',
    rank: reader.readLongOrNull(offsets[1]) ?? 0,
  );
  return object;
}

P _muscleGroupRankEntryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension MuscleGroupRankEntryQueryFilter on QueryBuilder<MuscleGroupRankEntry,
    MuscleGroupRankEntry, QFilterCondition> {
  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'group',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
          QAfterFilterCondition>
      groupContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'group',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
          QAfterFilterCondition>
      groupMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'group',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'group',
        value: '',
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> groupIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'group',
        value: '',
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> rankEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> rankGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> rankLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rank',
        value: value,
      ));
    });
  }

  QueryBuilder<MuscleGroupRankEntry, MuscleGroupRankEntry,
      QAfterFilterCondition> rankBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rank',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MuscleGroupRankEntryQueryObject on QueryBuilder<MuscleGroupRankEntry,
    MuscleGroupRankEntry, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RankSnapshotSchema = Schema(
  name: r'RankSnapshot',
  id: -891810498484627299,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'rankIndex': PropertySchema(
      id: 1,
      name: r'rankIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _rankSnapshotEstimateSize,
  serialize: _rankSnapshotSerialize,
  deserialize: _rankSnapshotDeserialize,
  deserializeProp: _rankSnapshotDeserializeProp,
);

int _rankSnapshotEstimateSize(
  RankSnapshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _rankSnapshotSerialize(
  RankSnapshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeLong(offsets[1], object.rankIndex);
}

RankSnapshot _rankSnapshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RankSnapshot(
    date: reader.readDateTimeOrNull(offsets[0]),
    rankIndex: reader.readLongOrNull(offsets[1]) ?? 0,
  );
  return object;
}

P _rankSnapshotDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension RankSnapshotQueryFilter
    on QueryBuilder<RankSnapshot, RankSnapshot, QFilterCondition> {
  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition> dateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      dateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'date',
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition> dateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      dateGreaterThan(
    DateTime? value, {
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

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition> dateLessThan(
    DateTime? value, {
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

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition> dateBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      rankIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'rankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      rankIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'rankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      rankIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'rankIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<RankSnapshot, RankSnapshot, QAfterFilterCondition>
      rankIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'rankIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension RankSnapshotQueryObject
    on QueryBuilder<RankSnapshot, RankSnapshot, QFilterCondition> {}
