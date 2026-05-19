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

  /// One-decimal, ".0" stripped. Includes unit suffix.
  /// e.g. `kg = 70`, metric → "70 kg"; `kg = 70.5`, imperial → "155.4 lbs".
  static String formatWeight(double kg, UnitSystem units) {
    final unit = units == UnitSystem.imperial ? 'lbs' : 'kg';
    return '${formatWeightValue(kg, units)} $unit';
  }

  /// Numeric portion only — one decimal place, with a trailing ".0" stripped
  /// so "70 kg" reads cleanly while "72.5 kg" keeps its decimal.
  static String formatWeightValue(double kg, UnitSystem units) {
    final val = units == UnitSystem.imperial ? kgToLbs(kg) : kg;
    final s = val.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
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

  // ───────────────────────────────────────────────────────────────────
  //  Height — robust user-input handling
  // ───────────────────────────────────────────────────────────────────

  /// Parses an Imperial height string and returns centimeters.
  /// Accepts:
  ///   * `6'1"`, `6'1`, `6' 1"`, `6' 1` — feet + inches
  ///   * `6'` — bare feet
  ///   * `73`, `73in`, `73"` — total inches (only when ≥ 12 and ≤ 108)
  /// Returns `null` when the string can't be parsed or the inches portion
  /// is out of range.
  ///
  /// Inches above 11 within an explicit feet'inches' pattern are rejected
  /// (i.e. "6'15\"" is invalid) — those are user typos.
  static double? parseImperialHeight(String input) {
    // Normalise unicode quote variants to ASCII so the regexes can stay
    // simple. U+2019 → ' , U+201B → ' , U+201C/D → " .
    var trimmed = input
        .trim()
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('‛', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('in', '');
    if (trimmed.isEmpty) return null;

    // feet (digits) ' inches (optional digits) (optional " or '')
    // The character class `['"]*` swallows a trailing inch-mark which may be
    // ASCII `"`, an empty string, or two apostrophes (a common keyboard
    // workaround for `"`).
    final ftInRe = RegExp(r"^(\d+)\s*'\s*(\d{0,2})\s*[\x22']*$");
    final match = ftInRe.firstMatch(trimmed);
    if (match != null) {
      final feet = int.tryParse(match.group(1) ?? '');
      final inchesStr = match.group(2) ?? '';
      final inches = inchesStr.isEmpty ? 0 : int.tryParse(inchesStr);
      if (feet != null && inches != null && inches >= 0 && inches < 12) {
        final totalInches = feet * 12 + inches;
        return totalInches * 2.54;
      }
      return null;
    }

    // Bare number — interpret as total inches if in a plausible range.
    final bareNumberRe = RegExp(r'^(\d+(?:\.\d+)?)\s*["\x27]*$');
    final bareMatch = bareNumberRe.firstMatch(trimmed);
    if (bareMatch != null) {
      final plain = double.tryParse(bareMatch.group(1) ?? '');
      if (plain != null && plain >= 12 && plain <= 108) {
        return plain * 2.54;
      }
    }
    return null;
  }

  /// Converts a stored centimeter value to the user-facing display string.
  /// Imperial → `6'1"`, Metric → `185 cm`.
  static String heightToDisplay(double cm, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      final totalInches = (cm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      // Roll over edge case: 11.6 → rounds to 12 → display as +1 foot, 0 in
      if (inches == 12) return "${feet + 1}'0\"";
      return "$feet'$inches\"";
    }
    return '${cm.round()} cm';
  }

  /// Converts a height user-input string to centimeters for storage. Handles
  /// the Imperial feet'inches' format and plain numbers in either system.
  /// Returns `null` when the input can't be parsed.
  static double? displayHeightToCm(String input, UnitSystem units) {
    if (units == UnitSystem.imperial) {
      return parseImperialHeight(input);
    }
    // Metric — strip any unit suffix and parse as a positive number.
    final cleaned =
        input.trim().toLowerCase().replaceAll('cm', '').trim();
    final cm = double.tryParse(cleaned);
    if (cm == null || cm <= 0) return null;
    return cm;
  }
}
