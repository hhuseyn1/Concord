extension JsonMapLookup on Map<String, dynamic> {
  dynamic field(String key) {
    if (containsKey(key)) return this[key];
    final lower = key.toLowerCase();
    for (final k in keys) {
      if (k.toLowerCase() == lower) return this[k];
    }
    return null;
  }
}

DateTime? parseNullableDateTime(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isEmpty) return null;
  return DateTime.parse(value as String);
}

DateTime parseDateTime(dynamic value) => DateTime.parse(value as String);

List<String> parseStringList(dynamic value) {
  if (value == null) return const [];
  return (value as List<dynamic>).map((e) => e as String).toList();
}
