// lib/pages/home/contacts.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/avatars.dart';
import '../../data/models/contact.dart';
import '../../data/repo/users.dart';

class ContactsListWidget extends StatefulWidget {
  const ContactsListWidget({super.key});

  @override
  State<ContactsListWidget> createState() => _ContactsListWidgetState();
}

class _ContactsListWidgetState extends State<ContactsListWidget> {
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final loadedContacts = await UsersRepository.getAllContacts();
    if (mounted) {
      setState(() {
        _contacts = loadedContacts;
      });
    }
  }

  void _onContactSelected(Contact contact) {
    debugPrint('Selected contact: ${contact.name}');
    Navigator.of(context).pop(contact);
  }

  Widget _buildContactCard(Contact contact, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.onSurfaceVariant.withAlpha(18),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AvatarWidget(imagePath: contact.imagePath, size: 45, text: 'ai'),
        title: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            contact.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            contact.subtitle,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ),
        onTap: () => _onContactSelected(contact),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                return _buildContactCard(_contacts[index], colorScheme);
              },
            ),
          ),
        ],
      ),
    );
  }
}

