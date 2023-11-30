import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:food_donation_app/donor/donor.dart';
import 'package:food_donation_app/organization/organization.dart';
import 'member/member.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Donate Food'; // App title

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData(
          // Theme for the app
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const Scaffold(
        body: LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final String hosturl = '10.0.2.2:8000'; // Server url

  TextEditingController nameController = TextEditingController(); // Username
  TextEditingController passwordController =
      TextEditingController(); // Password

  // Username password combination hardcoded for testing
  Map<String, String> passwordMap = {
    "user1": "12,34,56",
    "user2": "12,34,56",
    "user3": "12,34,56",
  };
  Map<String, String> tokenMap = {
    "user1": "token1",
    "user2": "donor1",
    "user3": "member1",
  };
  Map<String, int> typeMap = {
    "user1": 1,
    "user2": 2,
    "user3": 3,
  };

  // Validate username and password
  bool validate(String username, String password) {
    if (passwordMap.containsKey(username) == false) {
      return false;
    } else if (passwordMap[username] == password) {
      return true;
    }
    return false;
  }

  // Get token from username
  String getToken(String username) {
    return tokenMap[username]!;
  }

  // Laod the organization if not already loaded
  Future<http.Response> addOrgToServer(String token) async {
    return http.post(
      Uri.parse(Platform.isAndroid
          ? 'http://$hosturl/add_organization/'
          : 'http://$hosturl/add_organization/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Laod the donor if not already loaded
  Future<http.Response> addDonToServer(String token) async {
    return http.post(
      Uri.parse(Platform.isAndroid
          ? 'http://$hosturl/add_donor/'
          : 'http://$hosturl/add_donor/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Laod the member if not already loaded
  Future<http.Response> addMemToServer(String token) async {
    return http.post(
      Uri.parse(Platform.isAndroid
          ? 'http://$hosturl/load_member/'
          : 'http://$hosturl/load_member/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Send usernam and password to server and recieve token
  Future<http.Response> getTokenFromServer(
      String username, String password) async {
    return http.post(
      Uri.parse(Platform.isAndroid
          ? 'http://$hosturl/token/?username=$username&password=$password'
          : 'http://$hosturl/token/?username=$username&password=$password'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 30),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: 400,
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: SizedBox(
                  width: 400,
                  child: TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
              ),
              // Space between login button and password field
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              ),
              Container(
                height: 50,
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ElevatedButton(
                    child: const Text('Login'),
                    onPressed: () {
                      // Handle login
                      if (validate(
                          nameController.text, passwordController.text)) {
                        if (typeMap[nameController.text] == 1) {
                          addOrgToServer(getToken(nameController.text));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrganizationApp(
                                        token: getToken(nameController.text),
                                        hosturl: hosturl,
                                      )));
                        } else if (typeMap[nameController.text] == 2) {
                          addDonToServer(getToken(nameController.text));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DonorApp(
                                        token: getToken(nameController.text),
                                        hosturl: hosturl,
                                      )));
                        } else if (typeMap[nameController.text] == 3) {
                          addMemToServer(getToken(nameController.text));
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MemberApp(
                                        token: getToken(nameController.text),
                                        hosturl: hosturl,
                                      )));
                        }
                      } else {
                        // if token recieved from sserver
                        getTokenFromServer(
                                nameController.text, passwordController.text)
                            .then((value) {
                          if (value.statusCode == 200) {
                            // If token recieved from server
                            // Add token to token map
                            tokenMap[nameController.text] =
                                jsonDecode(value.body)['access'];
                            // Add username and password to password map
                            passwordMap[nameController.text] =
                                passwordController.text;
                            // Add type to type map
                            typeMap[nameController.text] =
                                jsonDecode(value.body)['type'];
                            // Add user to server
                            if (typeMap[nameController.text] == 1) {
                              addOrgToServer(getToken(nameController.text));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OrganizationApp(
                                            token:
                                                getToken(nameController.text),
                                            hosturl: hosturl,
                                          )));
                            } else if (typeMap[nameController.text] == 2) {
                              addDonToServer(getToken(nameController.text));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => DonorApp(
                                            token:
                                                getToken(nameController.text),
                                            hosturl: hosturl,
                                          )));
                            } else if (typeMap[nameController.text] == 3) {
                              addMemToServer(getToken(nameController.text));
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MemberApp(
                                            token:
                                                getToken(nameController.text),
                                            hosturl: hosturl,
                                          )));
                            }
                          } else {
                            // Show error message
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Error"),
                                    content: const Text(
                                        "Invalid username or password. Please try again."),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text("Close"))
                                    ],
                                  );
                                });
                          }
                        });
                      }
                    }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Does not have account?'),
                  TextButton(
                    child: const Text(
                      'Sign in',
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      //signup screen
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignInPage(
                                    hosturl: hosturl,
                                  )));
                    },
                  )
                ],
              ),
            ],
          )),
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key, required this.hosturl}) : super(key: key);
  final String hosturl;

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final TextEditingController _firstNameController =
      TextEditingController(); // First name
  final TextEditingController _lastNameController =
      TextEditingController(); // Last name
  final TextEditingController _usernameController =
      TextEditingController(); // Username
  final TextEditingController _passwordController =
      TextEditingController(); // Password

  // Send the sign up request to the server
  Future<http.Response> signUp(String firstName, String lastName,
      String username, String password) async {
    return http.post(
        Uri.parse(Platform.isAndroid
            ? 'http://${widget.hosturl}/signup/'
            : 'http://${widget.hosturl}/signup/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        // Send data from textedit controllers to server

        body: jsonEncode(<String, String>{
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'password': password,
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      // Allign the text fields in the center
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 400,
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'First Name',
                  ),
                ),
              ),
              Container(
                width: 400,
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Last Name',
                  ),
                ),
              ),
              Container(
                width: 400,
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                  ),
                ),
              ),
              Container(
                width: 400,
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Send sign up request to server
                    signUp(_firstNameController.text, _lastNameController.text,
                        _usernameController.text, _passwordController.text);
                  },
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
