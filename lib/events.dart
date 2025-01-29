import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:go_router/go_router.dart';

class EventPage extends StatefulWidget {
  final Event info;

  const EventPage({super.key, required this.info}); 

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  bool paramsPanelExpanded = !(Platform.isAndroid || Platform.isIOS);

  bool listening = true;

  @override
  void initState() {
    super.initState();
    var n = Neuro.nameOf(context);
    var le = Neuro.of(context).listenedEvents;
    listening = le.containsKey(n);
    if (listening) response = le.listenTo(n)!;
  }

  @override
  void dispose() {
    super.dispose();
  }

  ValueNotifier<String> response = ValueNotifier("{}");

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
          verticalDirection: VerticalDirection.up, //??
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
            RichText(
              text:TextSpan(
                children: [
                  TextSpan(
                    text: widget.info.name, 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontFamily: "consola"),
                  ),
                  TextSpan(text: " event", style: Theme.of(context).textTheme.headlineMedium,),
                ],
              ),
            ), 
            Spacer(),
            StatefulBuilder(
              builder: (context, ss) => FilledButton(
                onPressed: ()=>ss((){
                  
                }),
                style: /*(sub!=null) ? ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.tertiary)
                ) : */null,
                child: Text("Listen"),
              )
            )
          ],
        ),
        // description
        if (widget.info.description.isNotEmpty) Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MarkdownBody(
              data: """
${widget.info.description}

(Note that you must enable the domain agent (usually using the [`enable`](method:${GoRouter.of(context).state!.pathParameters["domain"]}.enable) method) to actually receive the event.)
""".trim(),
              selectable: false,
              onTapLink: (t,h,tt) => gdpOnTapLink(context, t, h, tt),
            ),
          ),
        ), 
        /*
        // its content (events, events, types)
        if (widget.info.parameters.isNotEmpty) StatefulBuilder(
          builder: (context, setState) => ExpansionPanelList(
            children: [
              ExpansionPanel(
                headerBuilder: (_,isExpanded)=>Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(
                        "Parameters", 
                        style: TextTheme.of(context).titleMedium,
                      ),
                      Spacer(),
                      IgnorePointer(
                        ignoring: !isExpanded,
                        child: AnimatedOpacity(
                          opacity: isExpanded ? 1 : 0,
                          duration: kThemeAnimationDuration,
                          child: IconButton(
                            onPressed: (){},
                            icon: Icon(Icons.add),
                            tooltip: "Add parameter",
                          )
                        ),
                      )
                    ],
                  ),
                ), 
                body: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: settingNodes,
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
        ),
        */
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          padding: EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: response, 
            builder: (_,v,__) => SelectableText(
              v,
              style: TextStyle(fontFamily: "consola"),
            )
          ),
        ),
      ],
    );
  }
}
