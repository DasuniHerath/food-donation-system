import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DonorApp extends StatelessWidget {
  const DonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DonorAppState(),
      child: const OrgNavigationBar(),
    );
  }
}

class DonorAppState extends ChangeNotifier {
  var history = <Request>[];
  var requests = <Request>[
    Request(
        date: '12/12/2021',
        charityName: 'Compassion Connection',
        category: 'Rice',
        amount: 10,
        status: 'Delivering',
        icon: const Icon(Icons.rice_bowl),
        time: '12:00 PM'),
    Request(
        date: '12/12/2021',
        charityName: 'Unity Umbrella',
        category: 'Bread',
        amount: 5,
        status: 'Waiting',
        icon: const Icon(Icons.breakfast_dining),
        time: '12:00 PM'),
    Request(
        date: '11/04/2021',
        charityName: 'Hope Horizon',
        category: 'Fast Food',
        amount: 2,
        status: 'Found',
        icon: const Icon(Icons.fastfood),
        time: '12:00 PM'),
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
        ],
      ),
      body: <Widget>[
        Container(
          alignment: Alignment.center,
          child: const RequestPage(),
        ),
        Container(alignment: Alignment.center, child: const HistoryPage()),
      ][currentPageIndex],
    );
  }
}

// A page containing Requests
class RequestPage extends StatelessWidget {
  const RequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<DonorAppState>();

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
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<DonorAppState>();

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

class RequestTile extends StatelessWidget {
  final Request request;

  const RequestTile({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // watch the app state
    var appState = context.watch<DonorAppState>();

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
                    request.charityName,
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
                  Text(request.charityName),
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

class RequestBottomSheet extends StatelessWidget {
  final Request request;
  final DonorAppState appState;

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
      height: 250,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Text(
                  request.charityName,
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
                  request.amount.toString(),
                  textAlign: TextAlign.right,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.deepOrange),
                ),
              ],
            ),
            // button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.deepOrange),
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(100, 50)),
                  ),
                  child: const Text('Donate',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    minimumSize:
                        MaterialStateProperty.all<Size>(const Size(100, 50)),
                  ),
                  child: const Text('Reject'),
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
                  request.charityName,
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

class Request {
  final String date;
  final String charityName;
  final String category;
  final int amount;
  String status;
  final String time;
  final Icon icon;

  Request({
    required this.date,
    required this.charityName,
    required this.category,
    required this.amount,
    required this.status,
    required this.time,
    required this.icon,
  });
}