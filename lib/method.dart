import 'package:flutter/material.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class MethodPage extends StatefulWidget {
  final Method info;


  const MethodPage({super.key, required this.info}); 

  @override
  State<MethodPage> createState() => _MethodPageState();
}

class _MethodPageState extends State<MethodPage> {
  bool paramsPanelExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        // `domain.name` domain
        Row(
          spacing: 5,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(
                widget.info.name, 
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: "consola"),
              ),
            ),
            Text("method", style: Theme.of(context).textTheme.headlineMedium,)
          ],
        ),
        // description
        if (widget.info.description.isNotEmpty) Card(
          child: Text(widget.info.description, softWrap: true,),
        ),
        // its content (methods, events, types)
        StatefulBuilder(
          builder: (context, setState) => ExpansionPanelList(
            children: [
              ExpansionPanel(
                headerBuilder: (_,__)=>Text("Parameters"), 
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.info.parameters.values.map((e)=>ListTile(
                    title: Text(e.name),
                    subtitle: Text(e.description.truncate(77)),
                  )).toList(),
                ),
                isExpanded: paramsPanelExpanded
              )
            ],
            expansionCallback: (dex, opened) {
              setState((){
                paramsPanelExpanded = opened;
              });
            },
          )
        )
      ],
    );
  }
}

class ReasonableExpansionPanel extends ExpansionPanel {
  bool _isExpanded;
  ReasonableExpansionPanel({required super.headerBuilder, required super.body, bool isExpanded = false, super.canTapOnHeader, super.backgroundColor, super.splashColor, super.highlightColor}): _isExpanded = isExpanded;

  @override
  bool get isExpanded => _isExpanded;
  set isExpanded(bool g) => _isExpanded = g;
}

extension MopeString on String {
  String truncate(int maxCharacters) {
    return length > maxCharacters ? "${substring(maxCharacters-3)}..." : this;
  }
}
