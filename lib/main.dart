import 'dart:collection';

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

late final WebSocketChannel socket;
late final Client client;

CustomTransitionPage fadeTransition(Widget child) => CustomTransitionPage(
  child: child, 
  transitionDuration: Duration(milliseconds: 500),
  transitionsBuilder: (ctx, a, sa, c) => FadeTransition(
    opacity: a.drive(CurveTween(
      curve: Interval(1/3*2, 1, curve: Easing.emphasizedDecelerate)
    )),
    child: FadeTransition(
      opacity: sa.drive(CurveTween(
        curve: Interval(0,1/3*2, curve: Easing.emphasizedAccelerate),
      )),
      child: c,
    ),
  )
);

class ChangeNotifier2 extends ChangeNotifier {
  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}
final ChangeNotifier2 unsogged = ChangeNotifier2();

class SoggyObserver extends NavigatorObserver {
  @override
  void didChangeTop(Route topRoute, Route? previousTopRoute) {
  }
}

final _router = GoRouter(
observers: [SoggyObserver()],
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
  socket = WebSocketChannel.connect(Uri.parse("ws://localhost:1412"));
  client = Client(socket.cast<String>());
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: unsogged,
    builder: (ctx,c) {
      String currentPath;
      try {currentPath = _router.state?.name ?? "main";}
      on StateError {
        currentPath = "main";
      }
      return MaterialApp.router(
        routerConfig: _router,
        title: 'g',
        theme: ThemeData(
          colorScheme: currentPath == "method"
          ? methodScheme
          : currentPath == "domain" 
          ? domainScheme
          : mainScheme,
          useMaterial3: true,
        ),
      );
    }
  );
}

class ShellPage extends StatefulWidget {
  final Widget child;
  const ShellPage({super.key, required this.child});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  // shell is the main owner of it
  Map<String, Domain> domains = {};
  bool disconnected = false;
  void connect([bool spamSetState = true]) {
    disconnected = false;
    client.listen().whenComplete((){
      disconnected = true;
      if (spamSetState) setState((){});
    });
    if (spamSetState) setState((){});
  }
  @override
  void initState() {
    super.initState();
    connect(false);
    client.sendRequest("getProtocolInformation").then((v){
      domains = {
        for (final e in (v! as Map<String, dynamic>)["domains"] as List<Map<String, dynamic>>)
        e["domain"]: Domain(e)
      };
      setState((){});
    });
  }

  bool useModalNavigation = false;

  int drawerSelectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    var drawer = NavigationDrawer(
      selectedIndex: drawerSelectedIndex,
      onDestinationSelected: (idx) {
        drawerSelectedIndex = idx;
        _router.push("/${domains.values.toList()[idx].name}");
      },
      children: [
        Text("Domains",style: Theme.of(context).textTheme.titleSmall),
        ...domains.values.map(
          (d)=>NavigationDrawerDestination(
            icon: SizedBox.shrink(), 
            label: Text(d.name),
          )
        )
      ],
    );
    var box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Theme.of(context).colorScheme.surface
      ),
      child: disconnected
      ? Center(
        child: Column(
          children: [
            Text("Launch Geometry Dash and reconnect to start using the playground!"),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100),
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
        : widget.child,
    );
    return Neuro(
      domains: UnmodifiableMapView(domains),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text("GD Devtools Protocol Playground"),
        ),
        body: useModalNavigation ? box : Row(children: [
          // https://github.com/flutter/flutter/issues/123113
          Theme(
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
          box 
        ],),
        drawer: useModalNavigation ? drawer : null
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    useModalNavigation = MediaQuery.sizeOf(context).width <= 839; // <= medium
  }
}
