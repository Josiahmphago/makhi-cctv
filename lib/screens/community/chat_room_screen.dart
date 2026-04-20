import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatRoomScreen extends StatefulWidget {
  final String communityId;
  final String roomId; // e.g. "general" or "alerts"
  final String roomTitle;

  const ChatRoomScreen({
    super.key,
    required this.communityId,
    required this.roomId,
    required this.roomTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _fs = FirebaseFirestore.instance;
  final _st = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  final _ctrl = TextEditingController();
  bool _sending = false;

  Future<void> _send({File? image}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if ((_ctrl.text.trim().isEmpty) && image == null) return;

    setState(() => _sending = true);
    try {
      String? imageUrl;
      if (image != null) {
        final id = _fs.collection('tmp').doc().id;
        final ref = _st.ref('chat_images/${widget.communityId}/${widget.roomId}/$id.jpg');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }

      await _fs
          .collection('communities')
          .doc(widget.communityId)
          .collection('chat_rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
        'text': _ctrl.text.trim().isEmpty ? null : _ctrl.text.trim(),
        'imageUrl': imageUrl,
        'senderId': user.uid,
        'senderDisplay': user.displayName ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'chat',
        'communityId': widget.communityId,
        'roomId': widget.roomId,
      });

      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (x != null) await _send(image: File(x.path));
  }

  @override
  Widget build(BuildContext context) {
    final q = _fs
        .collection('communities')
        .doc(widget.communityId)
        .collection('chat_rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100);

    return Scaffold(
      appBar: AppBar(title: Text(widget.roomTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q.snapshots(),
              builder: (c, s) {
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                final docs = s.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final text = d['text'] as String?;
                    final imageUrl = d['imageUrl'] as String?;
                    final sender = d['senderDisplay'] ?? 'User';
                    final ts = (d['createdAt'] as Timestamp?)?.toDate();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(sender, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (text != null) Text(text),
                          if (imageUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(imageUrl, height: 180, fit: BoxFit.cover),
                              ),
                            ),
                          if (ts != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                ts.toLocal().toString(),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.photo_camera),
                    onPressed: _sending ? null : _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
