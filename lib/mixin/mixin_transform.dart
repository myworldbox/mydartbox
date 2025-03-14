import 'dart:convert';

mixin MixinTransform {
  // Get an object at a nested node (e.g., "a.b.c")
  Future<Map<String, dynamic>?> getObjAtNode(
    String node,
    dynamic object,
  ) async {
    final keys = node.split('.');
    dynamic current = object;
    for (final key in keys) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current is Map<String, dynamic> ? current : null;
  }

  // Set a value at a nested node (e.g., "a.b.c")
  Future<Map<String, dynamic>> setObjAtNode(
    String node,
    Map<String, dynamic> object,
    dynamic value,
  ) async {
    final keys = node.split('.');
    dynamic current = object;

    for (final key in keys.sublist(0, keys.length - 1)) {
      current[key] ??= <String, dynamic>{}; // Create an empty map if null
      if (current[key] is! Map) {
        current[key] = <String, dynamic>{}; // Overwrite if not an object
      }
      current = current[key];
    }

    current[keys.last] = value;
    return object;
  }

  // Convert an array to JSON-like list of maps
  List<Map<String, dynamic>> arrayToJson(List<dynamic> array) {
    if (array.isEmpty) return [];
    final cols = array.first as List<dynamic>;
    final rows = array.sublist(1);
    return rows.map((row) {
      return Map.fromEntries(
        cols
            .asMap()
            .entries
            .map((entry) {
              final col = entry.value;
              final i = entry.key;
              return MapEntry(col.toString(), row[i]);
            })
            .where((entry) => entry.value != null),
      );
    }).toList();
  }

  // Filter an object based on another object
  Map<String, dynamic> objectFilter(
    Map<String, dynamic> original,
    Map<String, dynamic> filter,
  ) {
    return filter.keys.fold<Map<String, dynamic>>({}, (acc, key) {
      if (original.containsKey(key)) {
        if (filter[key] is List && original[key] is List) {
          acc[key] = filter[key];
        } else if (filter[key] is Map &&
            original[key] is Map &&
            filter[key] != null &&
            original[key] != null) {
          acc[key] = objectFilter(
            original[key] as Map<String, dynamic>,
            filter[key] as Map<String, dynamic>,
          );
        } else {
          acc[key] = filter[key];
        }
      }
      return acc;
    });
  }

  // Remove a pattern at a specific index
  String removePatternAtIndex(String text, String pattern, int index) {
    final i = index < 0 ? text.length + index : index;
    if (i < 0 || i > text.length - pattern.length) return text;
    return text.substring(0, i) + text.substring(i + pattern.length);
  }

  // Repeat and trim a string to a specific length
  String repeatTrim(String text, int length) {
    if (text.length == length) return text;
    final repeated = text * (length / text.length).ceil();
    return repeated.substring(0, length);
  }

  // Convert a JSON object to a list of strings
  List<String> jsonToArray(Map<String, dynamic> json) {
    return json.values.map((v) => v is String ? v : jsonEncode(v)).toList();
  }

  // Replace all occurrences of patternA with patternB
  String patternAToB(String text, String patternA, String patternB) {
    return text.replaceAll(patternA, patternB);
  }

  // Capitalize a word at a specific index
  String capitalizeAtIndex(String str, int index) {
    final words = str.split(' ');
    final i = index < 0 ? words.length + index : index;
    if (i < 0 || i >= words.length) return str;
    return words
        .asMap()
        .entries
        .map((entry) {
          final j = entry.key;
          final w = entry.value;
          return j == i ? w[0].toUpperCase() + w.substring(1) : w;
        })
        .join(' ');
  }
}
