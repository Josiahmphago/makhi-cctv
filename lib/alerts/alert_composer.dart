import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../location/geohash.dart';
import '../location/location_service.dart';
import 'alert_sender_service.dart';

class AlertComposer extends StatefulWidget {
  const AlertComposer({super.key});

  @override
  State<AlertComposer> createState() => _AlertComposerState();
}

class _AlertComposerState extends State<AlertComposer> {
  final TextEditingController _messageController = TextEditingController();

  final List<File> _selectedImages = [];
  final List<Contact> _selectedContacts = [];

  bool _loading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ==========================================================
  // CONTACT PICKER
  // ==========================================================
  Future<void> _pickContacts() async {
    final granted =
        await FlutterContacts.requestPermission(readonly: true);
    if (!granted || !mounted) return;

    final contacts =
        await FlutterContacts.getContacts(withProperties: true);

    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = contacts.where((c) {
              final name = c.displayName.toLowerCase();
              return name.contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Contacts'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search contact...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          if (c.phones.isEmpty) {
                            return const SizedBox();
                          }

                          final selected =
                              _selectedContacts.contains(c);

                          return CheckboxListTile(
                            title: Text(
                              c.displayName.isEmpty
                                  ? '(No name)'
                                  : c.displayName,
                            ),
                            subtitle:
                                Text(c.phones.first.number),
                            value: selected,
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v == true) {
                                  _selectedContacts.add(c);
                                } else {
                                  _selectedContacts.remove(c);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  child: const Text('Done'),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // SEND ALERT
  // ==========================================================
  Future<void> _sendAlert() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one contact'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not authenticated");
      }

      final pos = await LocationService.current();
      final lat = pos?.latitude;
      final lng = pos?.longitude;

      final msg = _messageController.text.trim().isEmpty
          ? 'Emergency alert!'
          : _messageController.text.trim();

      final alertData = {
        'message': msg,
        'type': 'Emergency',
        'senderId': user.uid,
        'senderName':
            user.displayName ?? 'Community Member',
        'createdAt': FieldValue.serverTimestamp(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (lat != null && lng != null)
          'geohash':
              GeoHash.encode(lat, lng, precision: 7),
      };

      await FirebaseFirestore.instance
          .collection('alerts')
          .add(alertData);

      await AlertSenderService.sendAlert(
        context: context,
        contacts: _selectedContacts,
        imageFiles: _selectedImages,
        message: msg,
        alertType: 'Emergency',
        method: 'All',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent successfully'),
        ),
      );

      setState(() {
        _selectedContacts.clear();
        _messageController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Alert'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _messageController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Optional message',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.contacts),
            label: Text(
                'Select Contacts (${_selectedContacts.length})'),
            onPressed:
                _loading ? null : _pickContacts,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('SEND PANIC ALERT'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed:
                _loading ? null : _sendAlert,
          ),
        ],
      ),
    );
  }
}