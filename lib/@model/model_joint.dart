import 'package:mydartbox/@model/model_unfold.dart';

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
    throw ArgumentError('\n\nCurrent Type\n-> ${val.runtimeType}\n\nAollowed Types\n-> ${_t.toList()}\n');
  }

  bool _ok(dynamic val) =>
      _v.contains(val) ||
      _t.any((t) => _match(val, t, t.toString())) ||
      _v.any((v) => _eq(val, v));

  bool _match(dynamic val, Type t, String typeStr) {
    if (t == dynamic) return true;

    if (t == String) return val is String;
    if (t == int) return val is int;
    if (t == double) return val is double;
    if (t == bool) return val is bool;

    if (typeStr.startsWith('List<')) {
      return val is List &&
          _checkGeneric(
            val,
            typeStr,
            'List',
            (v, et, ets) => v.every((e) => _match(e, et, ets)),
          );
    }
    if (typeStr.startsWith('Map<')) {
      return val is Map &&
          _checkGeneric(
            val,
            typeStr,
            'Map',
            (v, kt, kts, vt, vts) =>
                v.keys.every((k) => _match(k, kt, kts)) &&
                v.values.every((v) => _match(v, vt, vts)),
          );
    }
    if (typeStr.startsWith('Set<')) {
      return val is Set &&
          _checkGeneric(
            val,
            typeStr,
            'Set',
            (v, et, ets) => v.every((e) => _match(e, et, ets)),
          );
    }

    return false;
  }

  bool _checkGeneric(
    dynamic val,
    String typeStr,
    String baseType,
    Function checkFn,
  ) {
    final args = _extractTypeArguments(typeStr);
    if (baseType == 'Map') {
      if (args.length != 2) return false;
      final keyType = _parseType(args[0]);
      final valueType = _parseType(args[1]);
      return checkFn(val, keyType.$1, keyType.$2, valueType.$1, valueType.$2);
    } else {
      if (args.length != 1) return false;
      final elementType = _parseType(args[0]);
      return checkFn(val, elementType.$1, elementType.$2);
    }
  }

  List<String> _extractTypeArguments(String typeStr) {
    final inner = typeStr.substring(
      typeStr.indexOf('<') + 1,
      typeStr.lastIndexOf('>'),
    );
    final List<String> args = [];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < inner.length; i++) {
      if (inner[i] == '<')
        depth++;
      else if (inner[i] == '>')
        depth--;
      else if (inner[i] == ',' && depth == 0) {
        args.add(inner.substring(start, i).trim());
        start = i + 1;
      }
    }
    args.add(inner.substring(start).trim());
    return args;
  }

  (Type, String) _parseType(String typeName) => switch (typeName.trim()) {
    'String' => (String, typeName),
    'int' => (int, typeName),
    'double' => (double, typeName),
    'bool' => (bool, typeName),
    'List' => (List, typeName),
    'Map' => (Map, typeName),
    'Set' => (Set, typeName),
    String s
        when s.startsWith('List<') ||
            s.startsWith('Map<') ||
            s.startsWith('Set<') =>
      (Object, s),
    _ => throw ArgumentError('Unknown type: $typeName'),
  };

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

/*
class CoreJoint {
  get data => ModelJoint([
    String,
    Map<String, List<String>>,
    List<String>,
    Map<String, List<Set<Map<String, Set<String>>>>>,
  ]);

  CoreJoint();
}

void main() {
  final coreJoint = CoreJoint();
  final data = <String, List<Set<Map<String, Set<String>>>>>{
    'ID': List.generate(
      5,
      (index) => {
        <String, Set<String>>{
          "er": {(index + 1).toString()},
        },
      },
    ),
    'Name': List.generate(
      5,
      (index) => {
        <String, Set<String>>{
          "er": {'Name $index'},
        },
      },
    ),
  };
  final a = coreJoint.data(data);
  print("bro ${a.toString()} ${a.runtimeType}");
}
*/
