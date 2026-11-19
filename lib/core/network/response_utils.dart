Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    final data = value['data'];
    if (data is Map) return data.cast<String, dynamic>();
    return value;
  }
  if (value is Map) {
    final data = value['data'];
    if (data is Map) return data.cast<String, dynamic>();
    return value.cast<String, dynamic>();
  }
  return const {};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  if (value is Map) {
    final data = value['data'];
    if (data is List) return data;
    for (final key in const ['items', 'results', 'records']) {
      if (value[key] is List) return value[key] as List;
    }
  }
  return const [];
}

Map<String, dynamic> mapOf(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : const {};
