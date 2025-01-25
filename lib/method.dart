import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gdp_playground/extensions.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class MethodPage extends StatefulWidget {
  final Method info;


  const MethodPage({super.key, required this.info}); 

  @override
  State<MethodPage> createState() => _MethodPageState();
}

class _MethodPageState extends State<MethodPage> {
  bool paramsPanelExpanded = !(Platform.isAndroid || Platform.isIOS);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `domain.name` domain
        Row(
          spacing: 7,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: (){
                  GoRouter.of(context).pop();
                }
              )
            ),
            Text(
              widget.info.name, 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: "consola"),
            ),
            Text("method", style: Theme.of(context).textTheme.headlineMedium,),
            Spacer(),
            FilledButton(
              child: Text("Execute"),
              onPressed: (){},
            )
          ],
        ),
        // description
        if (widget.info.description.isNotEmpty) Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(widget.info.description, softWrap: true,),
          ),
        ),
        // its content (methods, events, types)
        if (widget.info.parameters.isNotEmpty) StatefulBuilder(
          builder: (context, setState) => ExpansionPanelList(
            children: [
              ExpansionPanel(
                headerBuilder: (_,__)=>Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Parameters", 
                    style: TextTheme.of(context).titleMedium,
                  ),
                ), 
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