import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/domain.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/home.dart';
import 'package:gdp_playground/method.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:go_router/go_router.dart';

import 'protocol_definition.dart';

CustomTransitionPage fadeTransition(Widget child) => CustomTransitionPage(
  child: child, 
  transitionDuration: Duration(milliseconds: 500),
  transitionsBuilder: (ctx, a, sa, c) => FadeTransition(
    opacity: a.drive(CurveTween(
      curve: Interval(
        0, 1/3,
        curve: Easing.emphasizedAccelerate
      )
    )),
    child: ColoredBox(
      color: Theme.of(ctx).colorScheme.surfaceContainerLowest,
      child: FadeTransition(
        opacity: a.drive(CurveTween(
          curve: Interval(
            1/3, 1,
            curve: Easing.emphasizedDecelerate
          )
        )),
        child: c,
      ),
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
)),
routes: [
  ShellRoute(
    builder: (ctx, state, child) => ShellPage(child: child),
    routes: [
      GoRoute(
        path: "/",
        name: "main",
        pageBuilder: (ctx, s) => fadeTransition(const HomePage()),
        routes: [
          GoRoute(
            name: "domain",
            path: ":domain",
            pageBuilder: (ctx, s) => fadeTransition(
              DomainPage(info: Neuro.of(ctx).domains[s.pathParameters["domain"]]!)
            ),
            routes: [
              GoRoute(
                path: "method/:method",
                name: "method",
                pageBuilder: (ctx, s) => fadeTransition(
                  MethodPage(info: Neuro.of(ctx).domains[s.pathParameters["domain"]!]!.methods[s.pathParameters["method"]]!)
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
  bool disconnected = true;
  void connect([bool spamSetState = true]) {
    if (!disconnected) return;
    disconnected = false;
    socket = WebSocketChannel.connect(Uri.parse("ws://localhost:1412"));
    client = Client(socket!.cast<String>());
    client!.listen().whenComplete((){
      disconnected = true;
      setState((){});
    });
    socket!.ready.then((e){
    client!.sendRequest("getProtocolInformation").then((v){
      domains = {
        for (final e in jsonDecode(v! as String)["domains"] as List<dynamic>)
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
    var drawer = NavigationDrawer(
      selectedIndex: drawerSelectedIndex,
      onDestinationSelected: (idx) {
        drawerSelectedIndex = idx;
        if (_router.state?.name == "method") {
          _router.pop();
        };
        _router.replace("/${domains.values.toList()[idx].name}");
      },
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0).copyWith(left: 16*2),
          child: Text("Domains",style: Theme.of(context).textTheme.titleSmall),
        ),
        ...domains.values.map(
          (d)=>NavigationDrawerDestination(
            icon: Icon(Icons.mode), 
            label: Text(d.name),
          )
        )
      ],
    );
    var box = Builder(
      builder: (context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
          ),
          color: Theme.of(context).colorScheme.surfaceContainerLowest
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: disconnected
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
          : domains.isEmpty 
            ? Center(child: CircularProgressIndicator(),) 
            : SizedBox.expand(
              child: SingleChildScrollView(
                child: widget.child
              )
            ),
        )
      )
    );
    String name = GoRouter.of(context).state!.name!;
    var t = ThemeData(
      colorScheme: 
      (disconnected
      ? mainScheme
      : name == "method"
        ? methodScheme
        : name == "domain"
          ? domainScheme
          : mainScheme
      )
    );
    debugPrint(name);
    return Neuro(
      domains: UnmodifiableMapView(domains),
      child: Theme(
        data: t,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text("GD Devtools Protocol Playground"),
          ),
          body: useModalNavigation ? box : Row(children: [
            // https://github.com/flutter/flutter/issues/123113
            Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  drawerTheme: DrawerThemeData(
                    elevation: 0,
                    shape: const RoundedRectangleBorder(),
                    endShape: const RoundedRectangleBorder(),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  )
                ),
                child: drawer,
              ),
            ),
            Expanded(child: box) 
          ],),
          drawer: useModalNavigation ? drawer : null
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
