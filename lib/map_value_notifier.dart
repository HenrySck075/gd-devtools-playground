import 'package:flutter/widgets.dart';

class MapValueNotifier<K,V> extends ChangeNotifier implements Map<K,V> {
  final Map<K,ValueNotifier<V>> _value;
  MapValueNotifier(Map<K,V> value):_value = value.map((k,v)=>MapEntry(k,ValueNotifier(v)));
  
  ValueNotifier<V>? listenTo(K key) => _value[key];

  @override
  V? operator [](Object? key) => _value[key]?.value;
  
  @override
  void operator []=(K key, V value) {
    if (!containsKey(key)) _value[key] = ValueNotifier(value);
    _value[key]?.value = value;
  }
  
  @override
  void addAll(Map<K, V> other) {
    addEntries(other.entries);
  }
  
  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    for (final p in newEntries) {
      if (containsKey(p.key)) {
        _value[p.key]!.value = p.value;
      } else {
        _value[p.key] = ValueNotifier(p.value);
      }
    }
  }
  
  @override
  Map<RK, RV> cast<RK, RV>() {
    throw UnsupportedError("no");
  }
  
  @override
  void clear() {
    _value.clear();
  }
  
  @override
  bool containsKey(Object? key) => _value.containsKey(key);
  @override
  bool containsValue(Object? value) => _value.containsValue(value);
  
  @override
  Iterable<MapEntry<K, V>> get entries => _value.entries.map((p)=>MapEntry(p.key, p.value.value));
  
  @override
  void forEach(void Function(K key, V value) action) {
    // g
    for (var p in entries) {
      action(p.key,p.value);
    }
  }
  
  @override
  bool get isEmpty => _value.isEmpty;
  
  @override
  bool get isNotEmpty => _value.isNotEmpty;
  
  @override
  Iterable<K> get keys => _value.keys;
  
  @override
  int get length => _value.length;
  
  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    // TODO: implement map
    throw UnimplementedError();
  }
  
  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (!containsKey(key)) {
      _value[key] = ValueNotifier(ifAbsent());
    }
    return this[key]!;
  }
  
  @override
  V? remove(Object? key) => _value.remove(key)?.value;
  
  @override
  void removeWhere(bool Function(K key, V value) test) {
    _value.removeWhere((k,v)=>test(k,v.value));
  }
  
  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    if (containsKey(key)) {
      _value[key]!.value = update(_value[key]!.value);
    } else {
      _value[key] = ValueNotifier(ifAbsent!());
    }
    return this[key]!;
  }
  
  @override
  void updateAll(V Function(K key, V value) update) {
    _value.updateAll((k,v){
      v.value = update(k,v.value);
      return v;
    });
  }
  
  @override
  Iterable<V> get values => _value.values.map((v)=>v.value);
}