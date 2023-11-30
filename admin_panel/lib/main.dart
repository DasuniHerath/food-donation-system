import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io' as io;

void main() {
  runApp(const AdminPanelApp());
}

// Database Helper for the admin panel
class DBHelper {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDatabase();
    return _db!;
  }

  initDatabase() async {
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, 'forms.db');
    var db = await openDatabase(path, version: 1);
    return db;
  }

  // Get org forms
  Future<List<Map>> getOrgForms() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM orgforms');
    return list;
  }

  // Get don forms
  Future<List<Map>> getDonForms() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM donForms');
    return list;
  }

  // Get member forms
  Future<List<Map>> getMemberForms() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM memberForms');
    return list;
  }

  // Get rejections
  Future<List<Map>> getRejections() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM rejections');
    return list;
  }

  // Get actions
  Future<List<Map>> getActions() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM actions');
    return list;
  }

  // Delete org form
  Future<int> deleteOrgForm(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'orgForms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete don form
  Future<int> deleteDonForm(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'donForms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete member form
  Future<int> deleteMemberForm(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'memberForms',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete rejection
  Future<int> deleteRejection(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'rejections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete action
  Future<int> deleteAction(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class AdminPanelApp extends StatelessWidget {
  const AdminPanelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const AdminPanel(),
    );
  }
}

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  int _selectedIndex = 0; // The index of the selected tab
  NavigationRailLabelType labelType = NavigationRailLabelType.all; // Label type
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              groupAlignment: groupAlignment,
              onDestinationSelected: (int index) {
                setState(() {
                  // If the list is not empty, then show no forms
                  _selectedIndex = index;
                });
              },
              labelType: labelType,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Badge(
                      isLabelVisible: false,
                      child: Icon(Icons.description_outlined)),
                  selectedIcon: Badge(
                      isLabelVisible: false, child: Icon(Icons.description)),
                  label: Text('Applicants'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: false,
                    child: Icon(Icons.cancel_outlined),
                  ),
                  selectedIcon:
                      Badge(isLabelVisible: false, child: Icon(Icons.cancel)),
                  label: Text('Rejections'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    label: Text('4'),
                    isLabelVisible: false,
                    child: Icon(Icons.report_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: false,
                    label: Text('4'),
                    child: Icon(Icons.report),
                  ),
                  label: Text('Actions'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: false,
                    child: Icon(Icons.settings_outlined),
                  ),
                  selectedIcon:
                      Badge(isLabelVisible: false, child: Icon(Icons.settings)),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // This is the main content
            Expanded(
              child: _selectedIndex == 0
                  ? const ApplicantTabBar()
                  : _selectedIndex == 1
                      ? const RejectionView()
                      : _selectedIndex == 2
                          ? const ActionView()
                          : const SettingsView(),
            )
          ],
        ),
      ),
    );
  }
}

// Applications from three parties
class ApplicantTabBar extends StatefulWidget {
  const ApplicantTabBar({Key? key}) : super(key: key);

  @override
  ApplicantTabBarState createState() => ApplicantTabBarState();
}

class ApplicantTabBarState extends State<ApplicantTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 3);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
                icon: Icon(Icons.corporate_fare_outlined),
                text: 'Organizations'),
            Tab(icon: Icon(Icons.favorite_border_outlined), text: 'Donors'),
            Tab(icon: Icon(Icons.people_outline_outlined), text: 'Members'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              OrgFormView(),
              DonFormView(),
              MemFormView(),
            ],
          ),
        ),
      ],
    );
  }
}

// Applications from organizations
class OrgFormView extends StatefulWidget {
  const OrgFormView({Key? key}) : super(key: key);

  @override
  State<OrgFormView> createState() => _OrgFormViewState();
}

class _OrgFormViewState extends State<OrgFormView> {
  int _selectedIndex = 0;
  List<OrganizationForm> orgFormList = [];

  // Populate the list with db data
  void populateList() async {
    var db = DBHelper();
    List<Map> list = await db.getOrgForms();
    for (var item in list) {
      setState(() {
        orgFormList.add(OrganizationForm(
            name: item['name'],
            leader: item['leader'],
            email: item['email'],
            phone: item['phone'],
            address: item['address'],
            noOfMembers: item['noOfMembers'],
            reason: item['reason'],
            communities: item['communities']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var orgForm in orgFormList) ...[
                // Show the list of forms
                ListTile(
                  title: Text(orgForm.name),
                  subtitle: Text(orgForm.email),
                  onTap: () {
                    setState(() {
                      // If the list is not empty, then show no forms
                      if (orgFormList.isNotEmpty) {
                        _selectedIndex = orgFormList.indexOf(orgForm);
                      } else {
                        _selectedIndex = -1;
                      }
                    });
                  },
                ),
                const Divider(thickness: 1, height: 1),
              ]
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orgFormList.isEmpty)
                  const Text('No Forms')
                else ...[
                  Text('Name: ${orgFormList[_selectedIndex].name}'),
                  const SizedBox(height: 8),
                  Text('Leader: ${orgFormList[_selectedIndex].leader}'),
                  const SizedBox(height: 8),
                  Text('Email: ${orgFormList[_selectedIndex].email}'),
                  const SizedBox(height: 8),
                  Text('Phone: ${orgFormList[_selectedIndex].phone}'),
                  const SizedBox(height: 8),
                  Text('Address: ${orgFormList[_selectedIndex].address}'),
                  const SizedBox(height: 8),
                  Text(
                      'No. of Members: ${orgFormList[_selectedIndex].noOfMembers}'),
                  const SizedBox(height: 8),
                  Text(
                      'Communities: ${orgFormList[_selectedIndex].communities}'),
                  const SizedBox(height: 8),
                  Text('Reason: ${orgFormList[_selectedIndex].reason}'),
                ]
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Handle removal
                      orgFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteOrgForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Organization Approved'),
                      ),
                    );
                  },
                  child: const Text('Approve')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      orgFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteOrgForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Organization Rejected'),
                      ),
                    );
                  },
                  child: const Text('Reject'))
            ],
          ),
        ),
      ],
    );
  }
}

// Applications from donors
class DonFormView extends StatefulWidget {
  const DonFormView({Key? key}) : super(key: key);

  @override
  createState() => _DonFormView();
}

class _DonFormView extends State<DonFormView> {
  int _selectedIndex = 0;
  List<DonorForm> donFormList = [];

  // Populate the list with db data
  void populateList() async {
    var db = DBHelper();
    List<Map> list = await db.getDonForms();
    for (var item in list) {
      setState(() {
        donFormList.add(DonorForm(
            name: item['name'],
            email: item['email'],
            phone: item['phone'],
            address: item['address'],
            reason: item['reason'],
            timePeriods: item['timePeriods']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var orgForm in donFormList) ...[
                ListTile(
                  title: Text(orgForm.name),
                  subtitle: Text(orgForm.email),
                  onTap: () {
                    setState(() {
                      if (donFormList.isNotEmpty) {
                        _selectedIndex = donFormList.indexOf(orgForm);
                      } else {
                        _selectedIndex = -1;
                      }
                    });
                  },
                ),
                const Divider(thickness: 1, height: 1),
              ]
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (donFormList.isEmpty)
                  const Text('No Forms')
                else ...[
                  Text('Name: ${donFormList[_selectedIndex].name}'),
                  const SizedBox(height: 8),
                  Text('Email: ${donFormList[_selectedIndex].email}'),
                  const SizedBox(height: 8),
                  Text('Phone: ${donFormList[_selectedIndex].phone}'),
                  const SizedBox(height: 8),
                  Text('Address: ${donFormList[_selectedIndex].address}'),
                  const SizedBox(height: 8),
                  Text(
                      'Time Periods: ${donFormList[_selectedIndex].timePeriods}'),
                  const SizedBox(height: 8),
                  Text(
                      'Reason for joining: ${donFormList[_selectedIndex].reason}'),
                ]
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      donFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteDonForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Donor Approved'),
                      ),
                    );
                  },
                  child: const Text('Approve')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      donFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteDonForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Donor Rejected'),
                      ),
                    );
                  },
                  child: const Text('Reject'))
            ],
          ),
        ),
      ],
    );
  }
}

// List of member application
class MemFormView extends StatefulWidget {
  const MemFormView({Key? key}) : super(key: key);

  @override
  State<MemFormView> createState() => _MemFormView();
}

class _MemFormView extends State<MemFormView> {
  int _selectedIndex = 0;
  List<MemberForm> memFormList = [];

  // Populate the list with db data
  void populateList() async {
    var db = DBHelper();
    List<Map> list = await db.getMemberForms();
    for (var item in list) {
      setState(() {
        memFormList.add(MemberForm(
            name: item['name'],
            email: item['email'],
            phone: item['phone'],
            address: item['address'],
            age: item['age'],
            gender: item['gender']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var memForm in memFormList) ...[
                ListTile(
                  title: Text(memForm.name),
                  subtitle: Text(memForm.email),
                  onTap: () {
                    setState(() {
                      if (memFormList.isNotEmpty) {
                        _selectedIndex = memFormList.indexOf(memForm);
                      } else {
                        _selectedIndex = -1;
                      }
                    });
                  },
                ),
                const Divider(thickness: 1, height: 1),
              ]
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (memFormList.isEmpty)
                const Text('No Forms')
              else ...[
                Text('Name: ${memFormList[_selectedIndex].name}'),
                const SizedBox(height: 8),
                Text('Email: ${memFormList[_selectedIndex].email}'),
                const SizedBox(height: 8),
                Text('Phone: ${memFormList[_selectedIndex].phone}'),
                const SizedBox(height: 8),
                Text('Address: ${memFormList[_selectedIndex].address}'),
                const SizedBox(height: 8),
                Text('Age: ${memFormList[_selectedIndex].age}'),
                const SizedBox(height: 8),
                Text('Gender: ${memFormList[_selectedIndex].gender}'),
              ]
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      memFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteMemberForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Organization Approved'),
                      ),
                    );
                  },
                  child: const Text('Approve')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      memFormList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteMemberForm(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Organization Rejected'),
                      ),
                    );
                  },
                  child: const Text('Reject'))
            ],
          ),
        ),
      ],
    );
  }
}

class OrganizationForm {
  const OrganizationForm({
    required this.name,
    required this.leader,
    required this.email,
    required this.phone,
    required this.address,
    required this.noOfMembers,
    required this.reason,
    required this.communities,
  });

  final String name;
  final String leader;
  final String email;
  final String phone;
  final String address;
  final int noOfMembers;
  final String reason;
  final List<String> communities;
}

class DonorForm {
  const DonorForm({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.reason,
    required this.timePeriods,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String reason;
  final List<String> timePeriods;
}

class MemberForm {
  const MemberForm(
      {required this.name,
      required this.email,
      required this.phone,
      required this.address,
      required this.age,
      required this.gender});

  final String name;
  final String email;
  final String phone;
  final String address;
  final int age;
  final String gender;
}

class RejectionView extends StatefulWidget {
  const RejectionView({Key? key}) : super(key: key);

  @override
  State<RejectionView> createState() => _RejectionViewState();
}

class _RejectionViewState extends State<RejectionView> {
  int _selectedIndex = 0;
  List<Rejection> rejectionList = [];

  // Populate the list with db data
  void populateList() async {
    var db = DBHelper();
    List<Map> list = await db.getRejections();
    for (var item in list) {
      setState(() {
        rejectionList.add(Rejection(
            donName: item['donName'],
            orgName: item['orgName'],
            memName: item['memName'],
            donId: item['donId'],
            orgId: item['orgId'],
            memId: item['memId'],
            reason: item['reason'],
            date: item['date']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var rejection in rejectionList) ...[
                ListTile(
                  title: Text(rejection.donName),
                  subtitle: Text(rejection.reason),
                  onTap: () {
                    setState(() {
                      _selectedIndex = rejectionList.indexOf(rejection);
                    });
                  },
                ),
                const Divider(thickness: 1, height: 1),
              ]
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rejectionList.isEmpty)
                  const Text('No Rejections')
                else ...[
                  Text('Donor Name: ${rejectionList[_selectedIndex].donName}'),
                  const SizedBox(height: 8),
                  Text(
                      'Organization Name: ${rejectionList[_selectedIndex].orgName}'),
                  const SizedBox(height: 8),
                  Text('Member Name: ${rejectionList[_selectedIndex].memName}'),
                  const SizedBox(height: 8),
                  Text('Reason: ${rejectionList[_selectedIndex].reason}'),
                  const SizedBox(height: 8),
                  Text('Date: ${rejectionList[_selectedIndex].date}'),
                ]
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    // Show a diolog with options
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Actions'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      rejectionList.removeAt(_selectedIndex);
                                      // Remove from db
                                      var db = DBHelper();
                                      db.deleteRejection(_selectedIndex);
                                      _selectedIndex = 0;
                                    });
                                    // Show A SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Donor Banned'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Ban')),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      rejectionList.removeAt(_selectedIndex);
                                      // Remove from db
                                      var db = DBHelper();
                                      db.deleteRejection(_selectedIndex);
                                      _selectedIndex = 0;
                                    });
                                    // Show A SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Donor Suspended'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Suspend')),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      rejectionList.removeAt(_selectedIndex);
                                      // Remove from db
                                      var db = DBHelper();
                                      db.deleteRejection(_selectedIndex);
                                      _selectedIndex = 0;
                                    });
                                    // Show A SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Action Ignored'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Ignore'))
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Text('Actions'))
            ],
          ),
        ),
      ],
    );
  }
}

class Rejection {
  const Rejection({
    required this.donName,
    required this.orgName,
    required this.memName,
    required this.donId,
    required this.orgId,
    required this.memId,
    required this.reason,
    required this.date,
  });

  final String donName;
  final String orgName;
  final String memName;
  final int donId;
  final int orgId;
  final int memId;
  final String reason;
  final DateTime date;
}

class ActionView extends StatefulWidget {
  const ActionView({Key? key}) : super(key: key);

  @override
  State<ActionView> createState() => _ActionView();
}

class _ActionView extends State<ActionView> {
  int _selectedIndex = 0;
  List<NeededAction> actionList = [];

  // Populate the list with db data
  void populateList() async {
    var db = DBHelper();
    List<Map> list = await db.getActions();
    for (var item in list) {
      setState(() {
        actionList.add(NeededAction(
            id: item['id'],
            name: item['name'],
            type: item['type'],
            concern: item['concern']));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var action in actionList) ...[
                ListTile(
                  title: Text(action.name),
                  subtitle: Text(action.type),
                  onTap: () {
                    setState(() {
                      if (actionList.isNotEmpty) {
                        _selectedIndex = actionList.indexOf(action);
                      } else {
                        _selectedIndex = -1;
                      }
                    });
                  },
                ),
                const Divider(thickness: 1, height: 1),
              ]
            ],
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (actionList.isEmpty)
                  const Text('No Actions')
                else ...[
                  Text('ID: ${actionList[_selectedIndex].id}'),
                  const SizedBox(height: 8),
                  Text('Name: ${actionList[_selectedIndex].name}'),
                  const SizedBox(height: 8),
                  Text('Type: ${actionList[_selectedIndex].type}'),
                  const SizedBox(height: 8),
                  Text('Concern: ${actionList[_selectedIndex].concern}'),
                ]
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      actionList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteAction(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account Banned'),
                      ),
                    );
                  },
                  child: const Text('Ban')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      actionList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteAction(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account Suspended'),
                      ),
                    );
                  },
                  child: const Text('Suspend')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      actionList.removeAt(_selectedIndex);
                      // Remove from db
                      var db = DBHelper();
                      db.deleteAction(_selectedIndex);
                      _selectedIndex = 0;
                    });
                    // Show A SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Action Ignored'),
                      ),
                    );
                  },
                  child: const Text('Ignore'))
            ],
          ),
        ),
      ],
    );
  }
}

class NeededAction {
  const NeededAction({
    required this.id,
    required this.name,
    required this.type,
    required this.concern,
  });

  final String id;
  final String name;
  final String type;
  final String concern;
}

// A settings menu that has options such as logout and theme
class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsView();
}

class _SettingsView extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Settings'),
        ElevatedButton(onPressed: () {}, child: const Text('Logout'))
      ],
    );
  }
}
