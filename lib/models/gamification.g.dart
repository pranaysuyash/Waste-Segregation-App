// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AchievementAdapter extends TypeAdapter<Achievement> {
  @override
  final int typeId = 8;

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
      tier: fields[10] as AchievementTier,
      achievementFamilyId: fields[11] as String?,
      unlocksAtLevel: fields[12] as int?,
      claimStatus: fields[13] as ClaimStatus,
      metadata: (fields[14] as Map).cast<String, dynamic>(),
      pointsReward: fields[15] as int,
      relatedAchievementIds: (fields[16] as List).cast<String>(),
      clues: (fields[17] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Achievement obj) {
    writer
      ..writeByte(18)
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
      ..write(obj.progress)
      ..writeByte(10)
      ..write(obj.tier)
      ..writeByte(11)
      ..write(obj.achievementFamilyId)
      ..writeByte(12)
      ..write(obj.unlocksAtLevel)
      ..writeByte(13)
      ..write(obj.claimStatus)
      ..writeByte(14)
      ..write(obj.metadata)
      ..writeByte(15)
      ..write(obj.pointsReward)
      ..writeByte(16)
      ..write(obj.relatedAchievementIds)
      ..writeByte(17)
      ..write(obj.clues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class ChallengeAdapter extends TypeAdapter<Challenge> {
  @override
  final int typeId = 10;

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
      identical(this, other) || other is ChallengeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class UserPointsAdapter extends TypeAdapter<UserPoints> {
  @override
  final int typeId = 11;

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
      other is UserPointsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class WeeklyStatsAdapter extends TypeAdapter<WeeklyStats> {
  @override
  final int typeId = 12;

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
      other is WeeklyStatsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class GamificationProfileAdapter extends TypeAdapter<GamificationProfile> {
  @override
  final int typeId = 9;

  @override
  GamificationProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GamificationProfile(
      userId: fields[0] as String,
      achievements: (fields[1] as List).cast<Achievement>(),
      streaks: (fields[2] as Map).cast<String, StreakDetails>(),
      points: fields[3] as UserPoints,
      activeChallenges: (fields[4] as List).cast<Challenge>(),
      completedChallenges: (fields[5] as List).cast<Challenge>(),
      weeklyStats: (fields[6] as List).cast<WeeklyStats>(),
      discoveredItemIds: (fields[7] as List).cast<String>().toSet(),
      lastDailyEngagementBonusAwardedDate: fields[8] as DateTime?,
      lastViewPersonalStatsAwardedDate: fields[9] as DateTime?,
      unlockedHiddenContentIds: (fields[10] as List).cast<String>().toSet(),
    );
  }

  @override
  void write(BinaryWriter writer, GamificationProfile obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.achievements)
      ..writeByte(2)
      ..write(obj.streaks)
      ..writeByte(3)
      ..write(obj.points)
      ..writeByte(4)
      ..write(obj.activeChallenges)
      ..writeByte(5)
      ..write(obj.completedChallenges)
      ..writeByte(6)
      ..write(obj.weeklyStats)
      ..writeByte(7)
      ..write(obj.discoveredItemIds.toList())
      ..writeByte(8)
      ..write(obj.lastDailyEngagementBonusAwardedDate)
      ..writeByte(9)
      ..write(obj.lastViewPersonalStatsAwardedDate)
      ..writeByte(10)
      ..write(obj.unlockedHiddenContentIds.toList());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamificationProfileAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class StreakDetailsAdapter extends TypeAdapter<StreakDetails> {
  @override
  final int typeId = 14;

  @override
  StreakDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakDetails(
      type: fields[0] as StreakType,
      currentCount: fields[1] as int,
      longestCount: fields[2] as int,
      lastActivityDate: fields[3] as DateTime,
      lastMaintenanceAwardedDate: fields[4] as DateTime?,
      lastMilestoneAwardedLevel: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StreakDetails obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.currentCount)
      ..writeByte(2)
      ..write(obj.longestCount)
      ..writeByte(3)
      ..write(obj.lastActivityDate)
      ..writeByte(4)
      ..write(obj.lastMaintenanceAwardedDate)
      ..writeByte(5)
      ..write(obj.lastMilestoneAwardedLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakDetailsAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class AchievementTypeAdapter extends TypeAdapter<AchievementType> {
  @override
  final int typeId = 5;

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
      case 9:
        return AchievementType.metaAchievement;
      case 10:
        return AchievementType.specialEvent;
      case 11:
        return AchievementType.userGoal;
      case 12:
        return AchievementType.collectionMilestone;
      case 13:
        return AchievementType.firstClassification;
      case 14:
        return AchievementType.weekStreak;
      case 15:
        return AchievementType.monthStreak;
      case 16:
        return AchievementType.recyclingExpert;
      case 17:
        return AchievementType.compostMaster;
      case 18:
        return AchievementType.ecoWarrior;
      case 19:
        return AchievementType.familyTeamwork;
      case 20:
        return AchievementType.helpfulMember;
      case 21:
        return AchievementType.educationalContent;
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
      case AchievementType.metaAchievement:
        writer.writeByte(9);
        break;
      case AchievementType.specialEvent:
        writer.writeByte(10);
        break;
      case AchievementType.userGoal:
        writer.writeByte(11);
        break;
      case AchievementType.collectionMilestone:
        writer.writeByte(12);
        break;
      case AchievementType.firstClassification:
        writer.writeByte(13);
        break;
      case AchievementType.weekStreak:
        writer.writeByte(14);
        break;
      case AchievementType.monthStreak:
        writer.writeByte(15);
        break;
      case AchievementType.recyclingExpert:
        writer.writeByte(16);
        break;
      case AchievementType.compostMaster:
        writer.writeByte(17);
        break;
      case AchievementType.ecoWarrior:
        writer.writeByte(18);
        break;
      case AchievementType.familyTeamwork:
        writer.writeByte(19);
        break;
      case AchievementType.helpfulMember:
        writer.writeByte(20);
        break;
      case AchievementType.educationalContent:
        writer.writeByte(21);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTypeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class AchievementTierAdapter extends TypeAdapter<AchievementTier> {
  @override
  final int typeId = 6;

  @override
  AchievementTier read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AchievementTier.bronze;
      case 1:
        return AchievementTier.silver;
      case 2:
        return AchievementTier.gold;
      case 3:
        return AchievementTier.platinum;
      default:
        return AchievementTier.bronze;
    }
  }

  @override
  void write(BinaryWriter writer, AchievementTier obj) {
    switch (obj) {
      case AchievementTier.bronze:
        writer.writeByte(0);
        break;
      case AchievementTier.silver:
        writer.writeByte(1);
        break;
      case AchievementTier.gold:
        writer.writeByte(2);
        break;
      case AchievementTier.platinum:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementTierAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class ClaimStatusAdapter extends TypeAdapter<ClaimStatus> {
  @override
  final int typeId = 7;

  @override
  ClaimStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ClaimStatus.claimed;
      case 1:
        return ClaimStatus.unclaimed;
      case 2:
        return ClaimStatus.ineligible;
      default:
        return ClaimStatus.claimed;
    }
  }

  @override
  void write(BinaryWriter writer, ClaimStatus obj) {
    switch (obj) {
      case ClaimStatus.claimed:
        writer.writeByte(0);
        break;
      case ClaimStatus.unclaimed:
        writer.writeByte(1);
        break;
      case ClaimStatus.ineligible:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimStatusAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class StreakTypeAdapter extends TypeAdapter<StreakType> {
  @override
  final int typeId = 13;

  @override
  StreakType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StreakType.dailyClassification;
      case 1:
        return StreakType.dailyLearning;
      case 2:
        return StreakType.dailyEngagement;
      case 3:
        return StreakType.itemDiscovery;
      default:
        return StreakType.dailyClassification;
    }
  }

  @override
  void write(BinaryWriter writer, StreakType obj) {
    switch (obj) {
      case StreakType.dailyClassification:
        writer.writeByte(0);
        break;
      case StreakType.dailyLearning:
        writer.writeByte(1);
        break;
      case StreakType.dailyEngagement:
        writer.writeByte(2);
        break;
      case StreakType.itemDiscovery:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakTypeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
