import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat.dart';

class OrganizationApp extends StatelessWidget {
  // Getting token for autherization and hosturl for conect to server
  const OrganizationApp({
    super.key,
    required this.token,
    required this.hosturl,
  });
  final String token;
  final String hosturl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrganizationAppState(token: token, hosturl: hosturl),
      child: const OrgNavigationBar(), // Create the navigation bar
    );
  }
}

// Keep the state of the organization app
class OrganizationAppState extends ChangeNotifier {
  OrganizationAppState({
    required this.token,
    required this.hosturl,
  });

  final String token;
  final String hosturl;

  // Keep the status of websocket connections
  bool isOrgHistoryConnected = false;
  bool isOrgRequestsConnected = false;
  bool isOrgMembersConnected = false;

  // Websocket channels
  late IOWebSocketChannel orgHistoryChannel; // For history of requests
  late IOWebSocketChannel orgRequestsChannel; // For food requests
  late IOWebSocketChannel orgMembersChannel; // For member list

  // Lists to populate by retrived informations from websocket connections
  var history = <Request>[];
  var requests = <Request>[];
  var employees = <Employee>[];
  var donations = <Donation>[];

  // Create the relavent urls with the given host url
  Uri getUrl(int num) {
    switch (num) {
      case 1:
        return Uri.parse('ws://$hosturl/orghistory');
      case 2:
        return Uri.parse('ws://$hosturl/orgrequests');
      case 3:
        return Uri.parse('ws://$hosturl/orgMembers');
      case 4:
        return Uri.parse('http://$hosturl/add_request/');
      default:
        return Uri.parse('ws://$hosturl/ws');
    }
  }

  // Create the relavent urls with the given host url and a variable in query path
  Uri getUrlWithId(int num, int id) {
    switch (num) {
      case 1:
        return Uri.parse('http://$hosturl/delete_request/?id=$id');
      case 2:
        return Uri.parse('http://$hosturl/add_member/?memberid=$id');
      case 3:
        return Uri.parse('http://$hosturl/remove_member/?memberid=$id');
      default:
        return Uri.parse('ws://$hosturl/ws');
    }
  }

  // Connect the websocket connection for history
  void connectOrgHistory() async {
    // connect to websocket only if aleady not connected
    if (isOrgHistoryConnected) {
      return;
    }

    orgHistoryChannel = IOWebSocketChannel.connect(getUrl(1));
    // wait until orgHistoryChannel connected and write a message to the socket
    await orgHistoryChannel.ready;

    // Write a message to the socket
    orgHistoryChannel.sink.add(token);
    isOrgHistoryConnected = true;
    orgHistoryChannel.stream.listen((message) {
      updateHistory(message);
    });
  }

  // Rewrite the history list with the new data
  void updateHistory(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    history = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  // Connect the websocket connection for food requests
  void connectOrgRequests() async {
    // connect to websocket only if aleady not connected
    if (isOrgRequestsConnected) {
      return;
    }
    orgRequestsChannel = IOWebSocketChannel.connect(getUrl(2));
    await orgRequestsChannel.ready;

    // Write a message to the socket
    orgRequestsChannel.sink.add(token);
    isOrgRequestsConnected = true;
    orgRequestsChannel.stream.listen((message) {
      updateRequests(message);
    });
  }

  // Rewrite the requests list with the new data
  void updateRequests(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    requests = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  // Connect the websocket connection for members
  void connectOrgMembers() async {
    if (isOrgMembersConnected) {
      return;
    }
    orgMembersChannel = IOWebSocketChannel.connect(getUrl(3));
    await orgMembersChannel.ready;
    // Write a message to the socket
    orgMembersChannel.sink.add(token);
    isOrgMembersConnected = true;
    orgMembersChannel.stream.listen((message) {
      updateMembers(message);
    });
  }

  // Rewrite the employees list with the new data
  void updateMembers(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    employees = jsonData.map((data) => Employee.fromJson(data)).toList();
    notifyListeners();
  }

  // Add a new request
  void addRequest(String category, int amount, String comAddress) {
    // Dictionary to convert category name to category id
    var categoryDict = {
      'Rice': 1,
      'Bread': 2,
      'Fast Food': 3,
    };
    addRequestToServer(categoryDict[category]!, amount, comAddress);
    notifyListeners();
  }

  // Send a new request to the server
  Future<http.Response> addRequestToServer(
      int category, int amount, String comAddress) {
    return http.post(getUrl(4),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },

        // Convert data to JSON format
        body: jsonEncode(<String, dynamic>{
          'category': category,
          'amount': amount,
          'comAddress': comAddress,
        }));
  }

  // Cancel a request
  Future<http.Response> cancelRequest(int id) async {
    final http.Response response = await http.delete(
      getUrlWithId(1, id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Add a new member
  Future<http.Response> addMember(int id) {
    return http.post(
      getUrlWithId(2, id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Fire a member
  Future<http.Response> fireMember(int id) async {
    final http.Response response = await http.delete(
      getUrlWithId(3, id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }
}

// A navigation bar to navigate between pages
class OrgNavigationBar extends StatefulWidget {
  const OrgNavigationBar({super.key});

  @override
  State<OrgNavigationBar> createState() => _OrgNavigationBarState();
}

class _OrgNavigationBarState extends State<OrgNavigationBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A setting button in top right corner
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          SafeArea(
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.chat),
              iconSize: 40,
            ),
          ),
          const SizedBox(width: 8),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.settings),
              iconSize: 40,
              onPressed: () {
                // Add your settings functionality here
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: const Text('Do you want to logout'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.fastfood),
            label: 'Request',
          ),
          NavigationDestination(
              icon: Icon(Icons.favorite), label: 'Collectable'),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge),
            label: 'Members',
          ),
        ],
      ),
      body: <Widget>[
        Container(
          alignment: Alignment.center,
          child: const RequestPage(),
        ),
        Container(
          alignment: Alignment.center,
          child: const DonationPage(),
        ),
        Container(alignment: Alignment.center, child: const HistoryPage()),
        Container(
          alignment: Alignment.center,
          child: const EmployeesPage(),
        ),
      ][currentPageIndex],
    );
  }
}

// A page containing Requests and New Request button
class RequestPage extends StatelessWidget {
  const RequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();
    appState.connectOrgRequests();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (var request in appState.requests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RequestTile(
                    request: request,
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewRequest(appState: appState)),
                  );
                },
                label: const Text("Request"),
                icon: const Icon(Icons.restaurant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// A page containing History
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();
    appState.connectOrgHistory();

    return ListView(
      children: [
        for (var request in appState.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: HistoryTile(
              request: request,
            ),
          ),
      ],
    );
  }
}

// A page containing Employees and New Employee button
class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context
        .watch<OrganizationAppState>(); // Watch the app state for changes
    appState.connectOrgMembers(); // Connect to websocket

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // Create a tile for each employee
              for (var employee in appState.employees)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: EmployeeTile(
                    employee: employee,
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NewEmployee(
                            appState: appState)), // New employee page
                  );
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// A tile to display key details of a request in the request page
class RequestTile extends StatelessWidget {
  final Request request; // Request object

  const RequestTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appState = context
        .watch<OrganizationAppState>(); // Watch the app state for changes

    return InkWell(
      // Open a bottom sheet when tapped
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) => RequestBottomSheet(
                  request: request,
                  appState: appState,
                ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.restaurantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                request.icon,
                const SizedBox(width: 8),
                // Change font color based on status(wainting = black, open = green, closed = red)
                if (request.status == 'Waiting')
                  Text(
                    request.status,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  )
                else if (request.status == 'Delivering')
                  Text(
                    request.status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  )
                else
                  Text(
                    request.status,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 14,
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// A tile to display key details of a past request in the history page
class HistoryTile extends StatelessWidget {
  final Request request; // Request object

  const HistoryTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Open a bottom sheet when tapped
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) => HistoryBottomSheet(
                  request: request,
                ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(request.restaurantName),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(request.status),
                const SizedBox(width: 8),
                Text(request.time),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// A tile to display key details of an employee in the employee page
class EmployeeTile extends StatelessWidget {
  final Employee employee; // Employee object

  const EmployeeTile({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();

    return InkWell(
      // Open a bottom sheet when tapped
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) => EmployeeBottomSheet(
                  employee: employee,
                  appState: appState,
                ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A bottom sheet to display full details of a request and a cancel button
class RequestBottomSheet extends StatelessWidget {
  final Request request; // Request object
  final OrganizationAppState appState; // App state

  const RequestBottomSheet({
    super.key,
    required this.request,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Text(
                  request.restaurantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              request.icon,
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  request.status,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Amount: ${request.id}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  request.time,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // open chat with restaurant
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatPage(
                                title: request.restaurantName,
                              )),
                    );
                  },
                  label:
                      const Text('Donor', style: TextStyle(color: Colors.blue)),
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // open chat with member
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatPage(
                                title: request.id.toString(),
                              )),
                    );
                  },
                  label: const Text(
                    'Member',
                    style: TextStyle(color: Colors.green),
                  ),
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // cancel request
                    appState.cancelRequest(request.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// A bottom sheet to display full details of a past request
class HistoryBottomSheet extends StatelessWidget {
  final Request request; // Request object

  const HistoryBottomSheet({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Text(
                  request.restaurantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                request.time,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  request.status,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// A bottom sheet to display full details of an employee and a fire button
class EmployeeBottomSheet extends StatelessWidget {
  final Employee employee; // Employee object
  final OrganizationAppState appState; // App state

  const EmployeeBottomSheet({
    super.key,
    required this.employee,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Text(
                  employee.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Text(
                employee.status,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
            ]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    employee.email,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  employee.phone,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            // button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // fire employee
                    appState.fireMember(employee.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Fire'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// A class to represent a request
class Request {
  final int id;
  final String date;
  final String restaurantName;
  final String category;
  String status;
  final String time;
  final Icon icon;

  Request({
    required this.id,
    required this.date,
    required this.restaurantName,
    required this.category,
    required this.status,
    required this.time,
    required this.icon,
  });

  // A dictionary to get category name and icon from category id
  static const categoryDict = {
    '1': {
      'name': 'Rice',
      'icon': Icon(Icons.rice_bowl),
    },
    '2': {'name': 'Bread', 'icon': Icon(Icons.breakfast_dining)},
    '3': {'name': 'Fast Food', 'icon': Icon(Icons.fastfood)},
  };

  // A dictionary to get status name from status id
  static const statusDict = {
    0: 'Waiting',
    1: 'Rejected',
    2: 'Found',
    3: 'Cancelled',
    4: 'On the way',
    5: 'Collected',
    6: 'Delivering',
    7: 'Delivered',
  };

  // Function to convert JSON data to Request object
  factory Request.fromJson(Map<String, dynamic> json) {
    // Convert ISO 8601 format datetime into date and time
    var date = DateTime.parse(json['time']);
    var formattedDate = '${date.day}/${date.month}/${date.year}';
    var formattedTime =
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Request(
      id: json['id'],
      restaurantName: json['name'],
      date: formattedDate,
      category: categoryDict[json['category'].toString()]!['name']! as String,
      status: statusDict[json['status']]!,
      time: formattedTime,
      icon: (categoryDict[json['category'].toString()]!['icon']! as Icon),
    );
  }
}

// A class to represent an employee
class Employee {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String status;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  // A dictionary to convert status
  static const statusDict = {
    '0': 'Inactive',
    '1': 'Active',
  };

  // Function to convert JSON data to Employee object
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        status: statusDict[json['status'].toString()]!);
  }
}

// Create new request
class NewRequest extends StatefulWidget {
  final OrganizationAppState appState; // App state
  const NewRequest({super.key, required this.appState});

  @override
  State<NewRequest> createState() => _NewRequestState();
}

class _NewRequestState extends State<NewRequest> {
  // Create text field controllers
  TextEditingController amountController = TextEditingController(); // Amount
  TextEditingController comAddressController =
      TextEditingController(); // Community address

  String dropdownValue =
      'Rice'; // Initial value of dropdown menu to select category

  bool isCheckBoxSelected = false; // Status of the check box

  // Map icons to category names
  Map<String, Icon> categoryDict = {
    'Rice': const Icon(Icons.rice_bowl, color: Colors.green),
    'Bread': const Icon(Icons.breakfast_dining, color: Colors.brown),
    'Fast Food': const Icon(Icons.fastfood, color: Colors.orange),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Request'),
      ),
      body: Center(
        child: Column(
          // Create a form
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  width: 500,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      // Dropdown menu to select category
                      value: dropdownValue,
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                      items: <String>['Rice', 'Bread', 'Fast Food']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: categoryDict[value],
                              ), // Replace this with the desired icon for each value
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                // Text field to enter amount
                controller: amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Amount',
                ),
              ),
            ),
            const SizedBox(height: 8),
            // A tick box to select if the order is directly to the community
            Row(
              children: [
                Checkbox(
                  // Checkbox to select if the order is directly to the community
                  value: isCheckBoxSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      isCheckBoxSelected = value!;
                    });
                  },
                ),
                const Text('Order directly to the community'),
              ],
            ),
            // Display the address text field if the checkbox is selected
            Visibility(
                visible: isCheckBoxSelected,
                child: const SizedBox(
                  height: 8,
                )),
            Visibility(
              visible: isCheckBoxSelected,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: comAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Community Address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Add request
                widget.appState.addRequest(
                    dropdownValue,
                    int.parse(amountController.text),
                    isCheckBoxSelected ? comAddressController.text : 'default');

                Navigator.pop(context); // Go back to the previous page
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// Add new employee
class NewEmployee extends StatefulWidget {
  final OrganizationAppState appState;
  const NewEmployee({super.key, required this.appState});

  @override
  State<NewEmployee> createState() => _NewEmployeeState();
}

class _NewEmployeeState extends State<NewEmployee> {
  TextEditingController idController = TextEditingController(); // Member ID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Employee'),
      ),
      body: Center(
        child: Column(
          // Create a form
          children: <Widget>[
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Member ID',
              ),
            ),
            ElevatedButton(
              // Add employee
              onPressed: () {
                widget.appState.addMember(int.parse(idController.text));
                Navigator.pop(context);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

// Donation class to represent a donation listed by donors
class Donation {
  final String foodName;
  final String category;
  final int amount;
  final String time;
  final ImageProvider? image;

  Donation({
    required this.foodName,
    required this.category,
    required this.amount,
    required this.time,
    required this.image,
  });
}

// Display list of donations
class DonationPage extends StatelessWidget {
  const DonationPage({super.key});
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Listed Donations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (var donation in appState.donations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: DonationTile(
                      donation: donation,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tile to display key details of a donation
class DonationTile extends StatelessWidget {
  const DonationTile({
    super.key,
    required this.donation,
  });

  final Donation donation; // Donation object
  @override
  Widget build(BuildContext context) {
    var app = context.watch<OrganizationAppState>();
    return InkWell(
      onTap: () {
        // Open a bottom sheet when tapped
        showModalBottomSheet(
            context: context,
            builder: (context) => DonationBottomSheet(
                  donation: donation,
                  appState: app,
                ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    donation.foodName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    donation.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    donation.amount.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(child: Container()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // An internet image
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image(
                      image: donation.image!,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Bottom sheet to display full details of a donation and a accept button
class DonationBottomSheet extends StatelessWidget {
  const DonationBottomSheet(
      {super.key, required this.donation, required this.appState});

  final Donation donation; // Donation object
  final OrganizationAppState appState; // App state

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Column(
        children: [
          Container(
            height: 200, // replace with your value
            decoration: BoxDecoration(
              image: DecorationImage(
                image: donation.image!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              donation.foodName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                donation.category,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 16),
              Text(
                '${donation.amount.toString()} qty',
                style: const TextStyle(fontSize: 16, color: Colors.deepOrange),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Expiry Date and Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            donation.time,
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                    onPressed: () {
                      // Accept donation
                      Navigator.pop(context);
                    },
                    child: const Text('Accept')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
