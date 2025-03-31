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
      return val; // Return the value directly with its original type
    }
    throw ArgumentError('Invalid: $val');
  }

  bool _ok(dynamic val) =>
      _v.contains(val) ||
      _t.contains(val) || // Add this to accept Type objects directly
      _t.any(_match(val)) ||
      _v.any(_eq(val));

  bool Function(Type) _match(dynamic val) =>
      (t) =>
          t == dynamic ||
          val.runtimeType == t ||
          switch (val) {
            int _ => t == int,
            double _ => t == double,
            String _ => t == String,
            bool _ => t == bool,
            List _ => t == List,
            Map _ => t == Map,
            Set _ => t == Set,
            _ => false,
          };

  bool Function(dynamic) _eq(dynamic a) =>
      (b) =>
          identical(a, b) ||
          a == b ||
          switch (a) {
            List(length: var n) when b is List =>
              n == b.length &&
                  a.asMap().entries.every((e) => _eq(e.value)(b[e.key])),
            Map(length: var n) when b is Map =>
              n == b.length &&
                  a.keys.every((k) => b.containsKey(k) && _eq(a[k])(b[k])),
            Set(length: var n) when b is Set =>
              n == b.length && a.every(b.contains),
            _ => false,
          };
}
