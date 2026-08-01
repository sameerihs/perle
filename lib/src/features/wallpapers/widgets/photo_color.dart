import 'package:flutter/material.dart';

Color photoPlaceholderColor(String? hex) {
  if (hex == null) {
    return const Color(0xFF242428);
  }

  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) {
    return const Color(0xFF242428);
  }

  final value = int.tryParse(normalized, radix: 16);
  return value == null ? const Color(0xFF242428) : Color(0xFF000000 | value);
}
