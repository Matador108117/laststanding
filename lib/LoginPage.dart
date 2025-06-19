import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import "MyAppState.dart";

String loginPostMutation = """
mutation TokenAuth(\$username : String!,  \$password : String!) {
  tokenAuth(
    username: \$username 
    password: \$password 
  ) {
    token
  }
}
""";

const String meQuery = """
query Me {
  me {
    id
    username
  }
}
""";

String createPostMutation = """
mutation CreateUser(\$email : String!,  \$password : String!, \$username : String!) {
  createUser(
    email: \$email 
    password: \$password 
    username: \$username 
  ) {
    user {
      id
      email
      username
    }
  }
}
""";

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  TextEditingController createEmailController = TextEditingController();
  TextEditingController createPasswordController = TextEditingController();
  TextEditingController createUserController = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  void mostrarAlerta({
    required AlertType tipo,
    required String titulo,
    required String descripcion,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Alert(
        context: context,
        type: tipo,
        title: titulo,
        desc: descripcion,
        buttons: [
          DialogButton(
            onPressed: () => Navigator.pop(context), // ✅ CORREGIDO
            child: Text("Aceptar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ).show();
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.token.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome ${appState.username}"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                mostrarAlerta(
                  tipo: AlertType.info,
                  titulo: appState.username,
                  descripcion: "Tu sesión se ha cerrado correctamente.",
                );

                setState(() {
                  appState.username = "";
                  appState.token = "";
                });
              },
              child: Text('Logout'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: _formKey1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Ingrese credenciales", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: userNameController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingrese un usuario' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
                    ),
                    SizedBox(height: 10),
                    Mutation(
                      options: MutationOptions(
                        document: gql(loginPostMutation),
                        onCompleted: (result) async {
                          if (result == null) return;

                          final token = result["tokenAuth"]["token"];
                          setState(() => appState.token = token);

                          final client = GraphQLClient(
                            link: AuthLink(getToken: () async => 'JWT $token')
                                .concat(HttpLink("http://localhost:8000/graphql/")),
                            cache: GraphQLCache(),
                          );

                          final meResult = await client.query(QueryOptions(document: gql(meQuery)));

                          if (meResult.hasException) {
                            appState.error = meResult.exception.toString();
                            mostrarAlerta(
                              tipo: AlertType.error,
                              titulo: "Error al obtener datos",
                              descripcion: appState.error,
                            );
                            return;
                          }

                          final userData = meResult.data?['me'];
                          setState(() {
                            appState.username = userData['username'];
                            appState.userId = int.parse(userData['id'].toString());
                            appState.selectedIndex = 1;
                          });

                          mostrarAlerta(
                            tipo: AlertType.info,
                            titulo: appState.username,
                            descripcion: "Welcome to BoatApp",
                          );
                        },
                        onError: (error) {
                          appState.error = error?.graphqlErrors.first.message ?? "Error desconocido";
                          mostrarAlerta(
                            tipo: AlertType.error,
                            titulo: "Login error",
                            descripcion: appState.error,
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton(
                          onPressed: () {
                            if (_formKey1.currentState!.validate()) {
                              runMutation({
                                "username": userNameController.text,
                                "password": passwordController.text,
                              });
                            }
                          },
                          child: Text('Login'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Crear Usuario nuevo", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: createEmailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingrese un email' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: createUserController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingrese un nombre de usuario' : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: createPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
                    ),
                    SizedBox(height: 10),
                    Mutation(
                      options: MutationOptions(
                        document: gql(createPostMutation),
                        onCompleted: (result) {
                          if (result == null) return;

                          appState.username = createUserController.text;
                          userNameController.text = appState.username;

                          createEmailController.clear();
                          createUserController.clear();
                          createPasswordController.clear();

                          mostrarAlerta(
                            tipo: AlertType.success,
                            titulo: appState.username,
                            descripcion: "Usuario creado. Ahora puedes iniciar sesión.",
                          );
                        },
                        onError: (error) {
                          appState.error = error?.graphqlErrors.first.message ?? "Error desconocido";
                          mostrarAlerta(
                            tipo: AlertType.error,
                            titulo: "Error al crear usuario",
                            descripcion: appState.error,
                          );
                        },
                      ),
                      builder: (runMutation, result) {
                        return ElevatedButton(
                          onPressed: () {
                            if (_formKey2.currentState!.validate()) {
                              runMutation({
                                "email": createEmailController.text,
                                "password": createPasswordController.text,
                                "username": createUserController.text,
                              });
                            }
                          },
                          child: Text('Crear Usuario'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
