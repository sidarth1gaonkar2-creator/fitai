// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_entry.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFoodEntryCollection on Isar {
  IsarCollection<FoodEntry> get foodEntrys => this.collection();
}

const FoodEntrySchema = CollectionSchema(
  name: r'FoodEntry',
  id: -3633015723928946904,
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
    r'fat': PropertySchema(
      id: 3,
      name: r'fat',
      type: IsarType.double,
    ),
    r'fibre': PropertySchema(
      id: 4,
      name: r'fibre',
      type: IsarType.double,
    ),
    r'folateMcg': PropertySchema(
      id: 5,
      name: r'folateMcg',
      type: IsarType.double,
    ),
    r'ironMg': PropertySchema(
      id: 6,
      name: r'ironMg',
      type: IsarType.double,
    ),
    r'magnesiumMg': PropertySchema(
      id: 7,
      name: r'magnesiumMg',
      type: IsarType.double,
    ),
    r'mealGroupEmoji': PropertySchema(
      id: 8,
      name: r'mealGroupEmoji',
      type: IsarType.string,
    ),
    r'mealGroupId': PropertySchema(
      id: 9,
      name: r'mealGroupId',
      type: IsarType.string,
    ),
    r'mealGroupName': PropertySchema(
      id: 10,
      name: r'mealGroupName',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 11,
      name: r'name',
      type: IsarType.string,
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
    r'servingSize': PropertySchema(
      id: 14,
      name: r'servingSize',
      type: IsarType.double,
    ),
    r'servingUnit': PropertySchema(
      id: 15,
      name: r'servingUnit',
      type: IsarType.string,
    ),
    r'sodiumMg': PropertySchema(
      id: 16,
      name: r'sodiumMg',
      type: IsarType.double,
    ),
    r'sugar': PropertySchema(
      id: 17,
      name: r'sugar',
      type: IsarType.double,
    ),
    r'vitaminB12Mcg': PropertySchema(
      id: 18,
      name: r'vitaminB12Mcg',
      type: IsarType.double,
    ),
    r'vitaminCMg': PropertySchema(
      id: 19,
      name: r'vitaminCMg',
      type: IsarType.double,
    ),
    r'vitaminDMcg': PropertySchema(
      id: 20,
      name: r'vitaminDMcg',
      type: IsarType.double,
    ),
    r'zincMg': PropertySchema(
      id: 21,
      name: r'zincMg',
      type: IsarType.double,
    )
  },
  estimateSize: _foodEntryEstimateSize,
  serialize: _foodEntrySerialize,
  deserialize: _foodEntryDeserialize,
  deserializeProp: _foodEntryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'meal': LinkSchema(
      id: 3262130506179308620,
      name: r'meal',
      target: r'Meal',
      single: false,
      linkName: r'foodEntries',
    )
  },
  embeddedSchemas: {},
  getId: _foodEntryGetId,
  getLinks: _foodEntryGetLinks,
  attach: _foodEntryAttach,
  version: '3.1.0+1',
);

int _foodEntryEstimateSize(
  FoodEntry object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.mealGroupEmoji;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mealGroupId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mealGroupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.servingUnit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _foodEntrySerialize(
  FoodEntry object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.calciumMg);
  writer.writeDouble(offsets[1], object.calories);
  writer.writeDouble(offsets[2], object.carbs);
  writer.writeDouble(offsets[3], object.fat);
  writer.writeDouble(offsets[4], object.fibre);
  writer.writeDouble(offsets[5], object.folateMcg);
  writer.writeDouble(offsets[6], object.ironMg);
  writer.writeDouble(offsets[7], object.magnesiumMg);
  writer.writeString(offsets[8], object.mealGroupEmoji);
  writer.writeString(offsets[9], object.mealGroupId);
  writer.writeString(offsets[10], object.mealGroupName);
  writer.writeString(offsets[11], object.name);
  writer.writeDouble(offsets[12], object.potassiumMg);
  writer.writeDouble(offsets[13], object.protein);
  writer.writeDouble(offsets[14], object.servingSize);
  writer.writeString(offsets[15], object.servingUnit);
  writer.writeDouble(offsets[16], object.sodiumMg);
  writer.writeDouble(offsets[17], object.sugar);
  writer.writeDouble(offsets[18], object.vitaminB12Mcg);
  writer.writeDouble(offsets[19], object.vitaminCMg);
  writer.writeDouble(offsets[20], object.vitaminDMcg);
  writer.writeDouble(offsets[21], object.zincMg);
}

FoodEntry _foodEntryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FoodEntry();
  object.calciumMg = reader.readDoubleOrNull(offsets[0]);
  object.calories = reader.readDouble(offsets[1]);
  object.carbs = reader.readDouble(offsets[2]);
  object.fat = reader.readDouble(offsets[3]);
  object.fibre = reader.readDoubleOrNull(offsets[4]);
  object.folateMcg = reader.readDoubleOrNull(offsets[5]);
  object.id = id;
  object.ironMg = reader.readDoubleOrNull(offsets[6]);
  object.magnesiumMg = reader.readDoubleOrNull(offsets[7]);
  object.mealGroupEmoji = reader.readStringOrNull(offsets[8]);
  object.mealGroupId = reader.readStringOrNull(offsets[9]);
  object.mealGroupName = reader.readStringOrNull(offsets[10]);
  object.name = reader.readString(offsets[11]);
  object.potassiumMg = reader.readDoubleOrNull(offsets[12]);
  object.protein = reader.readDouble(offsets[13]);
  object.servingSize = reader.readDoubleOrNull(offsets[14]);
  object.servingUnit = reader.readStringOrNull(offsets[15]);
  object.sodiumMg = reader.readDoubleOrNull(offsets[16]);
  object.sugar = reader.readDoubleOrNull(offsets[17]);
  object.vitaminB12Mcg = reader.readDoubleOrNull(offsets[18]);
  object.vitaminCMg = reader.readDoubleOrNull(offsets[19]);
  object.vitaminDMcg = reader.readDoubleOrNull(offsets[20]);
  object.zincMg = reader.readDoubleOrNull(offsets[21]);
  return object;
}

P _foodEntryDeserializeProp<P>(
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
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDouble(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
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
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _foodEntryGetId(FoodEntry object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _foodEntryGetLinks(FoodEntry object) {
  return [object.meal];
}

void _foodEntryAttach(IsarCollection<dynamic> col, Id id, FoodEntry object) {
  object.id = id;
  object.meal.attach(col, col.isar.collection<Meal>(), r'meal', id);
}

extension FoodEntryQueryWhereSort
    on QueryBuilder<FoodEntry, FoodEntry, QWhere> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FoodEntryQueryWhere
    on QueryBuilder<FoodEntry, FoodEntry, QWhereClause> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterWhereClause> idBetween(
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

extension FoodEntryQueryFilter
    on QueryBuilder<FoodEntry, FoodEntry, QFilterCondition> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> calciumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      calciumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> calciumMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> calciumMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> calciumMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> caloriesEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> caloriesGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> caloriesLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> caloriesBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> carbsEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> carbsGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> carbsLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> carbsBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fatEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fatGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fatLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fatBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> fibreBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> folateMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      folateMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> folateMcgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> folateMcgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> folateMcgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> idBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> ironMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      magnesiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      magnesiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> magnesiumMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> magnesiumMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> magnesiumMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mealGroupEmoji',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mealGroupEmoji',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealGroupEmoji',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealGroupEmoji',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealGroupEmoji',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupEmojiIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealGroupEmoji',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mealGroupId',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mealGroupId',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealGroupId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealGroupId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealGroupIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealGroupId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupId',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealGroupId',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mealGroupName',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mealGroupName',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealGroupName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mealGroupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mealGroupName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealGroupName',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealGroupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mealGroupName',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      potassiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      potassiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> potassiumMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> potassiumMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> potassiumMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> proteinEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> proteinGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> proteinLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> proteinBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingSize',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingSize',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingSizeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingSizeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'servingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingSizeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'servingSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingSizeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'servingSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingUnit',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingUnit',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitEqualTo(
    String? value, {
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingUnitGreaterThan(
    String? value, {
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitLessThan(
    String? value, {
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitEndsWith(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> servingUnitMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'servingUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      servingUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sodiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      sodiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sodiumMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sodiumMgGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sodiumMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sodiumMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> sugarBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      vitaminB12McgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      vitaminB12McgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminCMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      vitaminCMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminCMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminCMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminCMgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      vitaminDMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      vitaminDMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminDMcgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminDMcgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> vitaminDMcgBetween(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgEqualTo(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgGreaterThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgLessThan(
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

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> zincMgBetween(
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

extension FoodEntryQueryObject
    on QueryBuilder<FoodEntry, FoodEntry, QFilterCondition> {}

extension FoodEntryQueryLinks
    on QueryBuilder<FoodEntry, FoodEntry, QFilterCondition> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> meal(
      FilterQuery<Meal> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meal');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', length, true, length, true);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, true, 0, true);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, false, 999999, true);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, true, length, include);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition>
      mealLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', length, include, 999999, true);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterFilterCondition> mealLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'meal', lower, includeLower, upper, includeUpper);
    });
  }
}

extension FoodEntryQuerySortBy on QueryBuilder<FoodEntry, FoodEntry, QSortBy> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupEmoji', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupEmoji', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupId', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupId', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupName', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByMealGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupName', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> sortByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension FoodEntryQuerySortThenBy
    on QueryBuilder<FoodEntry, FoodEntry, QSortThenBy> {
  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupEmoji() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupEmoji', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupEmojiDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupEmoji', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupId', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupId', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupName', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByMealGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealGroupName', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QAfterSortBy> thenByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension FoodEntryQueryWhereDistinct
    on QueryBuilder<FoodEntry, FoodEntry, QDistinct> {
  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calciumMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbs');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fat');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fibre');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folateMcg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ironMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'magnesiumMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByMealGroupEmoji(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealGroupEmoji',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByMealGroupId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealGroupId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByMealGroupName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealGroupName',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'potassiumMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protein');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingSize');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByServingUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingUnit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodiumMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sugar');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminCMg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminDMcg');
    });
  }

  QueryBuilder<FoodEntry, FoodEntry, QDistinct> distinctByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zincMg');
    });
  }
}

extension FoodEntryQueryProperty
    on QueryBuilder<FoodEntry, FoodEntry, QQueryProperty> {
  QueryBuilder<FoodEntry, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> calciumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calciumMg');
    });
  }

  QueryBuilder<FoodEntry, double, QQueryOperations> caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<FoodEntry, double, QQueryOperations> carbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbs');
    });
  }

  QueryBuilder<FoodEntry, double, QQueryOperations> fatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fat');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> fibreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fibre');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> folateMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folateMcg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> ironMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ironMg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> magnesiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'magnesiumMg');
    });
  }

  QueryBuilder<FoodEntry, String?, QQueryOperations> mealGroupEmojiProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealGroupEmoji');
    });
  }

  QueryBuilder<FoodEntry, String?, QQueryOperations> mealGroupIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealGroupId');
    });
  }

  QueryBuilder<FoodEntry, String?, QQueryOperations> mealGroupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealGroupName');
    });
  }

  QueryBuilder<FoodEntry, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> potassiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'potassiumMg');
    });
  }

  QueryBuilder<FoodEntry, double, QQueryOperations> proteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protein');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> servingSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingSize');
    });
  }

  QueryBuilder<FoodEntry, String?, QQueryOperations> servingUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingUnit');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> sodiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodiumMg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> sugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sugar');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> vitaminB12McgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> vitaminCMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminCMg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> vitaminDMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminDMcg');
    });
  }

  QueryBuilder<FoodEntry, double?, QQueryOperations> zincMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zincMg');
    });
  }
}
