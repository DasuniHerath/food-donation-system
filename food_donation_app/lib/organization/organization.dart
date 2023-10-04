import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class OrganizationApp extends StatelessWidget {
  const OrganizationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrganizationAppState(),
      child: const OrgNavigationBar(),
    );
  }
}

class OrganizationAppState extends ChangeNotifier {
  final wsUrlOrgHistory = Uri.parse(Platform.isAndroid
      ? 'ws://10.0.2.2:8000/orghistory'
      : 'ws://localhost:8000/orghistory');
  final wsUrlOrgRequests = Uri.parse(Platform.isAndroid
      ? 'ws://10.0.2.2:8000/orgrequests'
      : 'ws://localhost:8000/orgrequests');
  final wsUrlOrgMembers = Uri.parse(Platform.isAndroid
      ? 'ws://10.0.2.2:8000/orgMembers'
      : 'ws://localhost:8000/orgMembers');
  bool isOrgHistoryConnected = false;
  bool isOrgRequestsConnected = false;
  bool isOrgMembersConnected = false;

  late IOWebSocketChannel orgHistoryChannel;
  late IOWebSocketChannel orgRequestsChannel;
  late IOWebSocketChannel orgMembersChannel;

  var history = <Request>[];
  var requests = <Request>[];
  var employees = <Employee>[];

  void connectOrgHistory() {
    // connect to websocket only if aleady not connected
    if (isOrgHistoryConnected) {
      return;
    }
    orgHistoryChannel = IOWebSocketChannel.connect(wsUrlOrgHistory);
    isOrgHistoryConnected = true;
    orgHistoryChannel.stream.listen((message) {
      updateHistory(message);
    });
  }

  void updateHistory(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    history = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  void connectOrgRequests() {
    // connect to websocket only if aleady not connected
    if (isOrgRequestsConnected) {
      return;
    }
    orgRequestsChannel = IOWebSocketChannel.connect(wsUrlOrgRequests);
    isOrgRequestsConnected = true;
    orgRequestsChannel.stream.listen((message) {
      updateRequests(message);
    });
  }

  void updateRequests(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    requests = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  void connectOrgMembers() {
    if (isOrgMembersConnected) {
      return;
    }
    orgMembersChannel = IOWebSocketChannel.connect(wsUrlOrgMembers);
    isOrgMembersConnected = true;
    orgMembersChannel.stream.listen((message) {
      updateMembers(message);
    });
  }

  void updateMembers(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    employees = jsonData.map((data) => Employee.fromJson(data)).toList();
    notifyListeners();
  }

  void addRequest(String category, int amount) {
    // Dictionary to convert category name to category id
    var categoryDict = {
      'Rice': 1,
      'Bread': 2,
      'Fast Food': 3,
    };
    addRequestToServer(categoryDict[category]!, amount);
    notifyListeners();
  }

  Future<http.Response> addRequestToServer(int category, int amount) {
    return http.post(
        Uri.parse(Platform.isAndroid
            ? 'http://10.0.2.2:8000/add_request/'
            : 'http://localhost:8000/add_request/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },

        // Convert data to JSON format
        body: jsonEncode(<String, dynamic>{
          'category': category,
          'amount': amount,
        }));
  }

  Future<http.Response> cancelRequest(int id) async {
    final http.Response response = await http.delete(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/delete_request/?id=$id'
          : 'http://localhost:8000/delete_request/?id=$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return response;
  }

  Future<http.Response> addMember(int id) {
    return http.post(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/add_member/?memberid=$id'
          : 'http://localhost:8000/add_member/?memberid=$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
  }

  Future<http.Response> fireMember(int id) async {
    final http.Response response = await http.delete(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/remove_member/?memberid=$id'
          : 'http://localhost:8000/remove_member/?memberid=$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return response;
  }
}

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
        Container(alignment: Alignment.center, child: const HistoryPage()),
        Container(
          alignment: Alignment.center,
          child: const EmployeesPage(),
        ),
      ][currentPageIndex],
    );
  }
}

// A page containing Requests
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

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();
    appState.connectOrgMembers();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
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
                        builder: (context) => NewEmployee(appState: appState)),
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

class RequestTile extends StatelessWidget {
  final Request request;

  const RequestTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // watch the app state
    var appState = context.watch<OrganizationAppState>();

    return InkWell(
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

class HistoryTile extends StatelessWidget {
  final Request request;

  const HistoryTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
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

class EmployeeTile extends StatelessWidget {
  final Employee employee;

  const EmployeeTile({
    Key? key,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();

    return InkWell(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(employee.status),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class RequestBottomSheet extends StatelessWidget {
  final Request request;
  final OrganizationAppState appState;

  const RequestBottomSheet({
    super.key,
    required this.request,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    // watch the app state
    // var appState = context.watch<OrganizationAppState>();

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
            // button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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

class HistoryBottomSheet extends StatelessWidget {
  final Request request;

  const HistoryBottomSheet({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    // watch the app state

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
            // button
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class EmployeeBottomSheet extends StatelessWidget {
  final Employee employee;
  final OrganizationAppState appState;

  const EmployeeBottomSheet({
    super.key,
    required this.employee,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    // watch the app state

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
    '0': 'Waiting',
    '1': 'Delivering',
    '2': 'Found',
    '3': 'Cancelled',
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
      status: statusDict[json['status'].toString()]!,
      time: formattedTime,
      icon: (categoryDict[json['category'].toString()]!['icon']! as Icon),
    );
  }
}

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
  final OrganizationAppState appState;
  const NewRequest({super.key, required this.appState});

  @override
  State<NewRequest> createState() => _NewRequestState();
}

class _NewRequestState extends State<NewRequest> {
  // Create text field controllers
  TextEditingController amountController = TextEditingController();

  String dropdownValue = 'Rice';

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
            SizedBox(
                width: 500,
                child: DropdownButton<String>(
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
                          const Icon(Icons
                              .star), // Replace this with the desired icon for each value
                          const SizedBox(width: 8),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                )),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add request
                widget.appState.addRequest(
                    dropdownValue, int.parse(amountController.text));
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

// Add new employee
class NewEmployee extends StatefulWidget {
  final OrganizationAppState appState;
  const NewEmployee({super.key, required this.appState});

  @override
  State<NewEmployee> createState() => _NewEmployeeState();
}

class _NewEmployeeState extends State<NewEmployee> {
  // Create text fied controllers

  TextEditingController idController = TextEditingController();

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
              onPressed: () {
                // Add employee
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
