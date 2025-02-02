import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class SettingUpdated extends Notification {
  final String name;
  final dynamic value;

  SettingUpdated({required this.name, required this.value});
}

class SettingNode extends StatefulWidget {
  final Parameter parameter;
  const SettingNode(this.parameter, {super.key});

  static SettingNode adaptive(BuildContext context, Parameter parameter) {
    String? type = parameter.primitive 
    ? parameter.type
    : Neuro.of(context).resolveType(GoRouter.of(context).state!.pathParameters["domain"]!, parameter.type);
    if (type == "boolean") return BoolSettingNode(parameter);
    if (type == "string") return StringSettingNode(parameter);
    if (type == "integer") return IntSettingNode(parameter);
    if (type == "number") return NumberSettingNode(parameter);

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
    title: Text(widget.parameter.name),
    subtitle: Text(widget.parameter.description),
    trailing: buildTrailingNode(context),
    onTap: kDebugMode ? (){
      showDialog(
        context: context,
        builder: (c)=>AlertDialog(
          title: Text("iejiofwjefjwe"),
          content: Text("name: ${widget.parameter.name}\ntype: ${widget.parameter.type} (${widget.parameter.primitive})"),
        )
      );
    } : null,
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
        SettingUpdated(name: widget.parameter.name, value: widget.value.value).dispatch(context);
      }
    )
  );
}


// ignore: must_be_immutable
class StringSettingNode extends SettingNode {
  String text = "";
  @override
  dynamic getValue() {return text;}

  StringSettingNode(super.parameter, {super.key});
  @override
  State<SettingNode> createState() => _StringSettingNodeState();
}
class _StringSettingNodeState extends _SettingNodeState<StringSettingNode> {
  final TextEditingController _controller = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _controller.addListener((){
      widget.text = _controller.text;
      if (context.mounted) {
        SettingUpdated(name: widget.parameter.name, value: widget.text).dispatch(context);
      }
    });
  }
  @override
  Widget buildTrailingNode(BuildContext context) => SizedBox(
    width: 240,
    child: TextField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      controller: _controller,
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
  final TextEditingController _controller = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _controller.addListener((){
      widget.value = int.tryParse(_controller.text);
      if (context.mounted) {
        SettingUpdated(name: widget.parameter.name, value: widget.value).dispatch(context);
      }
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
          _controller.text = (int.parse(_controller.text.isEmpty ? "0" : _controller.text) - 1).toString();
        }, 
        icon: Icon(Icons.arrow_left)
      ),
      SizedBox(
        width: 120,
        child: TextField(
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"-?[0-9]+"))
          ],
          controller: _controller,
          textAlign: TextAlign.center,
        ),
      ),
      IconButton(
        onPressed: (){
          _controller.text = (int.parse(_controller.text.isEmpty ? "0" : _controller.text) + 1).toString();
        }, 
        icon: Icon(Icons.arrow_right)
      ),
    ],
  );
}

// ignore: must_be_immutable
class NumberSettingNode extends SettingNode {
  double? value;
  @override
  dynamic getValue() {return value ?? 0;}

  NumberSettingNode(super.parameter, {super.key});
@override
  State<SettingNode> createState() => _NumberSettingNodeState();
}
class _NumberSettingNodeState extends _SettingNodeState<NumberSettingNode> {
  final TextEditingController _controller = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _controller.addListener((){
      widget.value = double.tryParse(_controller.text);
      if (context.mounted) {
        SettingUpdated(name: widget.parameter.name, value: widget.value).dispatch(context);
      }
    });
  }
  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget buildTrailingNode(BuildContext context) => SizedBox(
    width: 120,
    child: TextField(
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"-?([0-9]*[.])?[0-9]+"))
      ],
      controller: _controller,
      textAlign: TextAlign.center,
    ),
  );
}