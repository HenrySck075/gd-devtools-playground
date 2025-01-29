import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/domain.dart';
import 'package:gdp_playground/events.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/home.dart';
import 'package:gdp_playground/map_value_notifier.dart';
import 'package:gdp_playground/method.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:go_router/go_router.dart';

import 'protocol_definition.dart';

CustomTransitionPage fadeTransition(Widget child, String valueKey) => CustomTransitionPage(
  child: child, 
  key: ValueKey(valueKey),
  transitionDuration: Duration(milliseconds: 200),
  transitionsBuilder: (ctx, a, sa, c) => FadeTransition(
    opacity: a.drive(CurveTween(
      curve: Interval(
        0, 1/3*(a.isForwardOrCompleted ? 1 : 2),
        curve: a.isForwardOrCompleted ? Easing.emphasizedAccelerate : Easing.emphasizedDecelerate
      )
    )),
    child: ColoredBox(
      color: Theme.of(ctx).colorScheme.surface,
      child: FadeTransition(
        opacity: a.drive(CurveTween(
          curve: Interval(
            1/3*(a.isForwardOrCompleted ? 1 : 2), 1,
            curve: a.isForwardOrCompleted ? Easing.emphasizedDecelerate : Easing.emphasizedAccelerate
          )
        )),
        child: c
      )
    ),
  )
);


final _router = GoRouter(
errorPageBuilder: (ctx, s)=>fadeTransition(Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text("Not found", style: TextTheme.of(ctx).headlineMedium,)
    ],
  ),
), "err"),
routes: [
  ShellRoute(
    builder: (ctx, state, child) => ShellPage(child: child),
    routes: [
      GoRoute(
        path: "/",
        name: "main",
        pageBuilder: (ctx, s) => fadeTransition(const HomePage(), "main"),
        routes: [
          GoRoute(
            name: "domain",
            path: ":domain",
            pageBuilder: (ctx, s) => fadeTransition(
              DomainPage(info: Neuro.of(ctx).domains[s.pathParameters["domain"]]!),
              "domain:${s.pathParameters["domain"]}"
            ),
            routes: [
              GoRoute(
                path: "method/:method",
                name: "method",
                pageBuilder: (ctx, s) => fadeTransition(
                  MethodPage(info: Neuro.of(ctx).domains[s.pathParameters["domain"]!]!.methods[s.pathParameters["method"]]!),
                  "method:${s.pathParameters["method"]}"
                )
              ),
              GoRoute(
                path: "event/:event",
                name: "event",
                pageBuilder: (ctx, s) => fadeTransition(
                  EventPage(info: Neuro.of(ctx).domains[s.pathParameters["domain"]!]!.events[s.pathParameters["event"]]!),
                  "event:${s.pathParameters["event"]}"
                )
              )
            ]
          )
        ]
      )
    ]
  )
],
);
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'g',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        colorScheme: mainScheme,
        useMaterial3: true,
      ),
    );
  }
}

class ShellPage extends StatefulWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  WebSocketChannel? socket;
  Client? client;
  // shell is the main owner of it
  Map<String, Domain> domains = {};
  MapValueNotifier<String, String> listenedEvents = MapValueNotifier({});

  bool? disconnected = true;

  Client _clientResolve() {return client!;}
  WebSocketChannel _channelResolve() {return socket!;}

  void connect([bool spamSetState = true]) {
    if (disconnected == false) return;
    disconnected = null;
    socket = WebSocketChannel.connect(Uri.parse("ws://localhost:1412"));
    var idk = socket!.cast<String>().changeStream((s)=>s.asBroadcastStream());
    client = Client(idk);
    client!.listen().whenComplete((){
      disconnected = true;
      setState((){});
    });
    idk.stream.listen((e){
      Map<String, dynamic> payload = jsonDecode(e);
      if (payload.containsKey("id")) return;
      if (listenedEvents.containsKey(payload["method"])) {
        listenedEvents[payload["method"]] = payload["parameters"];
      }
    });
    socket!.ready.then((e){
      disconnected = false;
      client!.sendRequest("getProtocolInformation").then((v){
        domains = {
          for (final e in (jsonDecode(v! as String)["domains"] as List<dynamic>)..sort(
            (oat,meal)=>(oat["domain"] as String).compareTo(meal["domain"]))
          )
          e["domain"]: Domain(e)
        };
        setState((){});
      }, onError: (e){
        disconnected = true;
        debugPrint(e.toString());
        setState((){});
      });
    });
    setState((){});
  }
  @override
  void initState() {
    super.initState();
    connect(false);
  }

  bool useModalNavigation = false;

  int drawerSelectedIndex = -1;
  @override
  Widget build(BuildContext context) {
    if (disconnected != false) {
      drawerSelectedIndex = -1;
    } else if (domains.isNotEmpty && _router.state != null && _router.state!.name!="main") {
      drawerSelectedIndex = domains.keys.indexed.firstWhere(
        (g)=>g.$2 == _router.state!.pathParameters["domain"]
      ).$1;
    }
    var drawer = NavigationDrawer(
      selectedIndex: drawerSelectedIndex,
      onDestinationSelected: (idx) {
        _router.replace("/${domains.values.toList()[idx].name}");
      },
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(left: 16*2),
          child: Text("Domains",style: Theme.of(context).textTheme.titleSmall),
        ),
        ...domains.values.map(
          (d)=>NavigationDrawerDestination(
            icon: Icon(iconsForDomain.containsKey(d.name) ? iconsForDomain[d.name] : Icons.mode), 
            label: Text(d.name),
          )
        )
      ],
    );
    var box = Builder(
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
          ),
          color: Theme.of(context).colorScheme.surface
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: disconnected == true
          ? Center(
            child: Column(
              children: [
                Text("Launch Geometry Dash and reconnect to start using the playground!"),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 150),
                  child: FilledButton(
                    onPressed: connect,
                    child: Text("Reconnect"),
                  ),
                )
              ]
            )
          )
          : domains.isEmpty || disconnected == null
            ? Center(child: CircularProgressIndicator(),) 
            // i mean you can say that "just use SliverFillRemaining" but it cuts off contents when i use it so no
            : LayoutBuilder(
                builder: (context, constraints) {
                  debugPrint(constraints.maxHeight.toString());
                  return ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight==double.infinity?constraints.minHeight:constraints.maxHeight),
                    child: SingleChildScrollView(child: widget.child,)
                  );
                }
              ),
        )
      )
    );
    String name = GoRouter.of(context).state!.name!;
    var t = ThemeData(
      colorScheme: 
      disconnected != false
      ? mainScheme
      : name == "method"
        ? methodScheme
        : name == "domain"
          ? domainScheme
          : mainScheme
      
    );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () {
          GoRouter.of(context).pop();
        }
      },
      child: Neuro(
        domains: UnmodifiableMapView(domains),
        client: _clientResolve,
        channel: _channelResolve,
        listenedEvents: listenedEvents,
        child: AnimatedTheme(
          data: t,
          curve: Easing.emphasizedDecelerate,
          child: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  title: Text("GD Devtools Protocol Playground"),
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                body: useModalNavigation ? box : Row(children: [
                  // https://github.com/flutter/flutter/issues/123113
                  Theme(
                    data: Theme.of(context).copyWith(
                      drawerTheme: DrawerThemeData(
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                        endShape: const RoundedRectangleBorder(),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                      )
                    ),
                    child: drawer,
                  ),
                  Expanded(child: box) 
                ],),
                drawer: useModalNavigation ? drawer : null
              );
            }
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    useModalNavigation = MediaQuery.sizeOf(context).width <= 839; // <= medium
  }
}
