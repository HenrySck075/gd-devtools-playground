import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdp_playground/extensions.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class SettingNode extends StatefulWidget {
  final String name;
  final String description;
  SettingNode(Parameter parameter, {super.key})
  : name = parameter.name
  , description = parameter.description
  ;

  static SettingNode adaptive(BuildContext context, Parameter parameter) {
    String? type = parameter.primitive 
    ? parameter.type
    : Neuro.of(context).resolveType(GoRouter.of(context).state!.pathParameters["domain"]!, parameter.type);
    if (type == "boolean") return BoolSettingNode(parameter);
    if (type == "string") return StringSettingNode(parameter);
    if (type == "integer") return IntSettingNode(parameter);

    return SettingNode(parameter);
  }

  @override
  State<SettingNode> createState() => _SettingNodeState();
  
  dynamic getValue() {return null;}
}

class _SettingNodeState<T extends SettingNode> extends State<T> {
  Widget? buildTrailingNode(BuildContext context) => null;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(widget.name),
    subtitle: Text(widget.description.truncate(77).replaceAll("\n", " ")),
    trailing: buildTrailingNode(context),
  );
}

class BoolSettingNode extends SettingNode {
  final ValueNotifier<bool> value;

  @override
  dynamic getValue() {return value.value;}

  BoolSettingNode(super.parameter, {super.key})
  : value = ValueNotifier(false);
  @override
  State<SettingNode> createState() => _BoolSettingNodeState();
}
class _BoolSettingNodeState extends _SettingNodeState<BoolSettingNode> {
  @override
  Widget buildTrailingNode(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.value, 
    builder: (_, v, c) => CheckboxListTile(
      value: v, 
      onChanged: (nv) {
        widget.value.value = nv??false;
      }
    )
  );
}


class StringSettingNode extends SettingNode {
  final TextEditingController _controller = TextEditingController();

  @override
  dynamic getValue() {return _controller.text;}

  StringSettingNode(super.parameter, {super.key});
  @override
  State<SettingNode> createState() => _StringSettingNodeState();
}
class _StringSettingNodeState extends _SettingNodeState<StringSettingNode> {
  @override
  Widget buildTrailingNode(BuildContext context) => SizedBox(
    width: 120,
    child: TextField(
      controller: widget._controller,
    ),
  );
}

// ignore: must_be_immutable
class IntSettingNode extends SettingNode {
  int? value;
  @override
  dynamic getValue() {return value ?? 0;}

  IntSettingNode(super.parameter, {super.key});
@override
  State<SettingNode> createState() => _IntSettingNodeState();
}
class _IntSettingNodeState extends _SettingNodeState<IntSettingNode> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener((){
      widget.value = int.tryParse(_controller.text);
    });
  }
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget buildTrailingNode(BuildContext context) => Row(
    spacing: 4,
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        onPressed: (){
          _controller.text = (int.parse(_controller.text) - 1).toString();
        }, 
        icon: Icon(Icons.arrow_left)
      ),
      SizedBox(
        width: 120,
        child: TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly
          ],
          controller: _controller,
          textAlign: TextAlign.center,
        ),
      ),
      IconButton(
        onPressed: (){
          _controller.text = (int.parse(_controller.text) + 1).toString();
        }, 
        icon: Icon(Icons.arrow_right)
      ),
    ],
  );
}