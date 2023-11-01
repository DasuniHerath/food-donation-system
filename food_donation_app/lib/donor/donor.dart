import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DonorApp extends StatelessWidget {
  const DonorApp({super.key, required this.token, required this.hosturl});
  final String token;
  final String hosturl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DonorAppState(token: token, hosturl: hosturl),
      child: const OrgNavigationBar(),
    );
  }
}

class DonorAppState extends ChangeNotifier {
  DonorAppState({required this.token, required this.hosturl});

  final String token;
  final String hosturl;

  var history = <Request>[];
  var requests = <Request>[];
  var donations = <Donation>[];

  final List<String> items = List<String>.generate(100, (i) => "Item $i");

  late IOWebSocketChannel channelDonRequests;
  late IOWebSocketChannel channelDonHistory;

  bool isDonRequestsConnected = false;
  bool isDonHistoryConnected = false;

  Uri getUrl(int num) {
    switch (num) {
      case 1:
        return Uri.parse('ws://$hosturl/donorrequests');
      case 2:
        return Uri.parse('ws://$hosturl/donorhistory');
      default:
        return Uri.parse('ws://$hosturl/ws');
    }
  }

  Uri getUrlWithId(int num, int id) {
    switch (num) {
      case 1:
        return Uri.parse('http://$hosturl/accept_donation/?id=$id');
      case 2:
        return Uri.parse('http://$hosturl/reject_donation/?id=$id');
      default:
        return Uri.parse('ws://$hosturl/ws');
    }
  }

  void connectDonRequests() async {
    if (isDonRequestsConnected) return;
    channelDonRequests = IOWebSocketChannel.connect(getUrl(1));
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
    channelDonHistory = IOWebSocketChannel.connect(getUrl(2));
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
      getUrlWithId(1, id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  Future<http.Response> rejectDonRequest(int id) async {
    return http.delete(
      getUrlWithId(2, id),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'bearer $token',
      },
    );
  }

  void listDonation(Donation donation) {
    donations.add(donation);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Navigate to donation form page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DonationForm(
                          appState: appState,
                        ),
                      ),
                    );
                  },
                  label: const Text("Add"),
                  icon: const Icon(Icons.favorite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DonationForm extends StatefulWidget {
  const DonationForm({super.key, required this.appState});
  final DonorAppState appState;
  @override
  // ignore: library_private_types_in_public_api
  _DonationFormState createState() => _DonationFormState();
}

class _DonationFormState extends State<DonationForm> {
  File? _foodImage;

  TextEditingController foodNameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  // A variable to store the expiry date and time
  String _expiryController = '00/00/0000 00:00 AM';

  String dropdownValue = 'Rice';

  Map<String, Icon> categoryDict = {
    'Rice': const Icon(Icons.rice_bowl, color: Colors.green),
    'Bread': const Icon(Icons.breakfast_dining, color: Colors.brown),
    'Fast Food': const Icon(Icons.fastfood, color: Colors.orange),
  };

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (pickedImage != null) {
      // Check the file extension to ensure it's a .jpg image
      if (pickedImage.path.endsWith('.webp') ||
          pickedImage.path.endsWith('.jpg')) {
        setState(() {
          _foodImage = File(pickedImage.path);
          debugPrint('Image Path: ${_foodImage?.path}');
        });
      } else {
        // Display an error message or handle non-.jpg images as needed
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Donation Form'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: foodNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Food Name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Amount',
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Select category
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  width: 500,
                  child: DropdownButtonHideUnderline(
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
            // Select expiry date and time
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Textbox to display the expiry date and time
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller:
                          TextEditingController(text: _expiryController),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Expiry Date and Time',
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Show date picker
                      showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 14)),
                      ).then((selectedDate) {
                        if (selectedDate != null) {
                          showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          ).then((selectedTime) {
                            if (selectedTime != null) {
                              // Combine date and time
                              var dateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                              // Format date and time
                              var formattedDateTime =
                                  DateFormat('dd/MM/yyyy hh:mm a')
                                      .format(dateTime)
                                      .toString();
                              // Update the expiry date and time
                              setState(() {
                                _expiryController = formattedDateTime;
                              });
                            }
                          });
                        }
                      });
                    },
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
            // Add a button to pick an image
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Pick Image'),
                  ),
                  // If an image has been picked, display the image in 150x150
                  if (_foodImage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        _foodImage!,
                        width: 150,
                        height: 150,
                      ),
                    ),
                ],
              ),
            ),
            // Add a button to submit the form
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  // Get the values from the text fields and add to a donation object
                  var donation = Donation(
                    foodName: foodNameController.text,
                    category: dropdownValue,
                    amount: int.parse(amountController.text),
                    time: _expiryController,
                    image: _foodImage,
                  );
                  // Add the donation object to the app state
                  widget.appState.listDonation(donation);
                  // Navigate back to the donation page
                  Navigator.pop(context);
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Donation {
  final String foodName;
  final String category;
  final int amount;
  final String time;
  final File? image;

  Donation({
    required this.foodName,
    required this.category,
    required this.amount,
    required this.time,
    required this.image,
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
                    child: Image.file(
                      donation.image!,
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
