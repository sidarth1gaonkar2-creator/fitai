// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_menu_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedMenuItemCollection on Isar {
  IsarCollection<CachedMenuItem> get cachedMenuItems => this.collection();
}

const CachedMenuItemSchema = CollectionSchema(
  name: r'CachedMenuItem',
  id: -494979629536301666,
  properties: {
    r'calories': PropertySchema(
      id: 0,
      name: r'calories',
      type: IsarType.double,
    ),
    r'carbs': PropertySchema(
      id: 1,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'defaultServingSize': PropertySchema(
      id: 2,
      name: r'defaultServingSize',
      type: IsarType.double,
    ),
    r'fat': PropertySchema(
      id: 3,
      name: r'fat',
      type: IsarType.double,
    ),
    r'fetchedAt': PropertySchema(
      id: 4,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'fibre': PropertySchema(
      id: 5,
      name: r'fibre',
      type: IsarType.double,
    ),
    r'imageUrl': PropertySchema(
      id: 6,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'itemName': PropertySchema(
      id: 7,
      name: r'itemName',
      type: IsarType.string,
    ),
    r'protein': PropertySchema(
      id: 8,
      name: r'protein',
      type: IsarType.double,
    ),
    r'queryKey': PropertySchema(
      id: 9,
      name: r'queryKey',
      type: IsarType.string,
    ),
    r'restaurantName': PropertySchema(
      id: 10,
      name: r'restaurantName',
      type: IsarType.string,
    ),
    r'servingUnit': PropertySchema(
      id: 11,
      name: r'servingUnit',
      type: IsarType.string,
    ),
    r'sodiumMg': PropertySchema(
      id: 12,
      name: r'sodiumMg',
      type: IsarType.double,
    )
  },
  estimateSize: _cachedMenuItemEstimateSize,
  serialize: _cachedMenuItemSerialize,
  deserialize: _cachedMenuItemDeserialize,
  deserializeProp: _cachedMenuItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'queryKey': IndexSchema(
      id: 1924554350003761257,
      name: r'queryKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'queryKey',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedMenuItemGetId,
  getLinks: _cachedMenuItemGetLinks,
  attach: _cachedMenuItemAttach,
  version: '3.1.0+1',
);

int _cachedMenuItemEstimateSize(
  CachedMenuItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.imageUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.itemName.length * 3;
  bytesCount += 3 + object.queryKey.length * 3;
  bytesCount += 3 + object.restaurantName.length * 3;
  bytesCount += 3 + object.servingUnit.length * 3;
  return bytesCount;
}

void _cachedMenuItemSerialize(
  CachedMenuItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.calories);
  writer.writeDouble(offsets[1], object.carbs);
  writer.writeDouble(offsets[2], object.defaultServingSize);
  writer.writeDouble(offsets[3], object.fat);
  writer.writeDateTime(offsets[4], object.fetchedAt);
  writer.writeDouble(offsets[5], object.fibre);
  writer.writeString(offsets[6], object.imageUrl);
  writer.writeString(offsets[7], object.itemName);
  writer.writeDouble(offsets[8], object.protein);
  writer.writeString(offsets[9], object.queryKey);
  writer.writeString(offsets[10], object.restaurantName);
  writer.writeString(offsets[11], object.servingUnit);
  writer.writeDouble(offsets[12], object.sodiumMg);
}

CachedMenuItem _cachedMenuItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedMenuItem();
  object.calories = reader.readDouble(offsets[0]);
  object.carbs = reader.readDouble(offsets[1]);
  object.defaultServingSize = reader.readDouble(offsets[2]);
  object.fat = reader.readDouble(offsets[3]);
  object.fetchedAt = reader.readDateTime(offsets[4]);
  object.fibre = reader.readDoubleOrNull(offsets[5]);
  object.id = id;
  object.imageUrl = reader.readStringOrNull(offsets[6]);
  object.itemName = reader.readString(offsets[7]);
  object.protein = reader.readDouble(offsets[8]);
  object.queryKey = reader.readString(offsets[9]);
  object.restaurantName = reader.readString(offsets[10]);
  object.servingUnit = reader.readString(offsets[11]);
  object.sodiumMg = reader.readDoubleOrNull(offsets[12]);
  return object;
}

P _cachedMenuItemDeserializeProp<P>(
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedMenuItemGetId(CachedMenuItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedMenuItemGetLinks(CachedMenuItem object) {
  return [];
}

void _cachedMenuItemAttach(
    IsarCollection<dynamic> col, Id id, CachedMenuItem object) {
  object.id = id;
}

extension CachedMenuItemQueryWhereSort
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QWhere> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedMenuItemQueryWhere
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QWhereClause> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause>
      queryKeyEqualTo(String queryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'queryKey',
        value: [queryKey],
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterWhereClause>
      queryKeyNotEqualTo(String queryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [],
              upper: [queryKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [queryKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [queryKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [],
              upper: [queryKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedMenuItemQueryFilter
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QFilterCondition> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      caloriesEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      caloriesGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      caloriesLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calories',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      caloriesBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calories',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      carbsEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      carbsGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      carbsLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'carbs',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      carbsBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'carbs',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      defaultServingSizeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultServingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      defaultServingSizeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'defaultServingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      defaultServingSizeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'defaultServingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      defaultServingSizeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'defaultServingSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fatEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fatGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fatLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fat',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fatBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fat',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fetchedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fetchedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fetchedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fetchedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fetchedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fetchedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fibre',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fibre',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fibre',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      fibreBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fibre',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imageUrl',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imageUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imageUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imageUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      imageUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imageUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      itemNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      proteinEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      proteinGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      proteinLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'protein',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      proteinBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'protein',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'queryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      queryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'queryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restaurantName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'restaurantName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'restaurantName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restaurantName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      restaurantNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'restaurantName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servingUnit',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'servingUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      servingUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sodiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sodiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sodiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sodiumMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sodiumMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CachedMenuItemQueryObject
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QFilterCondition> {}

extension CachedMenuItemQueryLinks
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QFilterCondition> {}

extension CachedMenuItemQuerySortBy
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QSortBy> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByDefaultServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultServingSize', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByDefaultServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultServingSize', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByItemName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemName', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByItemNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemName', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByQueryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByQueryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByRestaurantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantName', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByRestaurantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantName', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }
}

extension CachedMenuItemQuerySortThenBy
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QSortThenBy> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByDefaultServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultServingSize', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByDefaultServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultServingSize', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByFetchedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fetchedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByImageUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByImageUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imageUrl', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByItemName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemName', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByItemNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemName', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByQueryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByQueryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByRestaurantName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantName', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByRestaurantNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restaurantName', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }
}

extension CachedMenuItemQueryWhereDistinct
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbs');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByDefaultServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultServingSize');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fat');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByFetchedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fetchedAt');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fibre');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByItemName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protein');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByQueryKey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queryKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByRestaurantName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restaurantName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByServingUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingUnit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodiumMg');
    });
  }
}

extension CachedMenuItemQueryProperty
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QQueryProperty> {
  QueryBuilder<CachedMenuItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedMenuItem, double, QQueryOperations> caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<CachedMenuItem, double, QQueryOperations> carbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbs');
    });
  }

  QueryBuilder<CachedMenuItem, double, QQueryOperations>
      defaultServingSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultServingSize');
    });
  }

  QueryBuilder<CachedMenuItem, double, QQueryOperations> fatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fat');
    });
  }

  QueryBuilder<CachedMenuItem, DateTime, QQueryOperations> fetchedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fetchedAt');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> fibreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fibre');
    });
  }

  QueryBuilder<CachedMenuItem, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<CachedMenuItem, String, QQueryOperations> itemNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemName');
    });
  }

  QueryBuilder<CachedMenuItem, double, QQueryOperations> proteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protein');
    });
  }

  QueryBuilder<CachedMenuItem, String, QQueryOperations> queryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queryKey');
    });
  }

  QueryBuilder<CachedMenuItem, String, QQueryOperations>
      restaurantNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restaurantName');
    });
  }

  QueryBuilder<CachedMenuItem, String, QQueryOperations> servingUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingUnit');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> sodiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodiumMg');
    });
  }
}
