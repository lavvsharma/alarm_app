import 'storage/hive_storage.dart';
import 'challenge_generator.dart';
import 'scheduler.dart';
import 'audio_service.dart';
import 'challenge_validator.dart';
import 'platform_permissions.dart';

class DI {
  DI._();

  static final HiveStorageService hiveStorage = HiveStorageService();
  static final ChallengeGeneratorService challengeGenerator = ChallengeGeneratorService();
  static final AlarmSchedulerService scheduler = AlarmSchedulerService();
  static final AlarmAudioService audio = AlarmAudioService();
  static final ChallengeValidatorService challengeValidator = ChallengeValidatorService();
  static final PlatformPermissionsService permissions = PlatformPermissionsService();
}

