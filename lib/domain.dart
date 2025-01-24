import 'package:flutter/material.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/extensions.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class DomainPage extends StatelessWidget {
  final Domain info;

  const DomainPage({super.key, required this.info}); 

  @override
  Widget build(BuildContext context) {
    List<ReasonableExpansionPanel> j = [
      if (info.methods.isNotEmpty) ReasonableExpansionPanel(
        headerBuilder: (c, opened) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Methods", 
            style: TextTheme.of(context).titleMedium,
          ),
        ), 
        body: Theme(
          data: Theme.of(context).copyWith(colorScheme: methodScheme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: info.methods.values.map((e)=>ListTile(
              title: Text(e.name),
              subtitle: Text(e.description.truncate(77)),
              onTap: (){
                GoRouter.of(context).go("/${info.name}/method/${e.name}");
              },
            )).toList(),
          ),
        ),
        isExpanded: false
      )
    ];
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `domain.name` domain
        Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              info.name, 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: "consola"),
            ),
            Text("domain", style: Theme.of(context).textTheme.headlineMedium,)
          ],
        ),
        // description
        if (info.description.isNotEmpty) Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(info.description, softWrap: true,),
          ),
        ),
        // its content (methods, events, types)
        StatefulBuilder(
          builder: (context, setState) => ExpansionPanelList(
            children: j,
            expansionCallback: (dex, opened) {
              setState((){
                j[dex].isExpanded = opened;
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