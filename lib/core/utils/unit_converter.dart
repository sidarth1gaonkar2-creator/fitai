enum UnitSystem { metric, imperial }

class UnitConverter {
  const UnitConverter._();

  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;

  static String cmToFtIn(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    if (inches == 12) return "${feet + 1}'0\"";
    return "$feet'$inches\"";
  }

  static double ftInToCm(String ftIn) {
    final match = RegExp(r"(\d+)'(\d+)").firstMatch(ftIn);
    if (match == null) return 170;
    final feet = int.parse(match.group(1)!);
    final inches = int.parse(match.group(2)!);
    return (feet * 12 + inches) * 2.54;
  }

  static String formatWeight(double kg, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      return '${kgToLbs(kg).round()} lbs';
    }
    return '${kg.round()} kg';
  }

  static String formatWeightValue(double kg, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      return kgToLbs(kg).toStringAsFixed(1);
    }
    return kg.toStringAsFixed(1);
  }

  static String weightUnit(UnitSystem units) =>
      units == UnitSystem.imperial ? 'lbs' : 'kg';

  static String formatHeight(double cm, UnitSystem units) {
    if (units == UnitSystem.imperial) return cmToFtIn(cm);
    return '${cm.round()} cm';
  }

  /// Converts a display-weight value back to kg for storage.
  static double displayWeightToKg(double displayValue, UnitSystem units) {
    if (units == UnitSystem.imperial) return lbsToKg(displayValue);
    return displayValue;
  }

  /// Inverse of [displayWeightToKg] — converts a stored kg value into the
  /// numeric value to show the user. Imperial users see lbs, metric users
  /// see kg unchanged.
  static double kgToDisplayWeight(double kg, UnitSystem units) {
    if (units == UnitSystem.imperial) return kgToLbs(kg);
    return kg;
  }
}
