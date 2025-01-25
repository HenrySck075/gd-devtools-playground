import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

import 'protocol_definition.dart';

/// shared states from the shell page
class Neuro extends InheritedWidget {
  final UnmodifiableMapView<String, Domain> domains;
  final Client Function() _clientResolve;
  Client get client => _clientResolve();
  const Neuro({super.key, required super.child, required this.domains, required Client Function() client})
  : _clientResolve = client;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget as Neuro).domains != domains;
  }

  static Neuro of(BuildContext ctx) => ctx.dependOnInheritedWidgetOfExactType<Neuro>()!;

  String? resolveType(String domain, String typeAlias) {
    try {
      return domains[domain]?.types.values.firstWhere((t)=>t.id==typeAlias).type;
    } catch (e) {
      return null;
    }
  }
}
