import '../models/models.dart';

bool matchesTournamentLocationAndDate(
  Tournament tournament,
  String city,
  DateTime startDate,
) {
  final existingDate = tournament.startDate.toLocal();
  final candidateDate = startDate.toLocal();
  return tournament.city.trim().toLowerCase() == city.trim().toLowerCase() &&
      existingDate.year == candidateDate.year &&
      existingDate.month == candidateDate.month &&
      existingDate.day == candidateDate.day;
}
