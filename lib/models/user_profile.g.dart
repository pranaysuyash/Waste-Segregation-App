// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrainingConsentAdapter extends TypeAdapter<TrainingConsent> {
  @override
  final int typeId = 16;

  @override
  TrainingConsent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrainingConsent(
      enabled: fields[0] as bool,
      policyVersion: fields[1] as String,
      grantedAt: fields[2] as DateTime?,
      revokedAt: fields[3] as DateTime?,
      source: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrainingConsent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.policyVersion)
      ..writeByte(2)
      ..write(obj.grantedAt)
      ..writeByte(3)
      ..write(obj.revokedAt)
      ..writeByte(4)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingConsentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 4;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      displayName: fields[1] as String?,
      email: fields[2] as String?,
      photoUrl: fields[3] as String?,
      familyId: fields[4] as String?,
      role: fields[5] as UserRole?,
      createdAt: fields[6] as DateTime?,
      lastActive: fields[7] as DateTime?,
      preferences: (fields[8] as Map?)?.cast<String, dynamic>(),
      gamificationProfile: fields[9] as GamificationProfile?,
      tokenWallet: fields[10] as TokenWallet?,
      tokenTransactions: (fields[11] as List?)?.cast<TokenTransaction>(),
      trainingConsent: fields[12] as TrainingConsent?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.photoUrl)
      ..writeByte(4)
      ..write(obj.familyId)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastActive)
      ..writeByte(8)
      ..write(obj.preferences)
      ..writeByte(9)
      ..write(obj.gamificationProfile)
      ..writeByte(10)
      ..write(obj.tokenWallet)
      ..writeByte(11)
      ..write(obj.tokenTransactions)
      ..writeByte(12)
      ..write(obj.trainingConsent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 3;

  @override
  UserRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserRole.admin;
      case 1:
        return UserRole.member;
      case 2:
        return UserRole.child;
      case 3:
        return UserRole.guest;
      default:
        return UserRole.admin;
    }
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    switch (obj) {
      case UserRole.admin:
        writer.writeByte(0);
        break;
      case UserRole.member:
        writer.writeByte(1);
        break;
      case UserRole.child:
        writer.writeByte(2);
        break;
      case UserRole.guest:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
