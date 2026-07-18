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
    r'calciumMg': PropertySchema(
      id: 0,
      name: r'calciumMg',
      type: IsarType.double,
    ),
    r'calories': PropertySchema(
      id: 1,
      name: r'calories',
      type: IsarType.double,
    ),
    r'carbs': PropertySchema(
      id: 2,
      name: r'carbs',
      type: IsarType.double,
    ),
    r'defaultServingSize': PropertySchema(
      id: 3,
      name: r'defaultServingSize',
      type: IsarType.double,
    ),
    r'fat': PropertySchema(
      id: 4,
      name: r'fat',
      type: IsarType.double,
    ),
    r'fetchedAt': PropertySchema(
      id: 5,
      name: r'fetchedAt',
      type: IsarType.dateTime,
    ),
    r'fibre': PropertySchema(
      id: 6,
      name: r'fibre',
      type: IsarType.double,
    ),
    r'folateMcg': PropertySchema(
      id: 7,
      name: r'folateMcg',
      type: IsarType.double,
    ),
    r'imageUrl': PropertySchema(
      id: 8,
      name: r'imageUrl',
      type: IsarType.string,
    ),
    r'ironMg': PropertySchema(
      id: 9,
      name: r'ironMg',
      type: IsarType.double,
    ),
    r'itemName': PropertySchema(
      id: 10,
      name: r'itemName',
      type: IsarType.string,
    ),
    r'magnesiumMg': PropertySchema(
      id: 11,
      name: r'magnesiumMg',
      type: IsarType.double,
    ),
    r'potassiumMg': PropertySchema(
      id: 12,
      name: r'potassiumMg',
      type: IsarType.double,
    ),
    r'protein': PropertySchema(
      id: 13,
      name: r'protein',
      type: IsarType.double,
    ),
    r'queryKey': PropertySchema(
      id: 14,
      name: r'queryKey',
      type: IsarType.string,
    ),
    r'restaurantName': PropertySchema(
      id: 15,
      name: r'restaurantName',
      type: IsarType.string,
    ),
    r'servingUnit': PropertySchema(
      id: 16,
      name: r'servingUnit',
      type: IsarType.string,
    ),
    r'sodiumMg': PropertySchema(
      id: 17,
      name: r'sodiumMg',
      type: IsarType.double,
    ),
    r'sugar': PropertySchema(
      id: 18,
      name: r'sugar',
      type: IsarType.double,
    ),
    r'vitaminB12Mcg': PropertySchema(
      id: 19,
      name: r'vitaminB12Mcg',
      type: IsarType.double,
    ),
    r'vitaminCMg': PropertySchema(
      id: 20,
      name: r'vitaminCMg',
      type: IsarType.double,
    ),
    r'vitaminDMcg': PropertySchema(
      id: 21,
      name: r'vitaminDMcg',
      type: IsarType.double,
    ),
    r'zincMg': PropertySchema(
      id: 22,
      name: r'zincMg',
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
  writer.writeDouble(offsets[0], object.calciumMg);
  writer.writeDouble(offsets[1], object.calories);
  writer.writeDouble(offsets[2], object.carbs);
  writer.writeDouble(offsets[3], object.defaultServingSize);
  writer.writeDouble(offsets[4], object.fat);
  writer.writeDateTime(offsets[5], object.fetchedAt);
  writer.writeDouble(offsets[6], object.fibre);
  writer.writeDouble(offsets[7], object.folateMcg);
  writer.writeString(offsets[8], object.imageUrl);
  writer.writeDouble(offsets[9], object.ironMg);
  writer.writeString(offsets[10], object.itemName);
  writer.writeDouble(offsets[11], object.magnesiumMg);
  writer.writeDouble(offsets[12], object.potassiumMg);
  writer.writeDouble(offsets[13], object.protein);
  writer.writeString(offsets[14], object.queryKey);
  writer.writeString(offsets[15], object.restaurantName);
  writer.writeString(offsets[16], object.servingUnit);
  writer.writeDouble(offsets[17], object.sodiumMg);
  writer.writeDouble(offsets[18], object.sugar);
  writer.writeDouble(offsets[19], object.vitaminB12Mcg);
  writer.writeDouble(offsets[20], object.vitaminCMg);
  writer.writeDouble(offsets[21], object.vitaminDMcg);
  writer.writeDouble(offsets[22], object.zincMg);
}

CachedMenuItem _cachedMenuItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedMenuItem();
  object.calciumMg = reader.readDoubleOrNull(offsets[0]);
  object.calories = reader.readDouble(offsets[1]);
  object.carbs = reader.readDouble(offsets[2]);
  object.defaultServingSize = reader.readDouble(offsets[3]);
  object.fat = reader.readDouble(offsets[4]);
  object.fetchedAt = reader.readDateTime(offsets[5]);
  object.fibre = reader.readDoubleOrNull(offsets[6]);
  object.folateMcg = reader.readDoubleOrNull(offsets[7]);
  object.id = id;
  object.imageUrl = reader.readStringOrNull(offsets[8]);
  object.ironMg = reader.readDoubleOrNull(offsets[9]);
  object.itemName = reader.readString(offsets[10]);
  object.magnesiumMg = reader.readDoubleOrNull(offsets[11]);
  object.potassiumMg = reader.readDoubleOrNull(offsets[12]);
  object.protein = reader.readDouble(offsets[13]);
  object.queryKey = reader.readString(offsets[14]);
  object.restaurantName = reader.readString(offsets[15]);
  object.servingUnit = reader.readString(offsets[16]);
  object.sodiumMg = reader.readDoubleOrNull(offsets[17]);
  object.sugar = reader.readDoubleOrNull(offsets[18]);
  object.vitaminB12Mcg = reader.readDoubleOrNull(offsets[19]);
  object.vitaminCMg = reader.readDoubleOrNull(offsets[20]);
  object.vitaminDMcg = reader.readDoubleOrNull(offsets[21]);
  object.zincMg = reader.readDoubleOrNull(offsets[22]);
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
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
      calciumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      calciumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      calciumMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'calciumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      calciumMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'calciumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      calciumMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'calciumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      calciumMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'calciumMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'folateMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'folateMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'folateMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      folateMcgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'folateMcg',
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
      ironMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      ironMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      ironMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ironMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      ironMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ironMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      ironMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ironMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      ironMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ironMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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
      magnesiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      magnesiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      magnesiumMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'magnesiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      magnesiumMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'magnesiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      magnesiumMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'magnesiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      magnesiumMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'magnesiumMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'potassiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'potassiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'potassiumMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      potassiumMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'potassiumMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sugar',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      sugarBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sugar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vitaminB12Mcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vitaminB12Mcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vitaminB12Mcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminB12McgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vitaminB12Mcg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vitaminCMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vitaminCMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vitaminCMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminCMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vitaminCMg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'vitaminDMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'vitaminDMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'vitaminDMcg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      vitaminDMcgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'vitaminDMcg',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'zincMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'zincMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'zincMg',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterFilterCondition>
      zincMgBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'zincMg',
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
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> sortByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      sortByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension CachedMenuItemQuerySortThenBy
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QSortThenBy> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy> thenByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QAfterSortBy>
      thenByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension CachedMenuItemQueryWhereDistinct
    on QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> {
  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calciumMg');
    });
  }

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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folateMcg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByImageUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imageUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ironMg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByItemName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'magnesiumMg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'potassiumMg');
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

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sugar');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminCMg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct>
      distinctByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminDMcg');
    });
  }

  QueryBuilder<CachedMenuItem, CachedMenuItem, QDistinct> distinctByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zincMg');
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

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> calciumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calciumMg');
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

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> folateMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folateMcg');
    });
  }

  QueryBuilder<CachedMenuItem, String?, QQueryOperations> imageUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imageUrl');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> ironMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ironMg');
    });
  }

  QueryBuilder<CachedMenuItem, String, QQueryOperations> itemNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemName');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations>
      magnesiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'magnesiumMg');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations>
      potassiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'potassiumMg');
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

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> sugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sugar');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations>
      vitaminB12McgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> vitaminCMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminCMg');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations>
      vitaminDMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminDMcg');
    });
  }

  QueryBuilder<CachedMenuItem, double?, QQueryOperations> zincMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zincMg');
    });
  }
}
