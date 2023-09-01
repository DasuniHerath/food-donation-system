import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  var history = <Request>[
    Request(
        date: '12/12/2021',
        restaurantName: 'Cafe World',
        category: 'Coffee',
        status: 'Open',
        icon: const Icon(Icons.star),
        time: '12:00 PM'),
    Request(
        date: '12/12/2021',
        restaurantName: 'Tasty Bites',
        category: 'Indian',
        status: 'Closed',
        icon: const Icon(Icons.favorite),
        time: '12:00 PM')
  ];
  var requests = <Request>[
    Request(
        date: '12/12/2021',
        restaurantName: 'Cafe World',
        category: 'Coffee',
        status: 'Open',
        icon: const Icon(Icons.star),
        time: '12:00 PM'),
    Request(
        date: '12/12/2021',
        restaurantName: 'Tasty Bites',
        category: 'Indian',
        status: 'Closed',
        icon: const Icon(Icons.favorite),
        time: '12:00 PM'),
    Request(
        date: '11/04/2021',
        restaurantName: 'Pizza Hut',
        category: 'Italian',
        status: 'Waiting',
        icon: const Icon(Icons.local_dining),
        time: '12:00 PM'),
  ];

  var employees = <Employee>[
    Employee(
        name: 'John Doe',
        email: 'example@gmail.com',
        phone: '1234567890',
        status: 'Active'),
    Employee(
        name: 'James Webb',
        email: 'james@outlook.com',
        phone: '0987654321',
        status: 'Inactive'),
  ];

  void addRequest(Request request) {
    requests.add(request);
    notifyListeners();
  }

  void cancelRequest(Request request) {
    requests.remove(request);
    request.status = 'Cancelled';
    history.add(request);
    notifyListeners();
  }

  void fireEmployee(Employee employee) {
    employees.remove(employee);
    notifyListeners();
  }

  void addEmployee(Employee employee) {
    employees.add(employee);
    notifyListeners();
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
            label: 'Employees',
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (var request in appState.requests)
                RequestTile(
                  request: request,
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
                        builder: (context) => NewRequest(appState: appState)),
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

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<OrganizationAppState>();

    return ListView(
      children: [
        for (var request in appState.history)
          HistoryTile(
            request: request,
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

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (var employee in appState.employees)
                EmployeeTile(
                  employee: employee,
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
    //
    super.key,
    required this.request,
  });

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    //
                    request.restaurantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    //
                    request.category,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                //
                request.icon,
                const SizedBox(width: 8),
                //
                Text(request.status),
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
    super.key,
    required this.request,
  });

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
    super.key,
    required this.employee,
  });

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
                    appState.cancelRequest(request);
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
                    appState.fireEmployee(employee);
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
  final String date;
  final String restaurantName;
  final String category;
  String status;
  final Icon icon;
  final String time;

  Request({
    required this.date,
    required this.restaurantName,
    required this.category,
    required this.status,
    required this.icon,
    required this.time,
  });
}

class Employee {
  final String name;
  final String email;
  final String phone;
  final String status;

  Employee({
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });
}

// Create new request
class NewRequest extends StatefulWidget {
  final OrganizationAppState appState;
  const NewRequest({super.key, required this.appState});

  @override
  State<NewRequest> createState() => _NewRequestState();
}

class _NewRequestState extends State<NewRequest> {
  // Create text fied controllers
  TextEditingController restaurantNameController = TextEditingController();

  TextEditingController categoryController = TextEditingController();

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
            TextField(
              controller: restaurantNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Restaurant Name',
              ),
            ),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Category',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add request
                widget.appState.addRequest(Request(
                    date: '12/12/2021',
                    restaurantName: restaurantNameController.text,
                    category: categoryController.text,
                    status: 'Open',
                    icon: const Icon(Icons.star),
                    time: '12:00 PM'));
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
  TextEditingController nameController = TextEditingController();

  TextEditingController emailController = TextEditingController();

  TextEditingController phoneController = TextEditingController();

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
              controller: nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Phone',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Add employee
                widget.appState.addEmployee(Employee(
                    name: nameController.text,
                    email: emailController.text,
                    phone: phoneController.text,
                    status: 'Active'));
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
