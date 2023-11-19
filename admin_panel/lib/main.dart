import 'package:flutter/material.dart';

void main() {
  runApp(const AdminPanelApp());
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
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
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
                          : const Text('Settings'),
            )
          ],
        ),
      ),
    );
  }
}

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

class OrgFormView extends StatefulWidget {
  const OrgFormView({Key? key}) : super(key: key);

  @override
  State<OrgFormView> createState() => _OrgFormViewState();
}

class _OrgFormViewState extends State<OrgFormView> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<OrganizationForm> orgFormList = [
      const OrganizationForm(
        name: 'Organization 1',
        leader: 'Leader 1',
        email: 'Email 1',
        phone: 'Phone 1',
        address: 'Address 1',
        noOfMembers: 1,
        reason: 'Reason 1',
        communities: ['Community 1'],
      ),
      const OrganizationForm(
        name: 'Organization 2',
        leader: 'Leader 2',
        email: 'Email 2',
        phone: 'Phone 2',
        address: 'Address 2',
        noOfMembers: 2,
        reason: 'Reason 2',
        communities: ['Community 2'],
      ),
      const OrganizationForm(
        name: 'Organization 3',
        leader: 'Leader 3',
        email: 'Email 3',
        phone: 'Phone 3',
        address: 'Address 3',
        noOfMembers: 3,
        reason: 'Reason 3',
        communities: ['Community 3'],
      ),
    ];

    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ListView(
            children: [
              for (var orgForm in orgFormList) ...[
                ListTile(
                  title: Text(orgForm.name),
                  subtitle: Text(orgForm.email),
                  onTap: () {
                    setState(() {
                      _selectedIndex = orgFormList.indexOf(orgForm);
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
                Text('Communities: ${orgFormList[_selectedIndex].communities}'),
                const SizedBox(height: 8),
                Text('Reason: ${orgFormList[_selectedIndex].reason}'),
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
                      // TODO: Handle removal
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
                      // TODO: Handle removal
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

class DonFormView extends StatefulWidget {
  const DonFormView({Key? key}) : super(key: key);

  @override
  _DonFormView createState() => _DonFormView();
}

class _DonFormView extends State<DonFormView> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<DonorForm> donFormList = [
      const DonorForm(
        name: 'Donor 1',
        email: 'Email 1',
        phone: 'Phone 1',
        address: 'Address 1',
        reason: 'Reason 1',
        communities: ['Community 1'],
        timePeriods: ['Time Period 1'],
      ),
      const DonorForm(
        name: 'Donor 2',
        email: 'Email 2',
        phone: 'Phone 2',
        address: 'Address 2',
        reason: 'Reason 2',
        communities: ['Community 2'],
        timePeriods: ['Time Period 2'],
      ),
      const DonorForm(
        name: 'Donor 3',
        email: 'Email 3',
        phone: 'Phone 3',
        address: 'Address 3',
        reason: 'Reason 3',
        communities: ['Community 3'],
        timePeriods: ['Time Period 3'],
      ),
    ];

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
                      _selectedIndex = donFormList.indexOf(orgForm);
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
                      // TODO: Handle removal
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
                      // TODO: Handle removal
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

class MemFormView extends StatefulWidget {
  const MemFormView({Key? key}) : super(key: key);

  @override
  State<MemFormView> createState() => _MemFormView();
}

class _MemFormView extends State<MemFormView> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    List<MemberForm> memFormList = [
      const MemberForm(
          name: 'Member 1',
          email: 'Email 1',
          phone: 'Phone 1',
          address: 'Address 1',
          age: 24,
          gender: 'Male'),
      const MemberForm(
          name: 'Member 2',
          email: 'Email 2',
          phone: 'Phone 1',
          address: 'Address 1',
          age: 24,
          gender: 'Male'),
      const MemberForm(
          name: 'Member 2',
          email: 'Email 2',
          phone: 'Phone 1',
          address: 'Address 1',
          age: 24,
          gender: 'Male'),
    ];

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
                      _selectedIndex = memFormList.indexOf(memForm);
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
                      // TODO: Handle removal
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
                      // TODO: Handle removal
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
    required this.communities,
    required this.timePeriods,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String reason;
  final List<String> communities;
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
  @override
  Widget build(BuildContext context) {
    List<Rejection> rejectionList = [
      Rejection(
        donName: 'Donor 1',
        orgName: 'Organization 1',
        memName: 'Member 1',
        donId: 1,
        orgId: 1,
        memId: 1,
        reason: 'Reason 1',
        date: DateTime(2021, 10, 10),
      ),
      Rejection(
        donName: 'Donor 2',
        orgName: 'Organization 2',
        memName: 'Member 2',
        donId: 2,
        orgId: 2,
        memId: 2,
        reason: 'Reason 2',
        date: DateTime(2021, 10, 10),
      ),
      Rejection(
        donName: 'Donor 3',
        orgName: 'Organization 3',
        memName: 'Member 3',
        donId: 3,
        orgId: 3,
        memId: 3,
        reason: 'Reason 3',
        date: DateTime(2021, 10, 10),
      ),
    ];

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
                    // TODO: Show some actions
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
  @override
  Widget build(BuildContext context) {
    List<NeededAction> actionList = [
      const NeededAction(
        id: '1',
        name: 'Action 1',
        type: 'Organization',
        concern: 'Concern 1',
      ),
      const NeededAction(
        id: '2',
        name: 'Action 1',
        type: 'Donor',
        concern: 'Concern 1',
      ),
      const NeededAction(
        id: '3',
        name: 'Action 1',
        type: 'Member',
        concern: 'Concern 1',
      ),
    ];

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
                      _selectedIndex = actionList.indexOf(action);
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
                Text('ID: ${actionList[_selectedIndex].id}'),
                const SizedBox(height: 8),
                Text('Name: ${actionList[_selectedIndex].name}'),
                const SizedBox(height: 8),
                Text('Type: ${actionList[_selectedIndex].type}'),
                const SizedBox(height: 8),
                Text('Concern: ${actionList[_selectedIndex].concern}'),
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
                    // TODO: Show some actions
                  },
                  child: const Text('Ban')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    // TODO: Show some actions
                  },
                  child: const Text('Suspend')),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () {
                    // TODO: Show some actions
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
