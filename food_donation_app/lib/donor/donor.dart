import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class DonorApp extends StatelessWidget {
  const DonorApp({super.key, required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DonorAppState(token: token),
      child: const OrgNavigationBar(),
    );
  }
}

class DonorAppState extends ChangeNotifier {
  DonorAppState({required this.token});

  final String token;

  var history = <Request>[];
  var requests = <Request>[];

  final List<String> items = List<String>.generate(100, (i) => "Item $i");

  final wsUrlDonRequests = Uri.parse(Platform.isAndroid
      ? 'ws://207.148.117.189/donorrequests'
      : 'ws://207.148.117.189/donorrequests');
  final wsUrlDonHistory = Uri.parse(Platform.isAndroid
      ? 'ws://207.148.117.189/donorhistory'
      : 'ws://207.148.117.189/donorhistory');

  late IOWebSocketChannel channelDonRequests;
  late IOWebSocketChannel channelDonHistory;

  bool isDonRequestsConnected = false;
  bool isDonHistoryConnected = false;

  void connectDonRequests() async {
    if (isDonRequestsConnected) return;
    channelDonRequests = IOWebSocketChannel.connect(wsUrlDonRequests);
    await channelDonRequests.ready;
    channelDonRequests.sink.add(token);
    isDonRequestsConnected = true;
    channelDonRequests.stream.listen((message) {
      updateDonRequests(message);
    });
  }

  void updateDonRequests(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    requests = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  void connectDonHistory() async {
    if (isDonHistoryConnected) return;
    channelDonHistory = IOWebSocketChannel.connect(wsUrlDonHistory);
    await channelDonHistory.ready;
    channelDonHistory.sink.add(token);
    isDonHistoryConnected = true;
    channelDonHistory.stream.listen((message) {
      updateDonHistory(message);
    });
  }

  void updateDonHistory(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    history = jsonData.map((data) => Request.fromJson(data)).toList();
    notifyListeners();
  }

  Future<http.Response> acceptDonRequest(int id) async {
    return http.put(
      Uri.parse(Platform.isAndroid
          ? 'http://207.148.117.189/accept_donation/?id=$id'
          : 'http://207.148.117.189/accept_donation/?id=$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  Future<http.Response> rejectDonRequest(int id) async {
    return http.delete(
      Uri.parse(Platform.isAndroid
          ? 'http://207.148.117.189/reject_donation/?id=$id'
          : 'http://207.148.117.189/reject_donation/?id=$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
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
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Donate'),
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
        const DonationPage(),
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
    appState.connectDonRequests();

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
    appState.connectDonHistory();

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
                  onPressed: () {
                    appState.acceptDonRequest(request.id);
                    Navigator.pop(context);
                  },
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
                  onPressed: () {
                    appState.rejectDonRequest(request.id);
                    Navigator.pop(context);
                  },
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
  final int id;
  final String date;
  final String charityName;
  final String category;
  final int amount;
  String status;
  final String time;
  final Icon icon;

  Request({
    required this.id,
    required this.date,
    required this.charityName,
    required this.category,
    required this.amount,
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
    1: 'Found',
    2: 'Rejected',
    3: 'Cancelled',
    4: 'On the way',
    5: 'Collected',
    6: 'Delivering',
    7: 'Delivered',
  };

  factory Request.fromJson(Map<String, dynamic> json) {
    // Convert ISO 8601 format datetime into date and time
    var date = DateTime.parse(json['time']);
    var formattedDate = '${date.day}/${date.month}/${date.year}';
    var formattedTime =
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Request(
      id: json['id'],
      date: formattedDate,
      charityName: json['name'],
      category: categoryDict[json['category'].toString()]!['name']! as String,
      amount: json['amount'],
      status: statusDict[json['status']]!,
      time: formattedTime,
      icon: (categoryDict[json['category'].toString()]!['icon']! as Icon),
    );
  }
}

class DonationPage extends StatelessWidget {
  const DonationPage({super.key});
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<DonorAppState>();
    return Column(
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
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DonationTile(
                  donation: Donation(
                      foodName: "Rice and Curry",
                      category: "Rice",
                      amount: 10,
                      time: DateTime.now().hour.toString()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Donation {
  final String foodName;
  final String category;
  final int amount;
  final String time;

  Donation({
    required this.foodName,
    required this.category,
    required this.amount,
    required this.time,
  });
}

class DonationTile extends StatelessWidget {
  const DonationTile({
    super.key,
    required this.donation,
  });

  final Donation donation;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('tapped');
      },
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  'https://live.staticflickr.com/2665/4006883441_9d154ccbf7_b.jpg',
                  width: 150,
                  height: 150,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
