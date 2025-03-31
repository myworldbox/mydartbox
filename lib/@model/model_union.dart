/*
Implementation of Checker for Runtime ModelUnion Types & Values
*/

class ModelUnion {
  final List<Type> allowedTypes;
  final Set<dynamic> allowedValues;
  final dynamic _value;
  final bool _hasValue;

  const ModelUnion._(this.allowedTypes, this.allowedValues)
      : _value = null,
        _hasValue = false;

  factory ModelUnion(List<dynamic> typesOrValues) {
    final types = <Type>{};
    final values = <dynamic>{};
    for (var element in typesOrValues) {
      if (element is Type) {
        types.add(element);
      } else {
        values.add(element);
      }
    }
    return ModelUnion._(List<Type>.from(types), values);
  }

  ModelUnion._forValue(this.allowedTypes, this.allowedValues, dynamic value)
      : _value = value,
        _hasValue = true {
    if (!_isValid(value)) {
      throw ArgumentError(
          'Value "$value" must match one of: $allowedValues or a type in $allowedTypes');
    }
  }

  ModelUnion call(dynamic value) =>
      ModelUnion._forValue(allowedTypes, allowedValues, value);

  bool _isValid(dynamic value) {
    if (allowedValues.contains(value)) return true;

    for (var type in allowedTypes) {
      if (_matchesType(value, type)) return true;
    }

    for (var allowedValue in allowedValues) {
      if (_deepEquals(value, allowedValue)) return true;
    }

    return false;
  }

  bool _matchesType(dynamic value, Type type) {
    if (type == dynamic) return true; // Accept any value if type is dynamic
    if (value.runtimeType == type) return true;

    String typeStr = type.toString();

    if (typeStr.startsWith('List<') && value is List) {
      return _validateNestedList(value, typeStr);
    }
    if (typeStr.startsWith('Map<') && value is Map) {
      return _validateNestedMap(value, typeStr);
    }
    if (typeStr.startsWith('Set<') && value is Set) {
      return _validateNestedSet(value, typeStr);
    }

    // Fallback for basic collections
    if (type == List && value is List) return true;
    if (type == Map && value is Map) return true;
    if (type == Set && value is Set) return true;

    return false;
  }

  bool _validateNestedList(List<dynamic> list, String typeStr) {
    if (typeStr == 'List<dynamic>' || typeStr == 'List') return true;

    // Extract inner type (e.g., "List<int>" -> "int")
    final innerTypeStr = typeStr.substring(5, typeStr.length - 1);
    for (var item in list) {
      if (!_matchesTypeString(item, innerTypeStr)) return false;
    }
    return true;
  }

  bool _validateNestedMap(Map<dynamic, dynamic> map, String typeStr) {
    if (typeStr == 'Map<dynamic, dynamic>' || typeStr == 'Map') return true;

    // Extract key and value types (e.g., "Map<String, int>" -> "String" and "int")
    final match = RegExp(r'Map<([^,]+),\s*([^>]+)>').firstMatch(typeStr);
    if (match == null) return false;
    final keyTypeStr = match.group(1)!.trim();
    final valueTypeStr = match.group(2)!.trim();

    for (var entry in map.entries) {
      if (!_matchesTypeString(entry.key, keyTypeStr) ||
          !_matchesTypeString(entry.value, valueTypeStr)) {
        return false;
      }
    }
    return true;
  }

  bool _validateNestedSet(Set<dynamic> set, String typeStr) {
    if (typeStr == 'Set<dynamic>' || typeStr == 'Set') return true;

    final innerTypeStr = typeStr.substring(4, typeStr.length - 1);
    for (var item in set) {
      if (!_matchesTypeString(item, innerTypeStr)) return false;
    }
    return true;
  }

  bool _matchesTypeString(dynamic value, String typeStr) {
    // Handle primitive types
    switch (typeStr) {
      case 'int':
        return value is int;
      case 'double':
        return value is double;
      case 'String':
        return value is String;
      case 'bool':
        return value is bool;
    }

    // Handle nested generic types recursively
    if (typeStr.startsWith('List<')) {
      return value is List && _validateNestedList(value, typeStr);
    }
    if (typeStr.startsWith('Map<')) {
      return value is Map && _validateNestedMap(value, typeStr);
    }
    if (typeStr.startsWith('Set<')) {
      return value is Set && _validateNestedSet(value, typeStr);
    }

    // Fallback: attempt to match runtime type
    return value.runtimeType.toString() == typeStr;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (var key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is Set && b is Set) {
      if (a.length != b.length) return false;
      return a.every((e) => b.contains(e));
    }
    return false;
  }

  @override
  String toString() {
    if (!_hasValue) throw StateError('No value stored');
    return _value.toString();
  }
}