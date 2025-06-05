import 'package:flutter/material.dart';
import '../models/educational_content.dart';
import '../utils/constants.dart';
import '../utils/accessibility_contrast_fixes.dart';

class QuizScreen extends StatefulWidget {

  const QuizScreen({
    super.key,
    required this.quizContent,
  });
  final EducationalContent quizContent;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _selectedOptionIndex = -1;
  bool _hasAnswered = false;
  List<int> _userAnswers = [];
  bool _quizFinished = false;
  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.quizContent.questions ?? [];
    _userAnswers = List<int>.filled(_questions.length, -1);
  }

  void _selectOption(int optionIndex) {
    if (_hasAnswered) return;

    setState(() {
      _selectedOptionIndex = optionIndex;
      _hasAnswered = true;
      _userAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _hasAnswered = false;
        _selectedOptionIndex = -1;
      } else {
        _quizFinished = true;
      }
    });
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = -1;
      _hasAnswered = false;
      _userAnswers = List<int>.filled(_questions.length, -1);
      _quizFinished = false;
    });
  }

  int _calculateScore() {
    var correctAnswers = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctOptionIndex) {
        correctAnswers++;
      }
    }
    return correctAnswers;
  }

  String _getScoreMessage(int score) {
    final percentage = (score / _questions.length) * 100;

    if (percentage >= 90) {
      return 'Excellent! You\'re a waste segregation expert!';
    } else if (percentage >= 70) {
      return 'Good job! You know your waste categories well.';
    } else if (percentage >= 50) {
      return 'Not bad. Keep learning about waste segregation.';
    } else {
      return 'You could use more practice. Try reviewing the materials again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no questions, show error message
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
        ),
        body: const Center(
          child: Text('No questions available for this quiz.'),
        ),
      );
    }

    // If quiz is finished, show results screen
    if (_quizFinished) {
      return _buildResultsScreen();
    }

    // Otherwise show quiz question screen
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.quizContent.title}'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.orange.shade100,
            color: Colors.orange,
          ),

          // Question number indicator
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.quizContent.durationMinutes ~/ _questions.length} min',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusRegular),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      _questions[_currentQuestionIndex].question,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingLarge),

                  // Options
                  ...List.generate(
                      _questions[_currentQuestionIndex].options.length,
                      (index) {
                    final isCorrect = index ==
                        _questions[_currentQuestionIndex].correctOptionIndex;
                    final isSelected = index == _selectedOptionIndex;

                    // Determine option card style based on selection and correctness
                    var backgroundColor = Colors.white;
                    var borderColor = Colors.grey.shade300;

                    if (_hasAnswered) {
                      if (isCorrect) {
                        backgroundColor = Colors.green.shade50;
                        borderColor = Colors.green;
                      } else if (isSelected) {
                        backgroundColor = Colors.red.shade50;
                        borderColor = Colors.red;
                      }
                    } else if (isSelected) {
                      backgroundColor = Colors.blue.shade50;
                      borderColor = Colors.blue;
                    }

                    return GestureDetector(
                      onTap: () {
                        _selectOption(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: AppTheme.paddingRegular),
                        padding: const EdgeInsets.all(AppTheme.paddingRegular),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusRegular),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Option indicator
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _hasAnswered
                                    ? isCorrect
                                        ? Colors.green
                                        : isSelected
                                            ? Colors.red
                                            : Colors.grey.shade300
                                    : isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: _hasAnswered
                                    ? Icon(
                                        isCorrect
                                            ? Icons.check
                                            : isSelected
                                                ? Icons.close
                                                : null,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : Text(
                                        String.fromCharCode(
                                            65 + index), // A, B, C, D...
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(width: AppTheme.paddingRegular),

                            // Option text
                            Expanded(
                              child: Text(
                                _questions[_currentQuestionIndex]
                                    .options[index],
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeRegular,
                                  color: _hasAnswered && isCorrect
                                      ? Colors.green.shade800
                                      : _hasAnswered && isSelected
                                          ? Colors.red.shade800
                                          : AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Explanation after answering
                  if (_hasAnswered &&
                      _questions[_currentQuestionIndex].explanation !=
                          null) ...[
                    const SizedBox(height: AppTheme.paddingRegular),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.paddingRegular),
                      decoration: AccessibilityContrastFixes.getAccessibleInfoBoxDecoration('blue'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AccessibilityContrastFixes.getContrastColors('blue_info_box').textColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Explanation',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: AccessibilityContrastFixes.getContrastColors('blue_info_box').textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.paddingSmall),
                          Text(
                            _questions[_currentQuestionIndex].explanation!,
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip/Back button
                if (_currentQuestionIndex > 0)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentQuestionIndex--;
                        _hasAnswered =
                            _userAnswers[_currentQuestionIndex] != -1;
                        _selectedOptionIndex =
                            _userAnswers[_currentQuestionIndex];
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasAnswered = true;
                        _userAnswers[_currentQuestionIndex] = -1;
                      });
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                  ),

                // Next/Finish button
                ElevatedButton(
                  onPressed: _hasAnswered ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next'
                        : 'Finish',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final score = _calculateScore();
    final percentage = (score / _questions.length) * 100;

    // Determine result color based on score
    Color resultColor;
    if (percentage >= 90) {
      resultColor = Colors.green;
    } else if (percentage >= 70) {
      resultColor = Colors.green.shade300;
    } else if (percentage >= 50) {
      resultColor = Colors.orange;
    } else {
      resultColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(color: resultColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Score circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: resultColor,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score/${_questions.length}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: resultColor,
                            ),
                          ),
                          Text(
                            '${percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeRegular,
                              color: resultColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.paddingRegular),

                  // Result message
                  Text(
                    _getScoreMessage(score),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Question review section
            const Text(
              'Question Review',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppTheme.paddingRegular),

            // List of questions with answers
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final userAnswer = _userAnswers[index];
                final isCorrect = userAnswer == question.correctOptionIndex;

                return Container(
                  margin:
                      const EdgeInsets.only(bottom: AppTheme.paddingRegular),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusRegular),
                    border: Border.all(
                      color: userAnswer == -1
                          ? Colors.grey.shade300
                          : isCorrect
                              ? Colors.green
                              : Colors.red,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question header
                      Container(
                        padding: const EdgeInsets.all(AppTheme.paddingRegular),
                        decoration: BoxDecoration(
                          color: userAnswer == -1
                              ? Colors.grey.shade100
                              : isCorrect
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(
                                AppTheme.borderRadiusRegular - 1),
                            topRight: Radius.circular(
                                AppTheme.borderRadiusRegular - 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Question number
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: userAnswer == -1
                                    ? Colors.grey
                                    : isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  userAnswer == -1
                                      ? Icons.help_outline
                                      : isCorrect
                                          ? Icons.check
                                          : Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),

                            const SizedBox(width: AppTheme.paddingRegular),

                            // Question text
                            Expanded(
                              child: Text(
                                'Question ${index + 1}',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                  color: userAnswer == -1
                                      ? AppTheme.textPrimaryColor
                                      : isCorrect
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Question and answers
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingRegular),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeRegular,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: AppTheme.paddingRegular),

                            // Correct answer
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Correct answer: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    question
                                        .options[question.correctOptionIndex],
                                  ),
                                ),
                              ],
                            ),

                            // User answer if different
                            if (userAnswer != -1 &&
                                userAnswer != question.correctOptionIndex) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Your answer: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      question.options[userAnswer],
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (userAnswer == -1) ...[
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.remove_circle,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'You skipped this question',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Explanation if available
                            if (question.explanation != null) ...[
                              const SizedBox(height: AppTheme.paddingSmall),
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.paddingSmall),
                                decoration: AccessibilityContrastFixes.getAccessibleInfoBoxDecoration('blue'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AccessibilityContrastFixes.getContrastColors('blue_info_box').textColor,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Explanation',
                                          style: TextStyle(
                                            fontSize: AppTheme.fontSizeSmall,
                                            fontWeight: FontWeight.bold,
                                            color: AccessibilityContrastFixes.getContrastColors('blue_info_box').textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      question.explanation!,
                                      style: TextStyle(
                                        fontSize: AppTheme.fontSizeSmall,
                                        color: AccessibilityContrastFixes.getContrastColors('blue_info_box').textColor,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Action buttons
            Row(
              children: [
                // Try again button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetQuiz,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.paddingRegular,
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),

                const SizedBox(width: AppTheme.paddingRegular),

                // Back to content button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.paddingRegular,
                      ),
                    ),
                    child: const Text('Back to Content'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
