// lib/services/group_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Member leaves group
  /// - Removes ONLY that user
  /// - Deletes group ONLY if last member
  Future<void> leaveGroup(String groupId, String userId) async {
    final ref = _db.collection('groups').doc(groupId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final members = List<String>.from(data['memberIds'] ?? []);

      members.remove(userId);

      if (members.isEmpty) {
        tx.delete(ref);
      } else {
        tx.update(ref, {
          'memberIds': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Owner removes another member
  Future<void> removeMember({
    required String groupId,
    required String memberId,
    required String ownerId,
  }) async {
    final ref = _db.collection('groups').doc(groupId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final members = List<String>.from(data['memberIds'] ?? []);

      if (!members.contains(memberId)) return;

      members.remove(memberId);

      if (members.isEmpty) {
        tx.delete(ref);
      } else {
        tx.update(ref, {
          'memberIds': members,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
