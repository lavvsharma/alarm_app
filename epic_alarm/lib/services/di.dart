import 'storage/hive_storage.dart';
import 'challenge_generator.dart';
import 'scheduler.dart';

class DI {
  DI._();

  static final HiveStorageService hiveStorage = HiveStorageService();
  static final ChallengeGeneratorService challengeGenerator = ChallengeGeneratorService();
  static final AlarmSchedulerService scheduler = AlarmSchedulerService();
}

