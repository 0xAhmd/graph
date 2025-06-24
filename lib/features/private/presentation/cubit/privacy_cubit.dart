import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:ig_mate/features/profile/domain/repo/privacy_repo.dart';
import 'package:ig_mate/features/private/domain/entities/privacy_settings.dart';

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
      debugPrint('Error loading privacy settings: $e');
      emit(PrivacyError(message: 'Failed to load privacy settings'));
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
      debugPrint('Error updating privacy settings: $e');
      emit(PrivacyError(message: 'Failed to update privacy settings'));
    }
  }

  Future<bool> isUserPrivate(String userId) async {
    try {
      return await _privacyRepo.isUserPrivate(userId);
    } catch (e) {
      debugPrint('Error checking if user is private: $e');
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
            debugPrint('Error streaming privacy settings: $error');
            emit(PrivacyError(message: 'Failed to stream privacy settings'));
          },
        );
  }
}
