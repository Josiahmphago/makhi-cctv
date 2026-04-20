import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert_group.dart';

class AlertRecipientDirectory {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Prevent log spam
  final Set<String> _warned = {};

  /// Live stream combining: alert_groups (if present) + legacy collections
  Stream<List<AlertGroup>> streamGroups() async* {
    final alertGroupsStream = _db
        .collection('alert_groups')
        .orderBy('priority', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AlertGroup.fromMap(d.id, d.data())).toList());

    await for (final base in alertGroupsStream) {
      final legacy = await _buildLegacyGroupsSafe();
      yield _mergeById(preferred: base, fallback: legacy);
    }
  }

  /// One-shot fetch
  Future<List<AlertGroup>> fetchOnce() async {
    final base = await _safeQuery(
      () async {
        final agSnap = await _db.collection('alert_groups').orderBy('priority', descending: false).get();
        return agSnap.docs.map((d) => AlertGroup.fromMap(d.id, d.data())).toList();
      },
      fallback: <AlertGroup>[],
      warnKey: 'alert_groups',
    );

    final legacy = await _buildLegacyGroupsSafe();
    return _mergeById(preferred: base, fallback: legacy);
  }

  // ---------------- internal helpers ----------------

  List<AlertGroup> _mergeById({
    required List<AlertGroup> preferred,
    required List<AlertGroup> fallback,
  }) {
    final map = {for (final g in fallback) g.id: g};
    for (final g in preferred) {
      map[g.id] = g;
    }

    // stable ordering: alert_groups first (already ordered by priority); then fallback alphabetical
    final preferredIds = preferred.map((g) => g.id).toSet();
    final rest = map.values.where((g) => !preferredIds.contains(g.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return [...preferred, ...rest];
  }

  Future<List<AlertGroup>> _buildLegacyGroupsSafe() async {
    return _safeQuery(
      () async => _buildLegacyGroups(),
      fallback: <AlertGroup>[
        // Always provide “placeholders” so UI isn’t empty even if Firestore denies reads
        AlertGroup(id: 'police', name: 'Police', numbers: const [], emoji: '🚔', priority: 1, teams: const []),
        AlertGroup(id: 'patrol', name: 'Patrol', numbers: const [], emoji: '🛡️', priority: 2, teams: const []),
        AlertGroup(id: 'family', name: 'Family', numbers: const [], emoji: '👨‍👩‍👧‍👦', priority: 3, teams: const []),
      ],
      warnKey: 'legacy_groups',
    );
  }

  Future<List<AlertGroup>> _buildLegacyGroups() async {
    final results = <AlertGroup>[];

    // ---------------- POLICE ----------------
    final policeTeams = <GroupTeam>[];
    final policeNumbers = <String>{};

    // police_stations (optional)
    final stationDocs = await _safeGetCollectionDocs('police_stations');
    for (final d in stationDocs) {
      final data = d.data();
      final contact = _cleanPhone(data['contact']);
      if (contact.isNotEmpty) policeNumbers.add(contact);
    }

    // station_shifts (preferred “on duty” source)
    final shiftDocs = await _safeGetCollectionDocs('station_shifts');
    for (final s in shiftDocs) {
      final m = s.data();
      final shiftType = (m['shiftType'] ?? '').toString(); // day/night
      final isActive = m['isActive'] == true;
      final officerId = (m['officerId'] ?? '').toString();

      if (officerId.isEmpty) continue;

      // Only fetch the specific officer doc (not all users)
      final officerPhone = await _safeGetUserPhone(officerId);
      if (officerPhone.isEmpty) continue;

      final name = _titleCase(shiftType.isEmpty ? 'Shift' : '$shiftType Shift');
      final existing = policeTeams.indexWhere((t) => t.name == name);

      if (existing >= 0) {
        final merged = {...policeTeams[existing].numbers, officerPhone}.toList();
        policeTeams[existing] = GroupTeam(name: name, numbers: merged);
      } else {
        policeTeams.add(GroupTeam(name: name, numbers: [officerPhone]));
      }

      if (isActive) policeNumbers.add(officerPhone);
    }

    results.add(
      AlertGroup(
        id: 'police',
        name: 'Police',
        numbers: policeNumbers.toList(),
        emoji: '🚔',
        priority: 1,
        teams: policeTeams,
      ),
    );

    // ---------------- PATROL ----------------
    final patrolTeams = <GroupTeam>[];
    final patrolNumbers = <String>{};

    final ptDocs = await _safeGetCollectionDocs('patrol_teams');
    for (final d in ptDocs) {
      final data = d.data();
      final teamName = (data['areaCovered'] ?? data['teamName'] ?? 'Patrol Team').toString();
      final members = (data['members'] as List<dynamic>? ?? []);

      final nums = <String>[];
      for (final m in members) {
        if (m is Map && m['phone'] != null) {
          final phone = _cleanPhone(m['phone']);
          if (phone.isNotEmpty) nums.add(phone);
        }
      }

      if (nums.isNotEmpty) {
        patrolTeams.add(GroupTeam(name: teamName, numbers: nums.toSet().toList()));
        patrolNumbers.addAll(nums);
      }
    }

    final psDocs = await _safeGetCollectionDocs('patrol_shifts');
    for (final d in psDocs) {
      final data = d.data();
      final teamName = (data['teamName'] ?? '').toString();
      final members = (data['members'] as List<dynamic>? ?? []);

      final nums = <String>[];
      for (final m in members) {
        if (m is Map && m['phone'] != null) {
          final phone = _cleanPhone(m['phone']);
          if (phone.isNotEmpty) nums.add(phone);
        }
      }

      if (teamName.isNotEmpty && nums.isNotEmpty) {
        final idx = patrolTeams.indexWhere((t) => t.name == teamName);
        if (idx >= 0) {
          final merged = {...patrolTeams[idx].numbers, ...nums}.toList();
          patrolTeams[idx] = GroupTeam(name: teamName, numbers: merged);
        } else {
          patrolTeams.add(GroupTeam(name: teamName, numbers: nums.toSet().toList()));
        }
        patrolNumbers.addAll(nums);
      }
    }

    results.add(
      AlertGroup(
        id: 'patrol',
        name: 'Patrol',
        numbers: patrolNumbers.toList(),
        emoji: '🛡️',
        priority: 2,
        teams: patrolTeams,
      ),
    );

    // ---------------- FAMILY ----------------
    final familyNumbers = <String>{};

    // contact_groups → name == "Family"
    final cgDocs = await _safeGetCollectionDocs('contact_groups');
    for (final d in cgDocs) {
      final data = d.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      if (name != 'family') continue;

      final members = (data['members'] as List<dynamic>? ?? []);
      for (final m in members) {
        if (m is Map && m['phone'] != null) {
          final phone = _cleanPhone(m['phone']);
          if (phone.isNotEmpty) familyNumbers.add(phone);
        } else if (m is String) {
          final phone = _cleanPhone(m);
          if (phone.isNotEmpty) familyNumbers.add(phone);
        }
      }
    }

    // emergency_contacts
    final ecDocs = await _safeGetCollectionDocs('emergency_contacts');
    for (final d in ecDocs) {
      final data = d.data();
      final phone = _cleanPhone(data['phone'] ?? data['number'] ?? data['phoneNumber']);
      if (phone.isNotEmpty) familyNumbers.add(phone);
    }

    // panic_settings is per-user doc: /panic_settings/{uid}
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final psDoc = await _safeGetDoc('panic_settings', uid);
      final contacts = (psDoc?['contacts'] as List<dynamic>? ?? []);
      for (final c in contacts) {
        final phone = _cleanPhone(c);
        if (phone.isNotEmpty) familyNumbers.add(phone);
      }
    }

    results.add(
      AlertGroup(
        id: 'family',
        name: 'Family',
        numbers: familyNumbers.toList(),
        emoji: '👨‍👩‍👧‍👦',
        priority: 3,
        teams: const [],
      ),
    );

    return results;
  }

  // ---------------- Safe Firestore helpers ----------------

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _safeGetCollectionDocs(String collectionPath) async {
    return _safeQuery(
      () async {
        final snap = await _db.collection(collectionPath).get();
        return snap.docs;
      },
      fallback: <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      warnKey: 'coll:$collectionPath',
    );
  }

  Future<Map<String, dynamic>?> _safeGetDoc(String collection, String docId) async {
    return _safeQuery(
      () async {
        final doc = await _db.collection(collection).doc(docId).get();
        return doc.data();
      },
      fallback: null,
      warnKey: 'doc:$collection/$docId',
    );
  }

  Future<String> _safeGetUserPhone(String userId) async {
    final data = await _safeGetDoc('users', userId);
    if (data == null) return '';
    final phone = _cleanPhone(data['phone']);
    return phone;
  }

  Future<T> _safeQuery<T>(
    Future<T> Function() fn, {
    required T fallback,
    required String warnKey,
  }) async {
    try {
      return await fn();
    } on FirebaseException catch (e) {
      _warnOnce(warnKey, 'Firestore blocked "$warnKey": ${e.code}');
      return fallback;
    } catch (e) {
      _warnOnce(warnKey, 'Error in "$warnKey": $e');
      return fallback;
    }
  }

  void _warnOnce(String key, String msg) {
    if (_warned.contains(key)) return;
    _warned.add(key);
    // ignore: avoid_print
    print('⚠️ $msg');
  }

  String _cleanPhone(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim().replaceAll(' ', '');
    if (s.isEmpty) return '';
    // remove accidental prefixes like "whatsapp:" or "tel:"
    return s.replaceAll(RegExp(r'^(whatsapp:|tel:|sms:)', caseSensitive: false), '');
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
