/** 
 * 
 * Deeply nested types are not handled
 * 
*/

class ModelUnion {
  final Set<Type> _t;
  final Set _v;

  const ModelUnion._(this._t, this._v);

  factory ModelUnion(List items) => ModelUnion._(
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
    if (t == dynamic || val.runtimeType == t) return true;
    if (val is Type && _t.contains(val)) return true;

    return switch (val) {
      int _ => t == int,
      double _ => t == double,
      String _ => t == String,
      bool _ => t == bool,
      List list => _checkGeneric(list, t, List, _checkList),
      Map map => _checkGeneric(map, t, Map, _checkMap),
      Set set => _checkGeneric(set, t, Set, _checkSet),
      _ => false,
    };
  }

  bool _checkGeneric(dynamic val, Type expected, Type rawType, bool Function(dynamic, Type) checker) {
    if (expected == rawType) return true;
    if (val.runtimeType == rawType) {
      if (_t.contains(expected) && expected != rawType) {
        return checker(val, expected);
      }
      return true;
    }
    return val.runtimeType == expected;
  }

  bool _checkList(dynamic list, Type listType) {
    if (list is! List) return false;
    if (list.isEmpty) return true;

    // For a specific List type, check elements against the expected nested type
    if (listType == List) return true;
    return list.every((element) => _matchNested(element, listType));
  }

  bool _checkMap(dynamic map, Type mapType) {
    if (map is! Map) return false;
    if (map.isEmpty) return true;

    if (mapType == Map) return true;
    return map.keys.every((key) => _matchNested(key, mapType)) &&
           map.values.every((value) => _matchNested(value, mapType));
  }

  bool _checkSet(dynamic set, Type setType) {
    if (set is! Set) return false;
    if (set.isEmpty) return true;

    if (setType == Set) return true;
    return set.every((element) => _matchNested(element, setType));
  }

  bool _matchNested(dynamic val, Type expected) {
    // Check if val matches any type in _t that fits the expected structure
    if (_t.contains(expected) && val.runtimeType == expected) return true;

    // Recurse based on the expected type
    return switch (val) {
      String _ => _t.contains(String) && expected != Map && expected != List && expected != Set,
      int _ => _t.contains(int),
      double _ => _t.contains(double),
      bool _ => _t.contains(bool),
      List list => _checkGeneric(list, expected, List, _checkList),
      Map map => _checkGeneric(map, expected, Map, _checkMap),
      Set set => _checkGeneric(set, expected, Set, _checkSet),
      _ => false,
    };
  }

  bool _eq(dynamic a, dynamic b) =>
      identical(a, b) ||
      a == b ||
      switch (a) {
        List(length: var n) when b is List =>
          n == b.length && a.asMap().entries.every((e) => _eq(e.value, b[e.key])),
        Map(length: var n) when b is Map =>
          n == b.length && a.keys.every((k) => b.containsKey(k) && _eq(a[k], b[k])),
        Set(length: var n) when b is Set =>
          n == b.length && a.every(b.contains),
        _ => false,
      };
}