import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/emergency_contact_service.dart';
import '../services/alert_sender_service.dart';
import 'manage_emergency_contacts.dart';

class SendAlertScreen extends StatefulWidget {
  const SendAlertScreen({super.key});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final AlertSenderService _sender = AlertSenderService();

  final TextEditingController _messageCtrl =
      TextEditingController(text: 'Emergency! Please help!');
  bool _includeLocation = true;

  // TODO: replace with FirebaseAuth.instance.currentUser!.uid
  final String _ownerId = 'demoOwner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Alert'),
        actions: [
          IconButton(
            tooltip: 'Manage Contacts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ManageEmergencyContactsScreen(ownerId: _ownerId),
                ),
              );
            },
            icon: const Icon(Icons.contacts),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compose',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your alert message…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: _includeLocation,
                        onChanged: (v) => setState(() => _includeLocation = v),
                      ),
                      const Text('Include location')
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<EmergencyContact>>(
                stream: _contactService.getContacts(_ownerId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contacts = snapshot.data!;
                  if (contacts.isEmpty) {
                    return const Center(
                      child: Text('No emergency contacts yet.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = contacts[i];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.phoneNumber),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.send),
                          onSelected: (method) async {
                            final composed = await _sender.composeMessage(
                              baseMessage: _messageCtrl.text,
                              includeLocation: _includeLocation,
                            );
                            bool ok = false;
                            if (method == 'SMS') {
                              ok = await _sender.sendSms(c.phoneNumber, composed);
                            } else if (method == 'WhatsApp') {
                              ok = await _sender.sendWhatsApp(c.phoneNumber, composed);
                            } else if (method == 'Telegram') {
                              ok = await _sender.sendTelegramBot(composed);
                              if (!ok) {
                                ok = await _sender.sendTelegramShare(composed);
                              }
                            }

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Opening $method…'
                                    : '$method failed or not available'),
                              ),
                            );
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'SMS', child: Text('Send via SMS')),
                            PopupMenuItem(
                                value: 'WhatsApp',
                                child: Text('Send via WhatsApp')),
                            PopupMenuItem(
                                value: 'Telegram',
                                child: Text('Send via Telegram')),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
