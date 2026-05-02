import 'package:flutter/widgets.dart';

ImageProvider? platformProfileImageProvider(String? photoUri) {
  final trimmed = photoUri?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(trimmed);
  }
  return null;
}
