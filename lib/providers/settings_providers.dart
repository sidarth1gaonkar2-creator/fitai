import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-selected theme mode. Defaults to system.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
