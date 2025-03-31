class ModelUnion {
  final Set<Type> _t;
  final Set _v;
  final dynamic _val;
  final bool _has;

  const ModelUnion._(this._t, this._v) : _val = null, _has = false;

  factory ModelUnion(List items) => ModelUnion._(
    items.whereType<Type>().toSet(),
    items.where((e) => e is! Type).toSet(),
  );

  const ModelUnion._v(this._t, this._v, this._val) : _has = true;

  ModelUnion call(dynamic val) =>
      _ok(val)
          ? ModelUnion._v(_t, _v, val)
          : throw ArgumentError('Invalid: $val');

  bool _ok(dynamic val) =>
      _v.contains(val) || _t.any(_match(val)) || _v.any(_eq(val));

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

  @override
  String toString() => _has ? '$_val' : throw StateError('No value');
}

class TypeToken<T> {
  const TypeToken();
  Type get type => T;
}
