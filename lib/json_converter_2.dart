import 'dart:convert';

String jsonEncodeIndented(Object? object, [int indentation = 2]) {
  // the
  return JsonEncoder.withIndent(" "*indentation).convert(object);
}