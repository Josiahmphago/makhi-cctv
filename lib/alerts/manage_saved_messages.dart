import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageSavedMessagesScreen extends StatefulWidget {
  const ManageSavedMessagesScreen({super.key});

  @override
  State<ManageSavedMessagesScreen> createState() => _ManageSavedMessagesScreenState();
}

class _ManageSavedMessagesScreenState extends State<ManageSavedMessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _editingMessageId;

  CollectionReference get _messagesRef => FirebaseFirestore.instance.collection('saved_messages');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _saveMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageData = {
      'text': text,
      'ownerId': _uid,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_editingMessageId != null) {
      await _messagesRef.doc(_editingMessageId).update(messageData);
    } else {
      await _messagesRef.add(messageData);
    }

    _messageController.clear();
    setState(() {
      _editingMessageId = null;
    });
  }

  void _editMessage(String id, String text) {
    setState(() {
      _editingMessageId = id;
      _messageController.text = text;
    });
  }

  Future<void> _deleteMessage(String id) async {
    await _messagesRef.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Emergency Messages'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter your emergency message',
                suffixIcon: IconButton(
                  icon: Icon(_editingMessageId == null ? Icons.save : Icons.check),
                  onPressed: _saveMessage,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Your Messages', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _messagesRef
                    .where('ownerId', isEqualTo: _uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('Error loading messages.');
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return const Text('No messages saved yet.');
                  }

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final doc = messages[index];
                      final text = doc['text'] ?? '';
                      return ListTile(
                        title: Text(text),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editMessage(doc.id, text),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteMessage(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
