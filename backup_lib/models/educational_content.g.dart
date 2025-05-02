// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'educational_content.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EducationalContentAdapter extends TypeAdapter<EducationalContent> {
  @override
  final int typeId = 10;

  @override
  EducationalContent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EducationalContent(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as ContentType,
      thumbnailUrl: fields[4] as String,
      categories: (fields[7] as List).cast<String>(),
      level: fields[9] as ContentLevel,
      dateAdded: fields[10] as DateTime,
      durationMinutes: fields[12] as int,
      icon: fields[13] as IconData,
      videoUrl: fields[5] as String?,
      contentText: fields[6] as String?,
      imageUrl: fields[14] as String?,
      questions: (fields[15] as List?)?.cast<QuizQuestion>(),
      steps: (fields[16] as List?)?.cast<TutorialStep>(),
      tags: (fields[8] as List).cast<String>(),
      isPremium: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EducationalContent obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.videoUrl)
      ..writeByte(6)
      ..write(obj.contentText)
      ..writeByte(7)
      ..write(obj.categories)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.level)
      ..writeByte(10)
      ..write(obj.dateAdded)
      ..writeByte(11)
      ..write(obj.isPremium)
      ..writeByte(12)
      ..write(obj.durationMinutes)
      ..writeByte(13)
      ..write(obj.icon)
      ..writeByte(14)
      ..write(obj.imageUrl)
      ..writeByte(15)
      ..write(obj.questions)
      ..writeByte(16)
      ..write(obj.steps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationalContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuizQuestionAdapter extends TypeAdapter<QuizQuestion> {
  @override
  final int typeId = 11;

  @override
  QuizQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizQuestion(
      question: fields[0] as String,
      options: (fields[1] as List).cast<String>(),
      correctOptionIndex: fields[2] as int,
      explanation: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, QuizQuestion obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.options)
      ..writeByte(2)
      ..write(obj.correctOptionIndex)
      ..writeByte(3)
      ..write(obj.explanation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TutorialStepAdapter extends TypeAdapter<TutorialStep> {
  @override
  final int typeId = 12;

  @override
  TutorialStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TutorialStep(
      title: fields[0] as String,
      description: fields[1] as String,
      imageUrl: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TutorialStep obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorialStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentProgressAdapter extends TypeAdapter<ContentProgress> {
  @override
  final int typeId = 13;

  @override
  ContentProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentProgress(
      contentId: fields[0] as String,
      isCompleted: fields[1] as bool,
      progress: fields[2] as double,
      lastPosition: fields[3] as int,
      lastAccessed: fields[4] as DateTime?,
      quizResults: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContentProgress obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.contentId)
      ..writeByte(1)
      ..write(obj.isCompleted)
      ..writeByte(2)
      ..write(obj.progress)
      ..writeByte(3)
      ..write(obj.lastPosition)
      ..writeByte(4)
      ..write(obj.lastAccessed)
      ..writeByte(5)
      ..write(obj.quizResults);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyTipAdapter extends TypeAdapter<DailyTip> {
  @override
  final int typeId = 14;

  @override
  DailyTip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyTip(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      category: fields[3] as String,
      date: fields[4] as DateTime,
      actionText: fields[5] as String?,
      actionLink: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyTip obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.actionText)
      ..writeByte(6)
      ..write(obj.actionLink);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentTypeAdapter extends TypeAdapter<ContentType> {
  @override
  final int typeId = 8;

  @override
  ContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentType.article;
      case 1:
        return ContentType.video;
      case 2:
        return ContentType.infographic;
      case 3:
        return ContentType.quiz;
      case 4:
        return ContentType.tutorial;
      case 5:
        return ContentType.tip;
      default:
        return ContentType.article;
    }
  }

  @override
  void write(BinaryWriter writer, ContentType obj) {
    switch (obj) {
      case ContentType.article:
        writer.writeByte(0);
        break;
      case ContentType.video:
        writer.writeByte(1);
        break;
      case ContentType.infographic:
        writer.writeByte(2);
        break;
      case ContentType.quiz:
        writer.writeByte(3);
        break;
      case ContentType.tutorial:
        writer.writeByte(4);
        break;
      case ContentType.tip:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentLevelAdapter extends TypeAdapter<ContentLevel> {
  @override
  final int typeId = 9;

  @override
  ContentLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentLevel.beginner;
      case 1:
        return ContentLevel.intermediate;
      case 2:
        return ContentLevel.advanced;
      default:
        return ContentLevel.beginner;
    }
  }

  @override
  void write(BinaryWriter writer, ContentLevel obj) {
    switch (obj) {
      case ContentLevel.beginner:
        writer.writeByte(0);
        break;
      case ContentLevel.intermediate:
        writer.writeByte(1);
        break;
      case ContentLevel.advanced:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
