import '../entities/day_entry_model.dart';

abstract class DayEntryRepository {
  Future<void> registerDayEntry(DayEntryModel entry);
  Stream<List<DayEntryModel>> watchMyRegistrations(String userId);
}
