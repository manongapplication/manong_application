import 'package:manong_application/models/urgency_level.dart';

class UrgencyLevelUtil {
  static const List<UrgencyLevel> _urgencyLevels = [
    UrgencyLevel(id: 0, level: 'Normal', time: '2-4 hours'),
    UrgencyLevel(id: 1, level: 'Urgent', time: '1-2 hours', price: 20.00),
    UrgencyLevel(id: 2, level: 'Emergency', time: '30-60 mins', price: 30.00),
  ];

  List<UrgencyLevel> get getUrgencyLevels => _urgencyLevels;
}
