// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_meal_plan_meal.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCustomMealPlanMealCollection on Isar {
  IsarCollection<CustomMealPlanMeal> get customMealPlanMeals =>
      this.collection();
}

const CustomMealPlanMealSchema = CollectionSchema(
  name: r'CustomMealPlanMeal',
  id: -5600651620525128052,
  properties: {
    r'mealType': PropertySchema(
      id: 0,
      name: r'mealType',
      type: IsarType.byte,
      enumMap: _CustomMealPlanMealmealTypeEnumValueMap,
    )
  },
  estimateSize: _customMealPlanMealEstimateSize,
  serialize: _customMealPlanMealSerialize,
  deserialize: _customMealPlanMealDeserialize,
  deserializeProp: _customMealPlanMealDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'foods': LinkSchema(
      id: 309432047786976150,
      name: r'foods',
      target: r'CustomMealPlanFood',
      single: false,
    ),
    r'plan': LinkSchema(
      id: -837100474178882617,
      name: r'plan',
      target: r'CustomMealPlan',
      single: false,
      linkName: r'meals',
    )
  },
  embeddedSchemas: {},
  getId: _customMealPlanMealGetId,
  getLinks: _customMealPlanMealGetLinks,
  attach: _customMealPlanMealAttach,
  version: '3.1.0+1',
);

int _customMealPlanMealEstimateSize(
  CustomMealPlanMeal object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _customMealPlanMealSerialize(
  CustomMealPlanMeal object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.mealType.index);
}

CustomMealPlanMeal _customMealPlanMealDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CustomMealPlanMeal();
  object.id = id;
  object.mealType = _CustomMealPlanMealmealTypeValueEnumMap[
          reader.readByteOrNull(offsets[0])] ??
      MealType.breakfast;
  return object;
}

P _customMealPlanMealDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_CustomMealPlanMealmealTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          MealType.breakfast) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CustomMealPlanMealmealTypeEnumValueMap = {
  'breakfast': 0,
  'lunch': 1,
  'dinner': 2,
  'snack': 3,
};
const _CustomMealPlanMealmealTypeValueEnumMap = {
  0: MealType.breakfast,
  1: MealType.lunch,
  2: MealType.dinner,
  3: MealType.snack,
};

Id _customMealPlanMealGetId(CustomMealPlanMeal object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _customMealPlanMealGetLinks(
    CustomMealPlanMeal object) {
  return [object.foods, object.plan];
}

void _customMealPlanMealAttach(
    IsarCollection<dynamic> col, Id id, CustomMealPlanMeal object) {
  object.id = id;
  object.foods
      .attach(col, col.isar.collection<CustomMealPlanFood>(), r'foods', id);
  object.plan.attach(col, col.isar.collection<CustomMealPlan>(), r'plan', id);
}

extension CustomMealPlanMealQueryWhereSort
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QWhere> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CustomMealPlanMealQueryWhere
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QWhereClause> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhereClause>
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

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterWhereClause>
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

extension CustomMealPlanMealQueryFilter
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QFilterCondition> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
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

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      mealTypeEqualTo(MealType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mealType',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      mealTypeGreaterThan(
    MealType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mealType',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      mealTypeLessThan(
    MealType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mealType',
        value: value,
      ));
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      mealTypeBetween(
    MealType lower,
    MealType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mealType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CustomMealPlanMealQueryObject
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QFilterCondition> {}

extension CustomMealPlanMealQueryLinks
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QFilterCondition> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foods(FilterQuery<CustomMealPlanFood> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'foods');
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'foods', length, true, length, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'foods', 0, true, 0, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'foods', 0, false, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'foods', 0, true, length, include);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'foods', length, include, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      foodsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'foods', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      plan(FilterQuery<CustomMealPlan> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'plan');
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', length, true, length, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', 0, true, 0, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', 0, false, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', 0, true, length, include);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'plan', length, include, 999999, true);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterFilterCondition>
      planLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'plan', lower, includeLower, upper, includeUpper);
    });
  }
}

extension CustomMealPlanMealQuerySortBy
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QSortBy> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      sortByMealType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      sortByMealTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.desc);
    });
  }
}

extension CustomMealPlanMealQuerySortThenBy
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QSortThenBy> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      thenByMealType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.asc);
    });
  }

  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QAfterSortBy>
      thenByMealTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mealType', Sort.desc);
    });
  }
}

extension CustomMealPlanMealQueryWhereDistinct
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QDistinct> {
  QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QDistinct>
      distinctByMealType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mealType');
    });
  }
}

extension CustomMealPlanMealQueryProperty
    on QueryBuilder<CustomMealPlanMeal, CustomMealPlanMeal, QQueryProperty> {
  QueryBuilder<CustomMealPlanMeal, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CustomMealPlanMeal, MealType, QQueryOperations>
      mealTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mealType');
    });
  }
}
