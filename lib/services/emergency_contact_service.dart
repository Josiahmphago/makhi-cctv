import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_contact.dart';

class EmergencyContactService {
  final _firestore = FirebaseFirestore.instance;

  /// Stream contacts for a given owner
  Stream<List<EmergencyContact>> getContacts(String ownerId) {
    return _firestore
        .collection('emergency_contacts')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EmergencyContact.fromMap(doc.data(), doc.id)).toList());
  }

  /// Add a new contact
  Future<void> addContact(EmergencyContact contact, String ownerId) async {
    await _firestore.collection('emergency_contacts').add({
      ...contact.toMap(),
      'ownerId': ownerId,
    });
  }

  /// Update a contact
  Future<void> updateContact(EmergencyContact contact, String contactId, String ownerId) async {
    await _firestore
        .collection('emergency_contacts')
        .doc(contactId)
        .set({
          ...contact.toMap(),
          'ownerId': ownerId,
        }, SetOptions(merge: true));
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId, String ownerId) async {
    await _firestore.collection('emergency_contacts').doc(contactId).delete();
  }
}
