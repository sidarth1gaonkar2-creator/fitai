// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_meal_plan_food.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomMealPlanFoodCollection on Isar {
  IsarCollection<CustomMealPlanFood> get customMealPlanFoods =>
      this.collection();
}

const CustomMealPlanFoodSchema = CollectionSchema(
  name: r'CustomMealPlanFood',
  id: 6056657830367134574,
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
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'potassiumMg': PropertySchema(
      id: 9,
      name: r'potassiumMg',
      type: IsarType.double,
    ),
    r'protein': PropertySchema(
      id: 10,
      name: r'protein',
      type: IsarType.double,
    ),
    r'servingSize': PropertySchema(
      id: 11,
      name: r'servingSize',
      type: IsarType.double,
    ),
    r'servingUnit': PropertySchema(
      id: 12,
      name: r'servingUnit',
      type: IsarType.string,
    ),
    r'sodiumMg': PropertySchema(
      id: 13,
      name: r'sodiumMg',
      type: IsarType.double,
    ),
    r'sugar': PropertySchema(
      id: 14,
      name: r'sugar',
      type: IsarType.double,
    ),
    r'vitaminB12Mcg': PropertySchema(
      id: 15,
      name: r'vitaminB12Mcg',
      type: IsarType.double,
    ),
    r'vitaminCMg': PropertySchema(
      id: 16,
      name: r'vitaminCMg',
      type: IsarType.double,
    ),
    r'vitaminDMcg': PropertySchema(
      id: 17,
      name: r'vitaminDMcg',
      type: IsarType.double,
    ),
    r'zincMg': PropertySchema(
      id: 18,
      name: r'zincMg',
      type: IsarType.double,
    )
  },
  estimateSize: _customMealPlanFoodEstimateSize,
  serialize: _customMealPlanFoodSerialize,
  deserialize: _customMealPlanFoodDeserialize,
  deserializeProp: _customMealPlanFoodDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'meal': LinkSchema(
      id: 9168698572867935582,
      name: r'meal',
      target: r'CustomMealPlanMeal',
      single: false,
      linkName: r'foods',
    )
  },
  embeddedSchemas: {},
  getId: _customMealPlanFoodGetId,
  getLinks: _customMealPlanFoodGetLinks,
  attach: _customMealPlanFoodAttach,
  version: '3.1.0+1',
);

int _customMealPlanFoodEstimateSize(
  CustomMealPlanFood object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.servingUnit;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _customMealPlanFoodSerialize(
  CustomMealPlanFood object,
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
  writer.writeString(offsets[8], object.name);
  writer.writeDouble(offsets[9], object.potassiumMg);
  writer.writeDouble(offsets[10], object.protein);
  writer.writeDouble(offsets[11], object.servingSize);
  writer.writeString(offsets[12], object.servingUnit);
  writer.writeDouble(offsets[13], object.sodiumMg);
  writer.writeDouble(offsets[14], object.sugar);
  writer.writeDouble(offsets[15], object.vitaminB12Mcg);
  writer.writeDouble(offsets[16], object.vitaminCMg);
  writer.writeDouble(offsets[17], object.vitaminDMcg);
  writer.writeDouble(offsets[18], object.zincMg);
}

CustomMealPlanFood _customMealPlanFoodDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomMealPlanFood();
  object.calciumMg = reader.readDoubleOrNull(offsets[0]);
  object.calories = reader.readDouble(offsets[1]);
  object.carbs = reader.readDouble(offsets[2]);
  object.fat = reader.readDouble(offsets[3]);
  object.fibre = reader.readDoubleOrNull(offsets[4]);
  object.folateMcg = reader.readDoubleOrNull(offsets[5]);
  object.id = id;
  object.ironMg = reader.readDoubleOrNull(offsets[6]);
  object.magnesiumMg = reader.readDoubleOrNull(offsets[7]);
  object.name = reader.readString(offsets[8]);
  object.potassiumMg = reader.readDoubleOrNull(offsets[9]);
  object.protein = reader.readDouble(offsets[10]);
  object.servingSize = reader.readDoubleOrNull(offsets[11]);
  object.servingUnit = reader.readStringOrNull(offsets[12]);
  object.sodiumMg = reader.readDoubleOrNull(offsets[13]);
  object.sugar = reader.readDoubleOrNull(offsets[14]);
  object.vitaminB12Mcg = reader.readDoubleOrNull(offsets[15]);
  object.vitaminCMg = reader.readDoubleOrNull(offsets[16]);
  object.vitaminDMcg = reader.readDoubleOrNull(offsets[17]);
  object.zincMg = reader.readDoubleOrNull(offsets[18]);
  return object;
}

P _customMealPlanFoodDeserializeProp<P>(
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
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDoubleOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _customMealPlanFoodGetId(CustomMealPlanFood object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customMealPlanFoodGetLinks(
    CustomMealPlanFood object) {
  return [object.meal];
}

void _customMealPlanFoodAttach(
    IsarCollection<dynamic> col, Id id, CustomMealPlanFood object) {
  object.id = id;
  object.meal
      .attach(col, col.isar.collection<CustomMealPlanMeal>(), r'meal', id);
}

extension CustomMealPlanFoodQueryWhereSort
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QWhere> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomMealPlanFoodQueryWhere
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QWhereClause> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterWhereClause>
      idBetween(
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

extension CustomMealPlanFoodQueryFilter
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QFilterCondition> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      calciumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      calciumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'calciumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      fibreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      fibreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fibre',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      folateMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      folateMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'folateMcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      ironMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      ironMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ironMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      magnesiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      magnesiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'magnesiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      potassiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      potassiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'potassiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingSizeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingSize',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingSizeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingSize',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingSizeEqualTo(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingSizeLessThan(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingSizeBetween(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'servingUnit',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'servingUnit',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitEqualTo(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitLessThan(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitBetween(
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'servingUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      servingUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      sodiumMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      sodiumMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sodiumMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      sugarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      sugarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminB12McgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminB12McgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminB12Mcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminCMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminCMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminCMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminDMcgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      vitaminDMcgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'vitaminDMcg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      zincMgIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      zincMgIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'zincMg',
      ));
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
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

extension CustomMealPlanFoodQueryObject
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QFilterCondition> {}

extension CustomMealPlanFoodQueryLinks
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QFilterCondition> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      meal(FilterQuery<CustomMealPlanMeal> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'meal');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', length, true, length, true);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, true, 0, true);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, false, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', 0, true, length, include);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'meal', length, include, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterFilterCondition>
      mealLengthBetween(
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

extension CustomMealPlanFoodQuerySortBy
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QSortBy> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      sortByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension CustomMealPlanFoodQuerySortThenBy
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QSortThenBy> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCalciumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calciumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFibreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fibre', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByFolateMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'folateMcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByIronMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ironMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByMagnesiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'magnesiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByPotassiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'potassiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenBySodiumMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodiumMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminB12McgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminB12Mcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminCMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminCMg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByVitaminDMcgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vitaminDMcg', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QAfterSortBy>
      thenByZincMgDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zincMg', Sort.desc);
    });
  }
}

extension CustomMealPlanFoodQueryWhereDistinct
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct> {
  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByCalciumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calciumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbs');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fat');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByFibre() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fibre');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByFolateMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'folateMcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByIronMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ironMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByMagnesiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'magnesiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByPotassiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'potassiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protein');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingSize');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByServingUnit({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingUnit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctBySodiumMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sugar');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByVitaminB12Mcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByVitaminCMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminCMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByVitaminDMcg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vitaminDMcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QDistinct>
      distinctByZincMg() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zincMg');
    });
  }
}

extension CustomMealPlanFoodQueryProperty
    on QueryBuilder<CustomMealPlanFood, CustomMealPlanFood, QQueryProperty> {
  QueryBuilder<CustomMealPlanFood, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      calciumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calciumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double, QQueryOperations>
      caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<CustomMealPlanFood, double, QQueryOperations> carbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbs');
    });
  }

  QueryBuilder<CustomMealPlanFood, double, QQueryOperations> fatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fat');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations> fibreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fibre');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      folateMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'folateMcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations> ironMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ironMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      magnesiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'magnesiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      potassiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'potassiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double, QQueryOperations> proteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protein');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      servingSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingSize');
    });
  }

  QueryBuilder<CustomMealPlanFood, String?, QQueryOperations>
      servingUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingUnit');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      sodiumMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodiumMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations> sugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sugar');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      vitaminB12McgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminB12Mcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      vitaminCMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminCMg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations>
      vitaminDMcgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vitaminDMcg');
    });
  }

  QueryBuilder<CustomMealPlanFood, double?, QQueryOperations> zincMgProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zincMg');
    });
  }
}
