import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MemberApp extends StatelessWidget {
  const MemberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MemberAppState(),
      child: const OrgNavigationBar(),
    );
  }
}

class MemberAppState extends ChangeNotifier {
  var history = <Delivery>[];
  var deliveries = <Delivery>[
    Delivery(
      date: '2021-10-01',
      time: '10:00',
      category: 'Bread',
      amount: 10,
      donorAddress: '123 Main St',
      communityAddress: '456 Main St',
      icon: const Icon(Icons.breakfast_dining),
    ),
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
            icon: Icon(Icons.airport_shuttle),
            label: 'Delivey',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: <Widget>[
        Container(
          alignment: Alignment.center,
          child: const RequestPage(),
        ),
        Container(alignment: Alignment.center, child: const ProfilePage()),
      ][currentPageIndex],
    );
  }
}

// A page containing Requests
class RequestPage extends StatefulWidget {
  const RequestPage({super.key});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  var toggle = false;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MemberAppState>();

    return Column(
      children: [
        const SizedBox(height: 28),
        // Togle switch between active and inactive
        SwitchListTile(
          // Title in large font
          title: const Text(
            'Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          value: toggle,
          onChanged: (bool value) {
            setState(() {
              toggle = !toggle;
            });
          },
          activeColor: Colors.green,
        ),

        Expanded(
          child: ListView(
            children: [
              for (var request in appState.deliveries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: DonorTile(
                    request: request,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // return an empty container for now
    return Container();
  }
}

class DonorTile extends StatelessWidget {
  final Delivery request;

  const DonorTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // watch the app state
    // var appState = context.watch<MemberAppState>();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RejectPage(),
          ),
        );
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
                  const Text(
                    // Donor name:
                    'Donor Address:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    // Donor address:
                    request.donorAddress,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    // Donor name:
                    'Community Address:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    // Donor address:
                    request.communityAddress,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.category,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
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
                Text(
                  request.amount.toString(),
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 14,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  final Delivery request;

  const HistoryTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RejectPage(),
          ),
        );
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
                  Text(request.category),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(request.communityAddress),
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

class Delivery {
  final String date;
  final String time;
  final String category;
  final int amount;
  final String donorAddress;
  final String communityAddress;
  final Icon icon;

  Delivery({
    required this.date,
    required this.time,
    required this.category,
    required this.amount,
    required this.donorAddress,
    required this.communityAddress,
    required this.icon,
  });
}

class RejectPage extends StatefulWidget {
  const RejectPage({super.key});

  @override
  RejectPageState createState() => RejectPageState();
}

class RejectPageState extends State<RejectPage> {
  String dropdownValue = 'Food is spoiled';
  final myController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a reason'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            DropdownButton<String>(
              value: dropdownValue,
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
              },
              items: <String>[
                'Food is spoiled',
                'Less than required amount',
                'Qulity is bad',
                'Other',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            if (dropdownValue == 'Other') ...[
              TextField(
                controller: myController,
              )
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
