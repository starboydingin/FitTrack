import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.weightKg,
    super.heightCm,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:       json['id'] as String,
        email:    json['email'] as String,
        name:     json['name'] as String,
        weightKg: (json['weightKg'] ?? json['weight_kg'] as num?)?.toDouble(),
        heightCm: (json['heightCm'] ?? json['height_cm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'email':     email,
        'name':      name,
        'weightKg':  weightKg,
        'heightCm':  heightCm,
      };
}
