import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final int initialTab;

  const EmergencyContactsScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: "Emergency Services"),
            Tab(text: "Personal Contacts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EmergencyServicesTab(onCall: _makePhoneCall),
          _PersonalContactsTab(onCall: _makePhoneCall),
        ],
      ),
    );
  }
}

class _EmergencyServicesTab extends StatelessWidget {
  final Function(String) onCall;

  const _EmergencyServicesTab({required this.onCall});

  @override
  Widget build(BuildContext context) {
    final emergencyServices = [
      EmergencyService(
        name: "Police Emergency",
        number: "10111",
        icon: Icons.local_police,
        color: const Color(0xFF1976D2),
        location: "National",
        availability: "24/7",
      ),
      EmergencyService(
        name: "Emergency Services",
        number: "999",
        icon: Icons.emergency,
        color: const Color(0xFFD32F2F),
        location: "National",
        availability: "24/7",
      ),
      EmergencyService(
        name: "Emergency Services",
        number: "112",
        icon: Icons.emergency,
        color: const Color(0xFFD32F2F),
        location: "National",
        availability: "24/7",
      ),
      EmergencyService(
        name: "Windhoek Police",
        number: "061 10 111",
        icon: Icons.local_police,
        color: const Color(0xFF1976D2),
        location: "Windhoek, Khomas",
        availability: "24/7",
      ),
      EmergencyService(
        name: "Windhoek Emergency Medical",
        number: "061 21 111",
        icon: Icons.local_hospital,
        color: const Color(0xFF388E3C),
        location: "Windhoek, Khomas",
        availability: "24/7",
      ),
      EmergencyService(
        name: "Windhoek Fire Department",
        number: "061 21 111",
        icon: Icons.local_fire_department,
        color: const Color(0xFFF57C00),
        location: "Windhoek, Khomas",
        availability: "24/7",
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencyServices.length,
      itemBuilder: (context, index) {
        final service = emergencyServices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EmergencyServiceCard(
            service: service,
            onCall: () => onCall(service.number),
          ),
        );
      },
    );
  }
}

class _PersonalContactsTab extends StatefulWidget {
  final Function(String) onCall;

  const _PersonalContactsTab({required this.onCall});

  @override
  State<_PersonalContactsTab> createState() => _PersonalContactsTabState();
}

class _PersonalContactsTabState extends State<_PersonalContactsTab> {
  final List<PersonalContact> _contacts = [
    PersonalContact(
      name: "John Doe",
      phone: "+264 81 123 4567",
      relationship: "Family",
      priority: 1,
    ),
    PersonalContact(
      name: "Mary Smith",
      phone: "+264 85 987 6543",
      relationship: "Friend",
      priority: 2,
    ),
  ];

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        onAdd: (contact) {
          setState(() {
            _contacts.add(contact);
          });
        },
      ),
    );
  }

  void _showEditContactDialog(int index) {
    final contact = _contacts[index];
    showDialog(
      context: context,
      builder: (context) => _EditContactDialog(
        contact: contact,
        onSave: (updatedContact) {
          setState(() {
            _contacts[index] = updatedContact;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _contacts.isEmpty
          ? _EmptyContactsView(onAdd: _showAddContactDialog)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PersonalContactCard(
                    contact: contact,
                    onCall: () => widget.onCall(contact.phone),
                    onEdit: () {
                      _showEditContactDialog(index);
                    },
                    onDelete: () {
                      setState(() {
                        _contacts.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContactDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EmergencyService {
  final String name;
  final String number;
  final IconData icon;
  final Color color;
  final String location;
  final String availability;

  EmergencyService({
    required this.name,
    required this.number,
    required this.icon,
    required this.color,
    required this.location,
    required this.availability,
  });
}

class PersonalContact {
  final String name;
  final String phone;
  final String relationship;
  final int priority;

  PersonalContact({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.priority,
  });
}

class EmergencyServiceCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onCall;

  const EmergencyServiceCard({
    super.key,
    required this.service,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                service.icon,
                color: service.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.number,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.availability,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.call, size: 18),
              label: const Text("Call"),
              style: FilledButton.styleFrom(
                backgroundColor: service.color,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalContactCard extends StatelessWidget {
  final PersonalContact contact;
  final VoidCallback onCall;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PersonalContactCard({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        contact.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(contact.priority)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Priority ${contact.priority}",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getPriorityColor(contact.priority),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact.phone,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.relationship,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: "Edit Contact",
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outlined),
                  tooltip: "Delete Contact",
                  iconSize: 20,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text("Call"),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFD32F2F);
      case 2:
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFF388E3C);
    }
  }
}

class _EmptyContactsView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyContactsView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              "No Personal Contacts",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your trusted contacts for emergency situations",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Add Contact"),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final Function(PersonalContact) onAdd;

  const _AddContactDialog({required this.onAdd});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _relationship = 'Family';
  int _priority = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add Emergency Contact"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Relationship",
                prefixIcon: Icon(Icons.family_restroom),
              ),
              initialValue: _relationship,
              items: ['Family', 'Friend', 'Colleague', 'Neighbor', 'Other']
                  .map((rel) => DropdownMenuItem(value: rel, child: Text(rel)))
                  .toList(),
              onChanged: (value) => setState(() => _relationship = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Priority Level",
                prefixIcon: Icon(Icons.priority_high),
              ),
              initialValue: _priority,
              items: [1, 2, 3, 4, 5]
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text("Priority $priority"),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final contact = PersonalContact(
                name: _nameController.text,
                phone: _phoneController.text,
                relationship: _relationship,
                priority: _priority,
              );
              widget.onAdd(contact);
              Navigator.pop(context);
            }
          },
          child: const Text("Add Contact"),
        ),
      ],
    );
  }
}

class _EditContactDialog extends StatefulWidget {
  final PersonalContact contact;
  final Function(PersonalContact) onSave;

  const _EditContactDialog({required this.contact, required this.onSave});

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _relationship;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _relationship = widget.contact.relationship;
    _priority = widget.contact.priority;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Emergency Contact"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Relationship",
                prefixIcon: Icon(Icons.family_restroom),
              ),
              initialValue: _relationship,
              items: ['Family', 'Friend', 'Colleague', 'Neighbor', 'Other']
                  .map((rel) => DropdownMenuItem(value: rel, child: Text(rel)))
                  .toList(),
              onChanged: (value) => setState(() => _relationship = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: "Priority Level",
                prefixIcon: Icon(Icons.priority_high),
              ),
              initialValue: _priority,
              items: [1, 2, 3, 4, 5]
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text("Priority $priority"),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final contact = PersonalContact(
                name: _nameController.text,
                phone: _phoneController.text,
                relationship: _relationship,
                priority: _priority,
              );
              widget.onSave(contact);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact updated successfully'),
                  backgroundColor: Color(0xFF388E3C),
                ),
              );
            }
          },
          child: const Text("Save Changes"),
        ),
      ],
    );
  }
}
