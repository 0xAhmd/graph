import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../profile/domain/repo/privacy_repo.dart';
import '../../domain/entities/privacy_settings.dart';

part 'privacy_state.dart';

class PrivacyCubit extends Cubit<PrivacyState> {
  final PrivacyRepoContract _privacyRepo;

  PrivacyCubit(this._privacyRepo) : super(PrivacyInitial());

  Future<void> loadPrivacySettings(String userId) async {
    emit(PrivacyLoading());
    try {
      final settings = await _privacyRepo.getPrivacySettings(userId);
      if (settings != null) {
        emit(PrivacyLoaded(privacySettings: settings));
      } else {
        // Create default settings if none exist
        final defaultSettings = PrivacySettingsEntity(
          userId: userId,
          isPrivate: false,
          updatedAt: DateTime.now(),
        );
        emit(PrivacyLoaded(privacySettings: defaultSettings));
      }
    } catch (e) {

      emit(const PrivacyError(message: 'Failed to load privacy settings'));
    }
  }

  Future<void> updatePrivacySettings({
    required String userId,
    required bool isPrivate,
  }) async {
    try {
      await _privacyRepo.updatePrivacySettings(
        userId: userId,
        isPrivate: isPrivate,
      );

      // Update the current state
      if (state is PrivacyLoaded) {
        final currentSettings = (state as PrivacyLoaded).privacySettings;
        final updatedSettings = currentSettings.copyWith(
          isPrivate: isPrivate,
          updatedAt: DateTime.now(),
        );
        emit(PrivacyLoaded(privacySettings: updatedSettings));
      }
    } catch (e) {

      emit(const PrivacyError(message: 'Failed to update privacy settings'));
    }
  }

  Future<bool> isUserPrivate(String userId) async {
    try {
      return await _privacyRepo.isUserPrivate(userId);
    } catch (e) {

      return false;
    }
  }

  void streamPrivacySettings(String userId) {
    _privacyRepo
        .streamPrivacySettings(userId)
        .listen(
          (settings) {
            if (settings != null) {
              emit(PrivacyLoaded(privacySettings: settings));
            }
          },
          onError: (error) {

            emit(
              const PrivacyError(message: 'Failed to stream privacy settings'),
            );
          },
        );
  }

  Future<void> togglePrivacy(String userId, bool isPrivate) async {
    emit(PrivacyLoading());
    await updatePrivacySettings(userId: userId, isPrivate: isPrivate);
  }
}
