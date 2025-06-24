import 'package:flutter/material.dart';

/// Represents the type of educational content
enum ContentType {
  article,
  video,
  infographic,
  quiz,
  tutorial,
  tip,
}

/// Represents the difficulty or level of the content
enum ContentLevel {
  beginner,
  intermediate,
  advanced,
}

/// Represents an educational content item in the app
class EducationalContent {
  /// Constructor for educational content
  const EducationalContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.thumbnailUrl,
    required this.categories,
    required this.level,
    required this.dateAdded,
    required this.durationMinutes,
    required this.icon,
    this.videoUrl,
    this.contentText,
    this.imageUrl,
    this.questions,
    this.steps,
    this.tags = const [],
    this.isPremium = false,
  });

  /// Factory method to create article content
  factory EducationalContent.article({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required String contentText,
    required List<String> categories,
    required ContentLevel level,
    required int durationMinutes,
    List<String> tags = const [],
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.article,
      thumbnailUrl: thumbnailUrl,
      contentText: contentText,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: durationMinutes,
      isPremium: isPremium,
      icon: Icons.article,
    );
  }

  /// Factory method to create video content
  factory EducationalContent.video({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required String videoUrl,
    required List<String> categories,
    required ContentLevel level,
    required int durationMinutes,
    List<String> tags = const [],
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.video,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: durationMinutes,
      isPremium: isPremium,
      icon: Icons.video_library,
    );
  }

  /// Factory method to create infographic content
  factory EducationalContent.infographic({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required String imageUrl,
    required List<String> categories,
    required ContentLevel level,
    required int durationMinutes,
    String? contentText,
    List<String> tags = const [],
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.infographic,
      thumbnailUrl: thumbnailUrl,
      imageUrl: imageUrl,
      contentText: contentText,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: durationMinutes,
      isPremium: isPremium,
      icon: Icons.image,
    );
  }

  /// Factory method to create quiz content
  factory EducationalContent.quiz({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required List<QuizQuestion> questions,
    required List<String> categories,
    required ContentLevel level,
    required int durationMinutes,
    List<String> tags = const [],
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.quiz,
      thumbnailUrl: thumbnailUrl,
      questions: questions,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: durationMinutes,
      isPremium: isPremium,
      icon: Icons.quiz,
    );
  }

  /// Factory method to create tutorial content
  factory EducationalContent.tutorial({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required List<TutorialStep> steps,
    required List<String> categories,
    required ContentLevel level,
    required int durationMinutes,
    List<String> tags = const [],
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.tutorial,
      thumbnailUrl: thumbnailUrl,
      steps: steps,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: durationMinutes,
      isPremium: isPremium,
      icon: Icons.menu_book,
    );
  }

  /// Factory method to create tip content
  factory EducationalContent.tip({
    required String id,
    required String title,
    required String description,
    required String thumbnailUrl,
    required String contentText,
    required List<String> categories,
    List<String> tags = const [],
    ContentLevel level = ContentLevel.beginner,
    bool isPremium = false,
  }) {
    return EducationalContent(
      id: id,
      title: title,
      description: description,
      type: ContentType.tip,
      thumbnailUrl: thumbnailUrl,
      contentText: contentText,
      categories: categories,
      tags: tags,
      level: level,
      dateAdded: DateTime.now(),
      durationMinutes: 1,
      isPremium: isPremium,
      icon: Icons.lightbulb_outline,
    );
  }
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String thumbnailUrl;
  final String? videoUrl;
  final String? contentText;
  final List<String> categories;
  final List<String> tags;
  final ContentLevel level;
  final DateTime dateAdded;
  final bool isPremium;
  final int durationMinutes;
  final IconData icon;

  /// For infographics: the image URL
  final String? imageUrl;

  /// For quizzes: list of questions and answers
  final List<QuizQuestion>? questions;

  /// For tutorials: list of steps
  final List<TutorialStep>? steps;

  /// Get color based on content type
  Color getTypeColor() {
    switch (type) {
      case ContentType.article:
        return Colors.blue;
      case ContentType.video:
        return Colors.red;
      case ContentType.infographic:
        return Colors.green;
      case ContentType.quiz:
        return Colors.orange;
      case ContentType.tutorial:
        return Colors.purple;
      case ContentType.tip:
        return Colors.teal;
    }
  }

  /// Get level text
  String getLevelText() {
    switch (level) {
      case ContentLevel.beginner:
        return 'Beginner';
      case ContentLevel.intermediate:
        return 'Intermediate';
      case ContentLevel.advanced:
        return 'Advanced';
    }
  }

  /// Get formatted duration text
  String getFormattedDuration() {
    if (durationMinutes < 1) {
      return 'Less than 1 min';
    } else if (durationMinutes == 1) {
      return '1 minute';
    } else if (durationMinutes < 60) {
      return '$durationMinutes minutes';
    } else {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      if (mins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $mins min';
      }
    }
  }
}

/// Represents a quiz question in the educational content
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;
}

/// Represents a tutorial step in the educational content
class TutorialStep {
  const TutorialStep({
    required this.title,
    required this.description,
    this.imageUrl,
  });
  final String title;
  final String description;
  final String? imageUrl;
}

/// Represents a daily tip for the home screen
class DailyTip {
  const DailyTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.date,
    this.actionText,
    this.actionLink,
  });
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime date;
  final String? actionText;
  final String? actionLink;
}
