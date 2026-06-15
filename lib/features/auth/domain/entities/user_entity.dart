import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final double? weightKg;
  final double? heightCm;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.weightKg,
    this.heightCm,
  });

  @override
  List<Object?> get props => [id, email, name, weightKg, heightCm];
}
