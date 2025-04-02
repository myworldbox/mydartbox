class ModelUnfold {
  final List<dynamic> _acceptTypes;
  final List<dynamic> _acceptValues;

  const ModelUnfold(this._acceptTypes, [this._acceptValues = const []]);

  T call<T>(T val) {
    if (_validate(val)) {
      return val;
    }

    // Generate detailed error message
    final receivedType = _getTypeDescription(val);
    final expectedTypes = _acceptTypes.map(_getTypeDescription).join(' or ');

    throw ArgumentError(
      'Received type: $receivedType\n'
      'Expected types: $expectedTypes',
    );
  }

  String _getTypeDescription(dynamic typeOrValue) {
    if (typeOrValue is Type) {
      return typeOrValue.toString();
    }
    if (typeOrValue is Map) {
      if (typeOrValue.isEmpty) return 'Map';
      final keyType = _getTypeDescription(typeOrValue.keys.first);
      final valueType = _getTypeDescription(typeOrValue.values.first);
      return 'Map<$keyType, $valueType>';
    }
    if (typeOrValue is List) {
      if (typeOrValue.isEmpty) return 'List';
      return 'List<${_getTypeDescription(typeOrValue.first)}>';
    }
    if (typeOrValue is Set) {
      if (typeOrValue.isEmpty) return 'Set';
      return 'Set<${_getTypeDescription(typeOrValue.first)}>';
    }
    return typeOrValue.runtimeType.toString();
  }

  bool _validate(dynamic val) {
    if (_acceptValues.any((v) => _deepEquals(v, val))) return true;
    return _acceptTypes.any((type) => _matchesType(val, type));
  }

  bool _matchesType(dynamic val, dynamic type) {
    if (type == dynamic) return true;
    if (type is Type && val.runtimeType == type) return true;

    if (type is Map && val is Map) {
      if (type.isEmpty) return true;
      return _matchesMap(val, type);
    }
    if (type is List && val is List) {
      if (type.isEmpty) return true;
      return _matchesList(val, type);
    }
    if (type is Set && val is Set) {
      if (type.isEmpty) return true;
      return _matchesSet(val, type);
    }

    return switch (val) {
      int _ => type == int,
      double _ => type == double,
      String _ => type == String,
      bool _ => type == bool,
      _ => false,
    };
  }

  bool _matchesMap(Map val, Map typeDef) {
    final keyType = typeDef.keys.first;
    final valueType = typeDef.values.first;

    return val.keys.every((k) => _matchesType(k, keyType)) &&
        val.values.every((v) => _matchesType(v, valueType));
  }

  bool _matchesList(List val, List typeDef) {
    final elementType = typeDef.first;
    return val.every((e) => _matchesType(e, elementType));
  }

  bool _matchesSet(Set val, Set typeDef) {
    final elementType = typeDef.first;
    return val.every((e) => _matchesType(e, elementType));
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == b) return true;

    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
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
      return a.every(b.contains);
    }

    return false;
  }
}