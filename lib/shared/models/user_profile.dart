import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneE164,
    required this.countryCode,
  });

  final String id;
  final String fullName;
  final String phoneE164;
  final String countryCode;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['userId'] as String? ?? json['user_id'] as String? ?? json['id'] as String,
    fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
    phoneE164: json['phoneE164'] as String? ?? json['phone_e164'] as String? ?? '',
    countryCode: json['countryCode'] as String? ?? json['country_code'] as String? ?? '',
  );

  @override
  List<Object?> get props => [id, fullName, phoneE164, countryCode];
}
