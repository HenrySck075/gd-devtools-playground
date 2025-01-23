import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:gdp_playground/confe.dart';
import 'package:gdp_playground/domain.dart';
import 'package:gdp_playground/g.dart';
import 'package:gdp_playground/home.dart';
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
              DomainPage(info: Neuro.of(ctx).domains.firstWhere((d)=>d.name == s.pathParameters["domain"]))
            ),
            routes: [
              GoRoute(
                path: "method/:method",
                name: "method",
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
      String currentPath = _router.state?.name ?? "main";
      return MaterialApp.router(
        routerConfig: _router,
        title: 'g',
        theme: ThemeData(
          colorScheme: currentPath == "method"
          ? methodScheme
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
  // shell is the main owner copy of it
  List<Domain> domains = [];
  @override
    void initState() {
      super.initState();
      client.listen();
      client.sendRequest("getProtocolInformation").then((v){
        domains = (v! as Map<String, dynamic>)["domains"];
        setState((){});
      });
    }

  bool useModalNavigation = false;

  @override
  Widget build(BuildContext context) {
    var drawer = NavigationDrawer(
      children: [
        Text("Domains",style: Theme.of(context).textTheme.titleSmall),
        ...domains.map((d)=>NavigationDrawerDestination(icon: SizedBox.shrink(), label: Text(d.name),))
      ],
      onDestinationSelected: (idx) {
        _router.push("/${domains[idx].name}");
      },
    );
    var box = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Theme.of(context).colorScheme.surface
      ),
      child: widget.child,
    );
    return Neuro(
      domains: UnmodifiableListView(domains),
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
