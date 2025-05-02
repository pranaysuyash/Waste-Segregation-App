// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 2;

  @override
  Achievement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Achievement(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as AchievementType,
      threshold: fields[4] as int,
      iconName: fields[5] as String,
      color: fields[6] as Color,
      isSecret: fields[7] as bool,
      earnedOn: fields[8] as DateTime?,
      progress: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.threshold)
      ..writeByte(5)
      ..write(obj.iconName)
      ..writeByte(6)
      ..write(obj.color)
      ..writeByte(7)
      ..write(obj.isSecret)
      ..writeByte(8)
      ..write(obj.earnedOn)
      ..writeByte(9)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StreakAdapter extends TypeAdapter<Streak> {
  @override
  final int typeId = 3;

  @override
  Streak read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Streak(
      current: fields[0] as int,
      longest: fields[1] as int,
      lastUsageDate: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Streak obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.current)
      ..writeByte(1)
      ..write(obj.longest)
      ..writeByte(2)
      ..write(obj.lastUsageDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 4;

  @override
  Challenge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Challenge(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      pointsReward: fields[5] as int,
      iconName: fields[6] as String,
      color: fields[7] as Color,
      requirements: (fields[8] as Map).cast<String, dynamic>(),
      isCompleted: fields[9] as bool,
      progress: fields[10] as double,
      participantIds: (fields[11] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Challenge obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.pointsReward)
      ..writeByte(6)
      ..write(obj.iconName)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.requirements)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.progress)
      ..writeByte(11)
      ..write(obj.participantIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChallengeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserPointsAdapter extends TypeAdapter<UserPoints> {
  @override
  final int typeId = 5;

  @override
  UserPoints read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPoints(
      total: fields[0] as int,
      weeklyTotal: fields[1] as int,
      monthlyTotal: fields[2] as int,
      level: fields[3] as int,
      categoryPoints: (fields[4] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserPoints obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.total)
      ..writeByte(1)
      ..write(obj.weeklyTotal)
      ..writeByte(2)
      ..write(obj.monthlyTotal)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.categoryPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPointsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WeeklyStatsAdapter extends TypeAdapter<WeeklyStats> {
  @override
  final int typeId = 6;

  @override
  WeeklyStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyStats(
      weekStartDate: fields[0] as DateTime,
      itemsIdentified: fields[1] as int,
      challengesCompleted: fields[2] as int,
      streakMaximum: fields[3] as int,
      pointsEarned: fields[4] as int,
      categoryCounts: (fields[5] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyStats obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.weekStartDate)
      ..writeByte(1)
      ..write(obj.itemsIdentified)
      ..writeByte(2)
      ..write(obj.challengesCompleted)
      ..writeByte(3)
      ..write(obj.streakMaximum)
      ..writeByte(4)
      ..write(obj.pointsEarned)
      ..writeByte(5)
      ..write(obj.categoryCounts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GamificationProfileAdapter extends TypeAdapter<GamificationProfile> {
  @override
  final int typeId = 7;

  @override
  GamificationProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GamificationProfile(
      userId: fields[0] as String,
      achievements: (fields[1] as List).cast<Achievement>(),
      streak: fields[2] as Streak,
      points: fields[3] as UserPoints,
      activeChallenges: (fields[4] as List).cast<Challenge>(),
      completedChallenges: (fields[5] as List).cast<Challenge>(),
      weeklyStats: (fields[6] as List).cast<WeeklyStats>(),
    );
  }

  @override
  void write(BinaryWriter writer, GamificationProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.achievements)
      ..writeByte(2)
      ..write(obj.streak)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.activeChallenges)
      ..writeByte(5)
      ..write(obj.completedChallenges)
      ..writeByte(6)
      ..write(obj.weeklyStats);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamificationProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 1;

  @override
  AchievementType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementType.wasteIdentified;
      case 1:
        return AchievementType.categoriesIdentified;
      case 2:
        return AchievementType.streakMaintained;
      case 3:
        return AchievementType.challengesCompleted;
      case 4:
        return AchievementType.perfectWeek;
      case 5:
        return AchievementType.knowledgeMaster;
      case 6:
        return AchievementType.quizCompleted;
      case 7:
        return AchievementType.specialItem;
      case 8:
        return AchievementType.communityContribution;
      default:
        return AchievementType.wasteIdentified;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementType obj) {
    switch (obj) {
      case AchievementType.wasteIdentified:
        writer.writeByte(0);
        break;
      case AchievementType.categoriesIdentified:
        writer.writeByte(1);
        break;
      case AchievementType.streakMaintained:
        writer.writeByte(2);
        break;
      case AchievementType.challengesCompleted:
        writer.writeByte(3);
        break;
      case AchievementType.perfectWeek:
        writer.writeByte(4);
        break;
      case AchievementType.knowledgeMaster:
        writer.writeByte(5);
        break;
      case AchievementType.quizCompleted:
        writer.writeByte(6);
        break;
      case AchievementType.specialItem:
        writer.writeByte(7);
        break;
      case AchievementType.communityContribution:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
