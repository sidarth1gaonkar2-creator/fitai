// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_meal_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSavedMealItemCollection on Isar {
  IsarCollection<SavedMealItem> get savedMealItems => this.collection();
}

const SavedMealItemSchema = CollectionSchema(
  name: r'SavedMealItem',
  id: -2258235427730038251,
  properties: {
    r'barcode': PropertySchema(
      id: 0,
      name: r'barcode',
      type: IsarType.string,
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
    r'fdcId': PropertySchema(
      id: 4,
      name: r'fdcId',
      type: IsarType.string,
    ),
    r'fiber': PropertySchema(
      id: 5,
      name: r'fiber',
      type: IsarType.double,
    ),
    r'foodName': PropertySchema(
      id: 6,
      name: r'foodName',
      type: IsarType.string,
    ),
    r'protein': PropertySchema(
      id: 7,
      name: r'protein',
      type: IsarType.double,
    ),
    r'quantity': PropertySchema(
      id: 8,
      name: r'quantity',
      type: IsarType.double,
    ),
    r'savedMealId': PropertySchema(
      id: 9,
      name: r'savedMealId',
      type: IsarType.long,
    ),
    r'servingSize': PropertySchema(
      id: 10,
      name: r'servingSize',
      type: IsarType.double,
    ),
    r'servingUnit': PropertySchema(
      id: 11,
      name: r'servingUnit',
      type: IsarType.string,
    ),
    r'sodium': PropertySchema(
      id: 12,
      name: r'sodium',
      type: IsarType.double,
    ),
    r'sugar': PropertySchema(
      id: 13,
      name: r'sugar',
      type: IsarType.double,
    )
  },
  estimateSize: _savedMealItemEstimateSize,
  serialize: _savedMealItemSerialize,
  deserialize: _savedMealItemDeserialize,
  deserializeProp: _savedMealItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'savedMealId': IndexSchema(
      id: 362762642621346104,
      name: r'savedMealId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'savedMealId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _savedMealItemGetId,
  getLinks: _savedMealItemGetLinks,
  attach: _savedMealItemAttach,
  version: '3.1.0+1',
);

int _savedMealItemEstimateSize(
  SavedMealItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.barcode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.fdcId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.foodName.length * 3;
  bytesCount += 3 + object.servingUnit.length * 3;
  return bytesCount;
}

void _savedMealItemSerialize(
  SavedMealItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.barcode);
  writer.writeDouble(offsets[1], object.calories);
  writer.writeDouble(offsets[2], object.carbs);
  writer.writeDouble(offsets[3], object.fat);
  writer.writeString(offsets[4], object.fdcId);
  writer.writeDouble(offsets[5], object.fiber);
  writer.writeString(offsets[6], object.foodName);
  writer.writeDouble(offsets[7], object.protein);
  writer.writeDouble(offsets[8], object.quantity);
  writer.writeLong(offsets[9], object.savedMealId);
  writer.writeDouble(offsets[10], object.servingSize);
  writer.writeString(offsets[11], object.servingUnit);
  writer.writeDouble(offsets[12], object.sodium);
  writer.writeDouble(offsets[13], object.sugar);
}

SavedMealItem _savedMealItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SavedMealItem();
  object.barcode = reader.readStringOrNull(offsets[0]);
  object.calories = reader.readDouble(offsets[1]);
  object.carbs = reader.readDouble(offsets[2]);
  object.fat = reader.readDouble(offsets[3]);
  object.fdcId = reader.readStringOrNull(offsets[4]);
  object.fiber = reader.readDoubleOrNull(offsets[5]);
  object.foodName = reader.readString(offsets[6]);
  object.id = id;
  object.protein = reader.readDouble(offsets[7]);
  object.quantity = reader.readDouble(offsets[8]);
  object.savedMealId = reader.readLong(offsets[9]);
  object.servingSize = reader.readDouble(offsets[10]);
  object.servingUnit = reader.readString(offsets[11]);
  object.sodium = reader.readDoubleOrNull(offsets[12]);
  object.sugar = reader.readDoubleOrNull(offsets[13]);
  return object;
}

P _savedMealItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readDouble(offset)) as P;
    case 8:
      return (reader.readDouble(offset)) as P;
    case 9:
      return (reader.readLong(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _savedMealItemGetId(SavedMealItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _savedMealItemGetLinks(SavedMealItem object) {
  return [];
}

void _savedMealItemAttach(
    IsarCollection<dynamic> col, Id id, SavedMealItem object) {
  object.id = id;
}

extension SavedMealItemQueryWhereSort
    on QueryBuilder<SavedMealItem, SavedMealItem, QWhere> {
  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhere> anySavedMealId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'savedMealId'),
      );
    });
  }
}

extension SavedMealItemQueryWhere
    on QueryBuilder<SavedMealItem, SavedMealItem, QWhereClause> {
  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause>
      savedMealIdEqualTo(int savedMealId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'savedMealId',
        value: [savedMealId],
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause>
      savedMealIdNotEqualTo(int savedMealId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'savedMealId',
              lower: [],
              upper: [savedMealId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'savedMealId',
              lower: [savedMealId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'savedMealId',
              lower: [savedMealId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'savedMealId',
              lower: [],
              upper: [savedMealId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause>
      savedMealIdGreaterThan(
    int savedMealId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'savedMealId',
        lower: [savedMealId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause>
      savedMealIdLessThan(
    int savedMealId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'savedMealId',
        lower: [],
        upper: [savedMealId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterWhereClause>
      savedMealIdBetween(
    int lowerSavedMealId,
    int upperSavedMealId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'savedMealId',
        lower: [lowerSavedMealId],
        includeLower: includeLower,
        upper: [upperSavedMealId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SavedMealItemQueryFilter
    on QueryBuilder<SavedMealItem, SavedMealItem, QFilterCondition> {
  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'barcode',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'barcode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'barcode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'barcode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      barcodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'barcode',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> fatEqualTo(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> fatLessThan(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> fatBetween(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fdcId',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fdcId',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fdcId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fdcId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fdcId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fdcId',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fdcIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fdcId',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'fiber',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'fiber',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fiber',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      fiberBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fiber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'foodName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'foodName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'foodName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'foodName',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      foodNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'foodName',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      quantityEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      quantityGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      quantityLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      quantityBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      savedMealIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'savedMealId',
        value: value,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      savedMealIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'savedMealId',
        value: value,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      savedMealIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'savedMealId',
        value: value,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      savedMealIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'savedMealId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingSizeEqualTo(
    double value, {
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingSizeGreaterThan(
    double value, {
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingSizeLessThan(
    double value, {
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingSizeBetween(
    double lower,
    double upper, {
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingUnitContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'servingUnit',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingUnitMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'servingUnit',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingUnitIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      servingUnitIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'servingUnit',
        value: '',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sodium',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sodium',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sodium',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sodium',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sodium',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sodiumBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sodium',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sugarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
      sugarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sugar',
      ));
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterFilterCondition>
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
}

extension SavedMealItemQueryObject
    on QueryBuilder<SavedMealItem, SavedMealItem, QFilterCondition> {}

extension SavedMealItemQueryLinks
    on QueryBuilder<SavedMealItem, SavedMealItem, QFilterCondition> {}

extension SavedMealItemQuerySortBy
    on QueryBuilder<SavedMealItem, SavedMealItem, QSortBy> {
  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFdcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fdcId', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFdcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fdcId', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFiberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByFoodName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortByFoodNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortBySavedMealId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedMealId', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortBySavedMealIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedMealId', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      sortByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortBySodium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodium', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortBySodiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodium', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> sortBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }
}

extension SavedMealItemQuerySortThenBy
    on QueryBuilder<SavedMealItem, SavedMealItem, QSortThenBy> {
  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByBarcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByBarcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'barcode', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenByCaloriesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'calories', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByCarbsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'carbs', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fat', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFdcId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fdcId', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFdcIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fdcId', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFiberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fiber', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByFoodName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenByFoodNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foodName', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByProteinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protein', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenBySavedMealId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedMealId', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenBySavedMealIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedMealId', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenByServingSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingSize', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenByServingUnit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy>
      thenByServingUnitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'servingUnit', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenBySodium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodium', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenBySodiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sodium', Sort.desc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.asc);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QAfterSortBy> thenBySugarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sugar', Sort.desc);
    });
  }
}

extension SavedMealItemQueryWhereDistinct
    on QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> {
  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByBarcode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'barcode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByCalories() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'calories');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByCarbs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'carbs');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByFat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fat');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByFdcId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fdcId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByFiber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fiber');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByFoodName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'foodName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByProtein() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protein');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct>
      distinctBySavedMealId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedMealId');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct>
      distinctByServingSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingSize');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctByServingUnit(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'servingUnit', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctBySodium() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sodium');
    });
  }

  QueryBuilder<SavedMealItem, SavedMealItem, QDistinct> distinctBySugar() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sugar');
    });
  }
}

extension SavedMealItemQueryProperty
    on QueryBuilder<SavedMealItem, SavedMealItem, QQueryProperty> {
  QueryBuilder<SavedMealItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SavedMealItem, String?, QQueryOperations> barcodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'barcode');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> caloriesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'calories');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> carbsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'carbs');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> fatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fat');
    });
  }

  QueryBuilder<SavedMealItem, String?, QQueryOperations> fdcIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fdcId');
    });
  }

  QueryBuilder<SavedMealItem, double?, QQueryOperations> fiberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fiber');
    });
  }

  QueryBuilder<SavedMealItem, String, QQueryOperations> foodNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'foodName');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> proteinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protein');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<SavedMealItem, int, QQueryOperations> savedMealIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedMealId');
    });
  }

  QueryBuilder<SavedMealItem, double, QQueryOperations> servingSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingSize');
    });
  }

  QueryBuilder<SavedMealItem, String, QQueryOperations> servingUnitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'servingUnit');
    });
  }

  QueryBuilder<SavedMealItem, double?, QQueryOperations> sodiumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sodium');
    });
  }

  QueryBuilder<SavedMealItem, double?, QQueryOperations> sugarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sugar');
    });
  }
}
