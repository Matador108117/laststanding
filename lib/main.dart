import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'LoginPage.dart';
import 'LogsPage.dart';
import 'SeguimientoPage.dart';
import 'MyAppState.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: Builder(
        builder: (context) {
          final appState = context.watch<MyAppState>();

          final authLink = AuthLink(
            getToken: () async => 'JWT ${appState.token}',
          );

          final httpLink = authLink.concat(
            HttpLink('http://localhost:8000/graphql/'),
          );

          final client = ValueNotifier(
            GraphQLClient(
              link: httpLink,
              cache: GraphQLCache(),
            ),
          );

          return GraphQLProvider(
            client: client,
            child: MaterialApp(
              title: 'BoatApp',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              home: MyHomePage(),
            ),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    Widget page;
    switch (appState.selectedIndex) {
      case 0:
        page = LoginPage();
        break;
      case 1:
        page = SeguimientoPage();
        break;
      case 2:
        page = LogsPage();
        break;
      case 3:
        page = LoginPage(); // Puedes cambiar a PerfilPage si lo implementas
        break;
      default:
        throw UnimplementedError('No widget for ${appState.selectedIndex}');
    }

    var mainArea = ColoredBox(
      color: Theme.of(context).colorScheme.onError,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Login',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_box),
                        label: 'Add boat tweet',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.abc_sharp),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.add_box),
                        label: 'Acount',
                      ),
                    ],
                    currentIndex: appState.selectedIndex,
                    onTap: (value) {
                      appState.selectedIndex = value;
                    },
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Login'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.add_box),
                        label: Text('Add tweet'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.account_circle),
                        label: Text('Perfil'),
                      ),
                    ],
                    selectedIndex: appState.selectedIndex,
                    onDestinationSelected: (value) {
                      appState.selectedIndex = value;
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}
