// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_theme_state.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserThemeStateCollection on Isar {
  IsarCollection<UserThemeState> get userThemeStates => this.collection();
}

const UserThemeStateSchema = CollectionSchema(
  name: r'UserThemeState',
  id: 5645166880547812994,
  properties: {
    r'coins': PropertySchema(
      id: 0,
      name: r'coins',
      type: IsarType.long,
    ),
    r'equippedThemeId': PropertySchema(
      id: 1,
      name: r'equippedThemeId',
      type: IsarType.string,
    ),
    r'gems': PropertySchema(
      id: 2,
      name: r'gems',
      type: IsarType.long,
    ),
    r'ownedThemeIds': PropertySchema(
      id: 3,
      name: r'ownedThemeIds',
      type: IsarType.stringList,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _userThemeStateEstimateSize,
  serialize: _userThemeStateSerialize,
  deserialize: _userThemeStateDeserialize,
  deserializeProp: _userThemeStateDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userThemeStateGetId,
  getLinks: _userThemeStateGetLinks,
  attach: _userThemeStateAttach,
  version: '3.1.0+1',
);

int _userThemeStateEstimateSize(
  UserThemeState object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.equippedThemeId.length * 3;
  bytesCount += 3 + object.ownedThemeIds.length * 3;
  {
    for (var i = 0; i < object.ownedThemeIds.length; i++) {
      final value = object.ownedThemeIds[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _userThemeStateSerialize(
  UserThemeState object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.coins);
  writer.writeString(offsets[1], object.equippedThemeId);
  writer.writeLong(offsets[2], object.gems);
  writer.writeStringList(offsets[3], object.ownedThemeIds);
  writer.writeDateTime(offsets[4], object.updatedAt);
}

UserThemeState _userThemeStateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserThemeState();
  object.coins = reader.readLong(offsets[0]);
  object.equippedThemeId = reader.readString(offsets[1]);
  object.gems = reader.readLong(offsets[2]);
  object.id = id;
  object.ownedThemeIds = reader.readStringList(offsets[3]) ?? [];
  object.updatedAt = reader.readDateTime(offsets[4]);
  return object;
}

P _userThemeStateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userThemeStateGetId(UserThemeState object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userThemeStateGetLinks(UserThemeState object) {
  return [];
}

void _userThemeStateAttach(
    IsarCollection<dynamic> col, Id id, UserThemeState object) {
  object.id = id;
}

extension UserThemeStateQueryWhereSort
    on QueryBuilder<UserThemeState, UserThemeState, QWhere> {
  QueryBuilder<UserThemeState, UserThemeState, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserThemeStateQueryWhere
    on QueryBuilder<UserThemeState, UserThemeState, QWhereClause> {
  QueryBuilder<UserThemeState, UserThemeState, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<UserThemeState, UserThemeState, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterWhereClause> idBetween(
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

extension UserThemeStateQueryFilter
    on QueryBuilder<UserThemeState, UserThemeState, QFilterCondition> {
  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      coinsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coins',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      coinsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coins',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      coinsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coins',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      coinsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coins',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'equippedThemeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'equippedThemeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'equippedThemeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'equippedThemeId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      equippedThemeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'equippedThemeId',
        value: '',
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      gemsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gems',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      gemsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gems',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      gemsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gems',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      gemsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gems',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
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

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
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

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ownedThemeIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ownedThemeIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ownedThemeIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ownedThemeIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ownedThemeIds',
        value: '',
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      ownedThemeIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'ownedThemeIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserThemeStateQueryObject
    on QueryBuilder<UserThemeState, UserThemeState, QFilterCondition> {}

extension UserThemeStateQueryLinks
    on QueryBuilder<UserThemeState, UserThemeState, QFilterCondition> {}

extension UserThemeStateQuerySortBy
    on QueryBuilder<UserThemeState, UserThemeState, QSortBy> {
  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> sortByCoins() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coins', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> sortByCoinsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coins', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      sortByEquippedThemeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equippedThemeId', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      sortByEquippedThemeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equippedThemeId', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> sortByGems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gems', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> sortByGemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gems', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserThemeStateQuerySortThenBy
    on QueryBuilder<UserThemeState, UserThemeState, QSortThenBy> {
  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByCoins() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coins', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByCoinsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coins', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      thenByEquippedThemeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equippedThemeId', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      thenByEquippedThemeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'equippedThemeId', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByGems() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gems', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByGemsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gems', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension UserThemeStateQueryWhereDistinct
    on QueryBuilder<UserThemeState, UserThemeState, QDistinct> {
  QueryBuilder<UserThemeState, UserThemeState, QDistinct> distinctByCoins() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coins');
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QDistinct>
      distinctByEquippedThemeId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'equippedThemeId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QDistinct> distinctByGems() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gems');
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QDistinct>
      distinctByOwnedThemeIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownedThemeIds');
    });
  }

  QueryBuilder<UserThemeState, UserThemeState, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension UserThemeStateQueryProperty
    on QueryBuilder<UserThemeState, UserThemeState, QQueryProperty> {
  QueryBuilder<UserThemeState, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserThemeState, int, QQueryOperations> coinsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coins');
    });
  }

  QueryBuilder<UserThemeState, String, QQueryOperations>
      equippedThemeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'equippedThemeId');
    });
  }

  QueryBuilder<UserThemeState, int, QQueryOperations> gemsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gems');
    });
  }

  QueryBuilder<UserThemeState, List<String>, QQueryOperations>
      ownedThemeIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownedThemeIds');
    });
  }

  QueryBuilder<UserThemeState, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
