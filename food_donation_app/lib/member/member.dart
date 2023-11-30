import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../chat.dart';

class MemberApp extends StatelessWidget {
  const MemberApp({super.key, required this.token, required this.hosturl});

  final String token; // Token for authentication with the server
  final String hosturl; // Host url of the server

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create an app state
      create: (context) => MemberAppState(token: token, hosturl: hosturl),
      child: const OrgNavigationBar(), // Create the navigation bar
    );
  }
}

// App state for the member app
class MemberAppState extends ChangeNotifier {
  MemberAppState({required this.token, required this.hosturl});

  final String token; // Token for authentication with the server
  final String hosturl; // Host url of the server

  // Store delivery details got from the server
  var deliveries = <Delivery>[];

  // Websocket channel for delivery
  late IOWebSocketChannel wsDeliveryChannel;

  bool iswsDeliveryConnected = false; // Check if websocket is connected
  bool isStatusGot = false; // Check if status is got from the server

  bool status = false; // Status of the member (active/inactive)

  // Create the relevant urls with given host url
  Uri getUrl(int num) {
    switch (num) {
      case 1:
        return Uri.parse('ws://$hosturl/memberdelivery');
      case 2:
        return Uri.parse('http://$hosturl/get_status/');
      case 3:
        return Uri.parse('http://$hosturl/reject_delivery/');
      default:
        return Uri.parse('ws://$hosturl/ws');
    }
  }

  // Create the relevant urls with given host url and id as a query parameter
  Uri getUrlWithId(int id) {
    return Uri.parse('http://$hosturl/update_delivery/?newState=$id');
  }

  // Create the relevant urls with given host url and state as a query parameter
  Uri getUrlWithState(bool state) {
    return Uri.parse('http://$hosturl/change_status/?status=$state');
  }

  // Create the relevant urls with given host url and rate  as a query parameter
  Uri getUrlWithRate(int rate) {
    return Uri.parse('http://$hosturl/add_rating/?rate=$rate');
  }

  // Connect to the websocket channel for delivery
  void connectwsDelivery() async {
    if (iswsDeliveryConnected) return;
    wsDeliveryChannel = IOWebSocketChannel.connect(getUrl(1));
    await wsDeliveryChannel.ready;
    wsDeliveryChannel.sink.add(token); // Send token to the server
    iswsDeliveryConnected = true;
    wsDeliveryChannel.stream.listen((message) {
      updateDelivry(message);
    });
  }

  // Update delivery details with the message got from the server
  void updateDelivry(String message) {
    List<dynamic> jsonData = jsonDecode(message);
    deliveries = jsonData.map((data) => Delivery.fromJson(data)).toList();
    notifyListeners();
  }

  // Change the status of the member in the server
  Future<http.Response> setStatusActive(bool status) async {
    return http.put(
      getUrlWithState(status),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  // Update member status with the status got from the server
  Future<http.Response> getStatus() async {
    return await http.get(
      getUrl(2),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  // Reject a delivery with the reason
  Future<http.Response> rejectDelivery(String reason) async {
    return http.delete(
      getUrl(3),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
      body: jsonEncode(<String, String>{
        'reason': reason,
      }),
    );
  }

  // Update delivery status with the new state
  Future<http.Response> updateDelivetyState(int newState) async {
    return http.put(
      getUrlWithId(newState),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  // Add rating at the end of the delivery
  Future<http.Response> addRating(int rate) async {
    return http.put(
      getUrlWithRate(rate),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }
}

// A navigation bar with two destinations
class OrgNavigationBar extends StatefulWidget {
  const OrgNavigationBar({super.key});

  @override
  State<OrgNavigationBar> createState() => _OrgNavigationBarState();
}

class _OrgNavigationBarState extends State<OrgNavigationBar> {
  int currentPageIndex = 0; // Current page index

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          SafeArea(
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Navigate to chat list page
                    builder: (context) => const ChatList(
                      title: 'Chat',
                      type: 'Member',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              iconSize: 40,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          // Change the current page index
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
        Container(alignment: Alignment.center, child: const DeliveryPage()),
      ][currentPageIndex >= 0 && currentPageIndex < 2 ? currentPageIndex : 0],
    );
  }
}

// A page containing delivery information and delivery status change button
class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  var toggle = false; // Toggle switch between active and inactive
  var deliveryState = 'Collected'; // Delivery state

  void initToggle() async {
    var appState = context.read<MemberAppState>();
    var response = await appState.getStatus();
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      toggle = jsonData['status'];
    }
  }

  // A dictionary to convert status id to status name
  static const statusDictReverse = {
    0: 'Waiting',
    1: 'Found',
    2: 'Rejected',
    3: 'Cancelled',
    4: 'On the way',
    5: 'Collected',
    6: 'Delivering',
    7: 'Delivered',
  };

  // Function to change delivery status in the server

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MemberAppState>();
    appState.connectwsDelivery();
    initToggle();
    // If delivery state is 7 (Delivered), show rating page
    return Column(
      children: [
        // If delivery state is 7 (Delivered), show rating page
        if (appState.deliveries.isNotEmpty &&
            appState.deliveries[0].status == 7) ...[
          SafeArea(
            child: AlertDialog(
              title: const Text('Rate your experience',
                  textAlign: TextAlign.center),
              content: HeartRating(appState: appState),
            ),
          )
        ],
        const SizedBox(height: 28),
        // Togle switch between active and inactive
        if ((appState.deliveries.isNotEmpty &&
                appState.deliveries[0].status != 7) ||
            (appState.deliveries.isEmpty)) ...[
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
                      delivery: request,
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
                Text(
                  // if appState.deliveries[0].status is null, show 'Waiting'
                  // else show the status name
                  appState.deliveries.isEmpty
                      ? 'Waiting'
                      : statusDictReverse[appState.deliveries[0].status]
                          .toString(),

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // Get next delivery state
                        var delState = appState.deliveries.isEmpty
                            ? 'Waiting'
                            : statusDictReverse[
                                    appState.deliveries[0].status + 1]
                                .toString();
                        showDialog(
                          context: context,
                          builder: (context) =>
                              DeliveryOptionsDialog(option: delState),
                        ).then((option) {
                          if (option != null) {
                            // If option is cancel, do nothing
                            if (option == 'Cancel') return;
                            setState(() {
                              // Change the status
                              appState.updateDelivetyState(
                                  appState.deliveries[0].status + 1);
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
        ]
      ],
    );
  }
}

// The dialog that pops up when the delivery status change button is pressed
class DeliveryOptionsDialog extends StatelessWidget {
  final String option; // The option that is going to be changed

  const DeliveryOptionsDialog({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change delivery status'),
      content: Text("Do you want to change the delivery status to $option?"),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

// Display key details of a delivery
class DonorTile extends StatelessWidget {
  final Delivery delivery; // Delivery details
  final MemberAppState appsState; // App state

  const DonorTile({
    Key? key,
    required this.delivery,
    required this.appsState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          // Navigate to reject page
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
                    delivery.donorAddress,
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
                    delivery.communityAddress,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    delivery.category,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                delivery.icon,
                const SizedBox(width: 8),
                // Change font color based on status(wainting = black, open = green, closed = red)
                Text(
                  delivery.amount.toString(),
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

// Represents a delivery
class Delivery {
  final String date;
  final String time;
  final String category;
  final int amount;
  final String donorAddress;
  final String communityAddress;
  final int status;
  final Icon icon;

  Delivery({
    required this.date,
    required this.time,
    required this.category,
    required this.amount,
    required this.donorAddress,
    required this.communityAddress,
    required this.status,
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
      status: json['status'],
      icon: (categoryDict[json['category'].toString()]!['icon']! as Icon),
    );
  }
}

// Select a reason for rejecting a delivery
class RejectPage extends StatefulWidget {
  final MemberAppState appState; // App state
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
            // Submit button
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

// Give a rating for the delivery by selecting a heart out of 5 hearts
class HeartRating extends StatefulWidget {
  final MemberAppState appState; // App state
  const HeartRating({super.key, required this.appState});

  @override
  HeartRatingState createState() => HeartRatingState();
}

class HeartRatingState extends State<HeartRating> {
  int _rating = 0; // Rating

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Rate your overall experience with the donor and donation',
              style: TextStyle(fontSize: 20),
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            // Create silectable 5 heart icons
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 35,
                icon: Icon(
                  _rating > index ? Icons.favorite : Icons.favorite_border,
                ),
                color: _rating > index ? Colors.deepOrange : Colors.grey,
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.appState.addRating(_rating);
                },
                child: const Text('Submit'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: () {}, child: const Text('Cancel')),
            ],
          )
        ],
      ),
    );
  }
}
