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
        icon: const Icon(Icons.star)),
    Request(
        date: '12/12/2021',
        restaurantName: 'Tasty Bites',
        category: 'Indian',
        status: 'Closed',
        icon: const Icon(Icons.favorite)),
  ];
  var requests = <Request>[
    Request(
        date: '12/12/2021',
        restaurantName: 'Cafe World',
        category: 'Coffee',
        status: 'Open',
        icon: const Icon(Icons.star)),
    Request(
        date: '12/12/2021',
        restaurantName: 'Tasty Bites',
        category: 'Indian',
        status: 'Closed',
        icon: const Icon(Icons.favorite)),
    Request(
        date: '11/04/2021',
        restaurantName: 'Pizza Hut',
        category: 'Italian',
        status: 'Waiting',
        icon: const Icon(Icons.local_dining)),
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
                  icon: request.icon,
                  status: request.status,
                  name: request.restaurantName,
                  category: request.category,
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
                  // Handle button tap
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
            date: request.date,
            restaurant: request.restaurantName,
            status: request.icon,
            time: '12:00 PM',
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
                  name: employee.name,
                  email: employee.email,
                  phone: employee.phone,
                  status: employee.status,
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
                  // Handle button tap
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
  final Icon icon;
  final String status;
  final String name;
  final String category;

  const RequestTile({
    super.key,
    required this.icon,
    required this.status,
    required this.name,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // handle tile tap
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
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(status),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final String date;
  final String restaurant;
  final Icon status;
  final String time;

  const HistoryTile({
    super.key,
    required this.date,
    required this.restaurant,
    required this.status,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle tile tap
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
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                status,
                const SizedBox(width: 8),
                Text(time),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class EmployeeTile extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String status;

  const EmployeeTile({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle tile tap
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
                    name,
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
                Text(status),
              ],
            )
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
  final String status;
  final Icon icon;

  Request({
    required this.date,
    required this.restaurantName,
    required this.category,
    required this.status,
    required this.icon,
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
