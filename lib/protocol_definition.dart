class Method {
  String name;
  String description;

  Method(Map<String, dynamic> m):
    name = m["name"] as String,
    description = m["description"] as String? ?? ""
  ;
}

class Domain {
  String name;
  String description;
  List<Method> methods;

  Domain(Map<String, dynamic> m):
    name = m["name"] as String,
    description = m["description"] as String? ?? "",
    methods = (m["methods"] as List<Map<String, dynamic>>).map((e)=>Method(e)).toList(growable:false)
  ;
}
