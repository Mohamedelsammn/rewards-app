import 'package:equatable/equatable.dart';

/// A participant who has NOT already won -- the candidate list for Admin
/// Analytics' manual "Select Winner" participant picker (implementation
/// requires the four-digit participation code as the primary identifier,
/// never "Ticket #1").
class EligibleParticipant extends Equatable {
  const EligibleParticipant({
    required this.participationId,
    required this.participationNumber,
    required this.fullName,
    required this.createdAt,
    this.phoneE164,
  });

  final String participationId;
  final int participationNumber;
  final String fullName;
  final DateTime createdAt;
  final String? phoneE164;

  String get formattedNumber => participationNumber.toString().padLeft(4, '0');

  factory EligibleParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return EligibleParticipant(
      participationId: json['id'] as String,
      participationNumber: json['participation_number'] as int? ?? 0,
      fullName: user?['full_name'] as String? ?? 'Anonymous',
      phoneE164: user?['phone_e164'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [participationId, participationNumber, fullName, createdAt, phoneE164];
}
