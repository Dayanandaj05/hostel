import 'package:hostel_app/features/dayentry/domain/entities/day_entry_model.dart';
import 'package:hostel_app/features/dayentry/domain/repositories/day_entry_repository.dart';
import 'package:hostel_app/services/mock/mock_service.dart';

class MockDayEntryRepository implements DayEntryRepository {
  @override
  Future<void> registerDayEntry(DayEntryModel entry) {
    return MockService.registerDayEntry(entry);
  }

  @override
  Stream<List<DayEntryModel>> watchMyRegistrations(String userId) {
    return MockService.watchMyDayEntries(userId);
  }
}
