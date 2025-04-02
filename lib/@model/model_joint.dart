/**
 * 
 * Deep tyes are represented with String
 * 
*/

class ModelJoint {
  final Set<Type> _t;
  final Set _v;

  const ModelJoint._(this._t, this._v);

  factory ModelJoint(List items) => ModelJoint._(
    items.whereType<Type>().toSet(),
    items.where((e) => e is! Type).toSet(),
  );

  T call<T>(T val) {
    if (_ok(val)) {
      return val;
    }
    throw ArgumentError('Invalid: $val');
  }

  bool _ok(dynamic val) =>
      _v.contains(val) ||
      _t.any((t) => _match(val, t)) ||
      _v.any((v) => _eq(val, v));

  bool _match(dynamic val, Type t) {
    if (t == dynamic) return true;
    if (val.runtimeType == t) return true;

    // Handle generic types
    if (t.toString().startsWith('List<')) {
      return val is List && _checkList(val, t);
    }
    if (t.toString().startsWith('Map<')) {
      return val is Map && _checkMap(val, t);
    }
    if (t.toString().startsWith('Set<')) {
      return val is Set && _checkSet(val, t);
    }

    return switch (val) {
      int _ => t == int,
      double _ => t == double,
      String _ => t == String,
      bool _ => t == bool,
      _ => false,
    };
  }

  bool _checkList(List list, Type listType) {
    final elementType = _getTypeArgument(listType, 0);
    return elementType == null || list.every((e) => _match(e, elementType));
  }

  bool _checkMap(Map map, Type mapType) {
    final keyType = _getTypeArgument(mapType, 0);
    final valueType = _getTypeArgument(mapType, 1);
    return (keyType == null || map.keys.every((k) => _match(k, keyType))) &&
        (valueType == null || map.values.every((v) => _match(v, valueType)));
  }

  bool _checkSet(Set set, Type setType) {
    final elementType = _getTypeArgument(setType, 0);
    return elementType == null || set.every((e) => _match(e, elementType));
  }

  Type? _getTypeArgument(Type genericType, int index) {
    final typeArgs = genericType
        .toString()
        .split('<')
        .last
        .split('>')
        .first
        .split(',');
    if (index < typeArgs.length) {
      return _parseType(typeArgs[index].trim());
    }
    return null;
  }

  Type? _parseType(String typeName) {
    const types = {
      'String': String,
      'int': int,
      'double': double,
      'bool': bool,
      'List': List,
      'Map': Map,
      'Set': Set,
    };
    return types[typeName];
  }

  bool _eq(dynamic a, dynamic b) =>
      identical(a, b) ||
      a == b ||
      switch (a) {
        List(length: var n) when b is List =>
          n == b.length &&
              a.asMap().entries.every((e) => _eq(e.value, b[e.key])),
        Map(length: var n) when b is Map =>
          n == b.length &&
              a.keys.every((k) => b.containsKey(k) && _eq(a[k], b[k])),
        Set(length: var n) when b is Set =>
          n == b.length && a.every(b.contains),
        _ => false,
      };
}
