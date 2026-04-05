String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

String? validatePositiveNumber(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final number = double.tryParse(value);
  if (number == null || number <= 0) {
    return '$fieldName must be a positive number';
  }
  return null;
}

String? validateAge(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Age is required';
  }
  final age = int.tryParse(value);
  if (age == null || age < 13 || age > 120) {
    return 'Age must be between 13 and 120';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Name is required';
  }
  final trimmed = value.trim();
  if (trimmed.length > 50) {
    return 'Name must be 50 characters or fewer';
  }
  if (RegExp(r'^\d+$').hasMatch(trimmed)) {
    return 'Name cannot be only digits';
  }
  return null;
}

String? validateWeight(String? value) {
  final base = validatePositiveNumber(value, 'Weight');
  if (base != null) return base;
  final weight = double.parse(value!);
  if (weight < 20 || weight > 300) {
    return 'Weight must be between 20 and 300 kg';
  }
  return null;
}

String? validateHeight(String? value) {
  final base = validatePositiveNumber(value, 'Height');
  if (base != null) return base;
  final height = double.parse(value!);
  if (height < 50 || height > 272) {
    return 'Height must be between 50 and 272 cm';
  }
  return null;
}
