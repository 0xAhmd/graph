part of 'privacy_cubit.dart';

abstract class PrivacyState extends Equatable {
  const PrivacyState();

  @override
  List<Object> get props => [];
}

class PrivacyInitial extends PrivacyState {}

class PrivacyLoading extends PrivacyState {}

class PrivacyLoaded extends PrivacyState {
  final PrivacySettingsEntity privacySettings;

  const PrivacyLoaded({required this.privacySettings});

  @override
  List<Object> get props => [privacySettings];
}

class PrivacyError extends PrivacyState {
  final String message;

  const PrivacyError({required this.message});

  @override
  List<Object> get props => [message];
}
