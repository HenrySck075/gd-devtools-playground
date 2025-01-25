
// ignore: camel_case_types
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class _f {
  String name;
  String description;
  _f(Map<String, dynamic> m)
  : name = m["name"] as String
  , description = m["description"] as String? ?? ""
  ;
}
class Parameter extends _f {
  String type;
  bool primitive;

  Parameter(super.m)
  : type = m["type"] ?? m["\$ref"]
  , primitive = m.containsKey("type");

  factory Parameter.create(Map<String, dynamic> m) {
    if (m["type"] == "string" && m.containsKey("enum")) {
      return EnumParameter(m);
    }
    return Parameter(m);
  }
}

/// what
class EnumParameter extends Parameter {
  List<String> values;
  EnumParameter(super.m)
  : assert(m["type"] == "string")
  , values = m["enum"]
  ;
}


class Method extends _f{
  Map<String, Parameter> parameters;
  Method(super.m)
  : parameters = {
    for (final e in (m["parameters"] as List<dynamic>?) ?? [])
    e["name"]: Parameter(e)
  };
}

class Type {
  String id;
  String description;
  String type;
  Map<String, Parameter> properties;
  Type(Map<String, dynamic> m)
  : id = m["id"] as String
  , description = m["description"] as String? ?? ""
  , type = m["type"] as String
  , properties = {
    for (final e in (m["properties"] as List<dynamic>?) ?? [])
    e["name"]: Parameter(e)
  }
  ;
}

class Domain {
  String name;
  String description;
  Map<String, Method> methods;
  Map<String, Type> types;

  Domain(Map<String, dynamic> m)
  : name = m["domain"] as String
  , description = m["description"] as String? ?? ""
  , methods =  {
    for (final e in (m["commands"] as List<dynamic>?) ?? [])
    e["name"]: Method(e)
  }
  , types = {
    for (final e in (m["types"] as List<dynamic>?) ?? [])
    e["id"]: Type(e)
  }
  ;
}


Map<String, IconData> iconsForDomain = {
  "DOM": Icons.list,
  "Log": Icons.terminal,
  "Level": Icons.map,
  "Game": Icons.games, // TODO: find a better one
  "Network": Icons.wifi,
  "Runtime": Icons.phone_android,
  "Mod": Icons.change_circle_outlined
};