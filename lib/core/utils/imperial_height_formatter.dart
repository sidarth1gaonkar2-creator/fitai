import 'package:flutter/services.dart';

/// Restricts a height TextField to characters that can be part of an
/// Imperial feet-inches input — digits, spaces, apostrophe `'`, double-quote
/// `"`, and the common unicode quote variants (`’`, `‛`, `“`, `”`).
///
/// This is purely a character allow-list; the actual parsing happens in
/// [UnitConverter.parseImperialHeight] when the form is submitted.
class ImperialHeightFormatter extends TextInputFormatter {
  // Matches a single character that should be PRESERVED.
  static final _allowed = RegExp(r"[\d\s'’‛\x22“”]");

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buf = StringBuffer();
    for (final ch in text.runes) {
      final s = String.fromCharCode(ch);
      if (_allowed.hasMatch(s)) buf.write(s);
    }
    final cleaned = buf.toString();
    if (cleaned == text) return newValue;
    // Preserve the user's caret as well as possible: clamp to the new length.
    final offset = newValue.selection.baseOffset
        .clamp(0, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
