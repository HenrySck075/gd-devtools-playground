import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'protocol_definition.dart';

class Neuro extends InheritedWidget {
  final UnmodifiableListView<Domain> domains;
  const Neuro({super.key, required super.child, required this.domains});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget as Neuro).domains != domains;
  }

  static Neuro of(BuildContext ctx) => ctx.dependOnInheritedWidgetOfExactType<Neuro>()!;
}
