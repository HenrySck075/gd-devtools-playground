import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:gdp_playground/map_value_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol_definition.dart';

/// shared states from the shell page
class Neuro extends InheritedWidget {
  final UnmodifiableMapView<String, Domain> domains;
  final Client Function() _clientResolve;
  final WebSocketChannel Function() _channelResolve;
  final MapValueNotifier<String, String> listenedEvents;
  Client get client => _clientResolve();
  WebSocketChannel get channel => _channelResolve();
  const Neuro({super.key, required super.child, required this.domains, required Client Function() client,  required WebSocketChannel Function() channel, required this.listenedEvents})
  : _clientResolve = client
  , _channelResolve = channel;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget as Neuro).domains != domains;
  }

  static Neuro of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<Neuro>()!;
  static String nameOf(BuildContext context) {
    var s = GoRouter.of(context).state!;
    var n = s.pathParameters["domain"];
    if (n==null) return "";
    if (s.pathParameters.containsKey("method")) return "$n.${s.pathParameters["method"]}";
    if (s.pathParameters.containsKey("event")) return "$n.${s.pathParameters["event"]}";
    if (s.pathParameters.containsKey("type")) return "$n.${s.pathParameters["type"]}";
    return n;
  }

  String? resolveType(String domain, String typeAlias) {
    try {
      return domains[domain]?.types.values.firstWhere((t)=>t.id==typeAlias).type;
    } catch (e) {
      return null;
    }
  }
}

void gdpOnTapLink(BuildContext context, String text, String? href, String title) {
  if (href!=null) {
    // this loooks like shit
    if (href.startsWith("event:")) {
      List<String> name = href.substring(7).split(".");
      GoRouter.of(context).push("/${name[0]}/event/${name[1]}");
    } else if (href.startsWith("method:")) {
      List<String> name = href.substring(7).split(".");
      GoRouter.of(context).push("/${name[0]}/method/${name[1]}");
    } else if (href.startsWith("domain:")) {
      GoRouter.of(context).push("/${href.substring(7)}");
    } else {
      launchUrl(Uri.parse(href));
    }
  }
}