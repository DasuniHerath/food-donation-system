import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class MemberApp extends StatelessWidget {
  const MemberApp({
    super.key,
    required this.token,
  });

  final String token;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MemberAppState(token: token),
      child: const OrgNavigationBar(),
    );
  }
}

class MemberAppState extends ChangeNotifier {
  MemberAppState({
    required this.token,
  });

  final String token;

  var deliveries = <Delivery>[];

  final wsUrlDelivery = Uri.parse(Platform.isAndroid
      ? 'ws://10.0.2.2:8000/memberdelivery'
      : 'ws://localhost:8000/memberdelivery');

  late IOWebSocketChannel wsDeliveryChannel;

  bool iswsDeliveryConnected = false;
  bool isStatusGot = false;

  bool status = false;

  void connectwsDelivery() async {
    if (iswsDeliveryConnected) return;
    wsDeliveryChannel = IOWebSocketChannel.connect(wsUrlDelivery);
    await wsDeliveryChannel.ready;
    wsDeliveryChannel.sink.add(token);
    iswsDeliveryConnected = true;
    wsDeliveryChannel.stream.listen((message) {
      updateDelivry(message);
    });
  }

  void updateDelivry(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    deliveries = jsonData.map((data) => Delivery.fromJson(data)).toList();
    notifyListeners();
  }

  Future<http.Response> setStatusActive(bool status) async {
    return http.put(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/change_status/?status=$status'
          : 'http://localhost:8000/change_status/?status=$status'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  Future<http.Response> getStatus() async {
    return await http.get(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/get_status/'
          : 'http://localhost:8000/get_status/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  Future<http.Response> rejectDelivery(String reason) async {
    return http.delete(
      Uri.parse(Platform.isAndroid
          ? 'http://10.0.2.2:8000/reject_delivery/'
          : 'http://localhost:8000/reject_delivery/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
      body: jsonEncode(<String, String>{
        'reason': reason,
      }),
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

  void initToggle() async {
    var appState = context.read<MemberAppState>();
    var response = await appState.getStatus();
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      toggle = jsonData['status'];
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MemberAppState>();
    appState.connectwsDelivery();
    initToggle();
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
              appState.setStatusActive(toggle);
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
                    appsState: appState,
                  ),
                ),
            ],
          ),
        ),

        // A row that containing a text and a button next to it
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Status:  ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Collected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => DeliveryOptionsDialog(),
                      ).then((value) {
                        if (value != null) {
                          setState(() {
                            // Change the status
                          });
                        }
                      });
                    },
                    child: const Text('Change'),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class DeliveryOptionsDialog extends StatelessWidget {
  final List<String> deliveryOptions = [
    'On the way',
    'Collected',
    'Delivering',
    'Delivered'
  ];

  DeliveryOptionsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var option in deliveryOptions)
            ListTile(
              title: Text(option),
              onTap: () {
                Navigator.pop(context, option);
              },
            ),
        ],
      ),
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
  final MemberAppState appsState;

  const DonorTile({
    Key? key,
    required this.request,
    required this.appsState,
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
            builder: (context) => RejectPage(
              appState: appsState,
            ),
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

  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Convert ISO 8601 format datetime into date and time
    var date = DateTime.parse(json['time']);
    var formattedDate = '${date.day}/${date.month}/${date.year}';
    var formattedTime =
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Delivery(
      date: formattedDate,
      time: formattedTime,
      category: categoryDict[json['category'].toString()]!['name']! as String,
      amount: json['amount'],
      donorAddress: json['donorAddress'],
      communityAddress: json['communityAddress'],
      icon: (categoryDict[json['category'].toString()]!['icon']! as Icon),
    );
  }
}

class RejectPage extends StatefulWidget {
  final MemberAppState appState;
  const RejectPage({super.key, required this.appState});

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
              onPressed: () {
                if (dropdownValue == 'Other') {
                  widget.appState.rejectDelivery(myController.text);
                } else {
                  widget.appState.rejectDelivery(dropdownValue);
                }
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
