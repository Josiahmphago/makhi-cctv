import 'package:hive/hive.dart';

part 'quick_alert_contact_local.g.dart';

@HiveType(typeId: 0)
class QuickAlertContactLocal extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String phoneNumber;

  QuickAlertContactLocal({
    required this.name,
    required this.phoneNumber,
  });
}
