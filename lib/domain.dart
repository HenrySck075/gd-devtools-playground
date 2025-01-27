import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/extensions.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';
import 'package:gdp_playground/expansion_panel_2.dart';

class DomainPage extends StatelessWidget {
  final Domain info;

  const DomainPage({super.key, required this.info}); 

  @override
  Widget build(BuildContext context) {
    List<ReasonableExpansionPanel> j = [
      if (info.methods.isNotEmpty) ReasonableExpansionPanel(
        name: "methods",
        headerBuilder: (c, opened) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Methods", 
            style: TextTheme.of(context).titleMedium,
          ),
        ), 
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: info.methods.values.map((e)=>ListTile(
            title: Text(e.name),
            subtitle: Text(e.description.truncate(77)),
            onTap: (){
              GoRouter.of(context).go("/${info.name}/method/${e.name}");
            },
          )).toList(),
        ),
        isExpanded: !(Platform.isAndroid || Platform.isIOS)
      ),
      if (info.events.isNotEmpty) ReasonableExpansionPanel(
        name: "events",
        headerBuilder: (c, opened) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Events", 
            style: TextTheme.of(context).titleMedium,
          ),
        ), 
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: info.events.values.map((e)=>ListTile(
            title: Text(e.name),
            subtitle: Text(e.description.truncate(77)),
            onTap: (){
              GoRouter.of(context).go("/${info.name}/event/${e.name}");
            },
          )).toList(),
        ),
        isExpanded: !(Platform.isAndroid || Platform.isIOS)
      )
    ];
    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `domain.name` domain
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: info.name, 
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: "consola"),
                ),
                TextSpan(text: " domain", style: Theme.of(context).textTheme.headlineMedium,)
              ],
            ),
          ),
        ),
        // description
        if (info.description.isNotEmpty) Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(info.description, softWrap: true,),
          ),
        ),
        // its content (methods, events, types)
        for (final panel in j)
        Theme(
          data: ThemeData(
            colorScheme: panel.name == "methods" ? methodScheme : panel.name == "events" ? eventScheme : panel.name == "types" ? typeScheme : mainScheme
          ),
          child: StatefulBuilder(
            builder: (context, setState) => ExpansionPanelList(
              materialGapSize: 0,
              children: [panel],
              expansionCallback: (dex, opened) {
                setState((){
                  panel.isExpanded = opened;
                });
              },
            )
          ),
        ),
        SizedBox(
          height: kDebugMode ? 77 : 16,
        )
      ],
    );
  }
}
