import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_group.dart';
import 'alert_recipient_directory.dart';

class AlertGroupService {
  final _col = FirebaseFirestore.instance.collection('alert_groups');

  Stream<List<AlertGroup>> streamGroups() {
    return _col.orderBy('priority', descending: false).snapshots().map((snap) {
      return snap.docs.map((d) => AlertGroup.fromMap(d.id, d.data())).toList();
    });
  }

  Future<List<AlertGroup>> fetchOnce() async {
    final snap = await _col.orderBy('priority', descending: false).get();
    return snap.docs.map((d) => AlertGroup.fromMap(d.id, d.data())).toList();
  }

  Future<void> upsertGroup(AlertGroup g) async {
    await _col.doc(g.id).set(g.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteGroup(String id) => _col.doc(id).delete();
}

extension AlertGroupImport on AlertGroupService {
  Future<int> importLegacyOnce() async {
    final dir = AlertRecipientDirectory();
    final legacy = await dir.fetchOnce();
    int written = 0;
    for (final g in legacy) {
      await upsertGroup(g.copyWith(priority: g.priority ?? 99));
      written++;
    }
    return written;
  }
}
