import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/json_converter_2.dart';
import 'package:gdp_playground/protocol_definition.dart';
import 'package:gdp_playground/setting.dart';

import 'package:go_router/go_router.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

class MethodPage extends StatefulWidget {
  final Method info;

  const MethodPage({super.key, required this.info}); 

  @override
  State<MethodPage> createState() => _MethodPageState();
}

class _MethodPageState extends State<MethodPage> {
  bool paramsPanelExpanded = !(Platform.isAndroid || Platform.isIOS);

  List<SettingNode> settingNodes = [];

  @override
  void initState() {
    super.initState();
  }

  ValueNotifier<String> response = ValueNotifier("Response will be set here!");
  ValueNotifier<String> request = ValueNotifier("{}");
  Map<String, dynamic> requestJson = {}; 

  void executeCommand(BuildContext context) {
    var client = Neuro.of(context).client;
    var routeState = GoRouter.of(context).state!;

    String method = "${routeState.pathParameters["domain"]}.${routeState.pathParameters["method"]}";
    client.sendRequest(method, requestJson).then((v){
      response.value = jsonEncodeIndented(v);
    }).catchError((e){
      if (!context.mounted) return;
      var err = e as RpcException;
      if (err.code == -32601 && err.message.endsWith(" wasn't found.")) {
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: Text("Not implemented"),
            content: Text("The method is documented but not implemented in the mod. Sorry!"),
          )
        );
      } else {
        response.value = "Error ${err.code}: ${err.message}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (settingNodes.isEmpty) {
      settingNodes = widget.info.parameters.values.map((e)=>SettingNode.adaptive(context, e)).toList();
      requestJson = {for (final node in settingNodes) node.parameter.name: node.getValue()};
      request.value = jsonEncode(requestJson);
    }
    return NotificationListener<SettingUpdated>(
      onNotification: (n){
        requestJson[n.name] = n.value;
        request.value = jsonEncode(requestJson);
        return true;
      },
      child: Column(
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
                    TextSpan(text: " method", style: Theme.of(context).textTheme.headlineMedium,),
                  ],
                ),
              ), 
              Spacer(),
              FilledButton(
                onPressed: ()=>executeCommand(context),
                child: Text("Execute"),
              )
            ],
          ),
          // description
          if (widget.info.description.isNotEmpty) Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MarkdownBody(
                data: widget.info.description,
                selectable: false,
                onTapLink: (t,h,tt) => gdpOnTapLink(context, t, h, tt),
              ),
            ),
          ), 
          // its content (methods, events, types)
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
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: EdgeInsets.all(16),
            child: ValueListenableBuilder(
              valueListenable: request, 
              builder: (_,v,__) => SelectableText(
                v,
                style: TextStyle(fontFamily: "consola"),
              )
            ),
          ),
          ValueListenableBuilder(
            valueListenable: response, 
            builder: (_,v,__) => Container(
              color: v.startsWith("Error") ? Theme.of(context).colorScheme.errorContainer : Theme.of(context).colorScheme.surfaceContainerLow,
              padding: EdgeInsets.all(16),
              child: SelectableText(
                v,
                style: TextStyle(fontFamily: "consola"),
              )
            )
          ),
        ],
      ),
    );
  }
}
