import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/services/training_admin_service.dart';
import '../../../router/app_router.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../services/training_progress_service.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const QuizScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<QuizScreen> createState() =>
      _QuizScreenState();
}

class _QuizScreenState
    extends State<QuizScreen> {
  final TrainingAdminService
  adminService =
  TrainingAdminService();

  final TrainingProgressService
  progressService =
  TrainingProgressService();

  QuizModel? quiz;

  bool loading = true;

  bool submitting = false;

  int currentIndex = 0;

  List<int?> selectedAnswers = [];

  bool alreadySubmitted = false;

  @override
  void initState() {
    super.initState();

    _loadQuiz();
  }

  // ============================================================
  // LOAD QUIZ
  // ============================================================

  Future<void> _loadQuiz() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user != null) {
        alreadySubmitted =
        await progressService
            .isQuizSubmitted(
          userId: user.uid,
          courseId:
          widget.courseId,
          lessonId:
          widget.lessonId,
        );
      }

      final result =
      await adminService.getQuiz(
        courseId:
        widget.courseId,
        lessonId:
        widget.lessonId,
      );

      if (!mounted) return;

      if (alreadySubmitted) {
        setState(() {
          quiz = result;
          loading = false;
        });

        return;
      }

      if (result != null &&
          result.questions.isNotEmpty) {
        quiz = result;

        selectedAnswers =
            List.generate(
              result.questions.length,
                  (_) => null,
            );
      } else {
        quiz = result;
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint(
        "QUIZ LOAD ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            "Failed to load quiz: $e",
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _submitQuiz() async {
    if (quiz == null ||
        submitting ||
        alreadySubmitted) {
      return;
    }

    if (selectedAnswers
        .contains(null)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            "Please answer all questions",
          ),
        ),
      );

      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      int correct = 0;

      final List<
          Map<String, dynamic>>
      answers = [];

      for (int i = 0;
      i < quiz!.questions.length;
      i++) {
        final QuizQuestionModel
        question =
        quiz!.questions[i];

        final selected =
        selectedAnswers[i]!;

        if (selected ==
            question
                .correctAnswerIndex) {
          correct++;
        }

        answers.add({
          "questionId":
          question.id,
          "selectedAnswer":
          selected,
          "correctAnswer":
          question
              .correctAnswerIndex,
        });
      }

      final score =
      ((correct /
          quiz!.questions
              .length) *
          100)
          .round();

      final passed =
          score >=
              quiz!.passingScore;

      await progressService
          .submitQuiz(
        userId: user.uid,
        courseId:
        widget.courseId,
        lessonId:
        widget.lessonId,
        score: score,
        passed: passed,
        answers: answers,
      );

      if (!mounted) return;

      setState(() {
        submitting = false;
        alreadySubmitted = true;
      });

      // --------------------------------------------------------
      // REPLACE QUIZ WITH REVIEW
      //
      // This is deliberate.
      //
      // Browser Back / GoRouter Back now returns to Lesson,
      // not to the editable quiz.
      // --------------------------------------------------------

      context.pushReplacement(
        AppRouter.quizReviewPath(
          widget.courseId,
          widget.lessonId,
        ),
      );
    } catch (e) {
      debugPrint(
        "QUIZ SUBMIT ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        submitting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            "Failed to submit quiz: $e",
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (loading) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (alreadySubmitted) {
      return _buildAlreadySubmitted();
    }

    if (quiz == null) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child:
          Text(
            "Quiz not available",
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff003366),
        foregroundColor:
        Colors.white,
        title:
        const Text(
          "Lesson Quiz",
        ),
        leading:
        IconButton(
          onPressed: () {
            context.pop();
          },
          icon:
          const Icon(
            Icons.arrow_back,
          ),
        ),
      ),

      body:
      _buildQuiz(),
    );
  }

  // ============================================================
  // ALREADY SUBMITTED
  // ============================================================

  Widget _buildAlreadySubmitted() {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff003366),
        foregroundColor:
        Colors.white,
        title:
        const Text(
          "Lesson Quiz",
        ),
        leading:
        IconButton(
          onPressed: () {
            context.pop();
          },
          icon:
          const Icon(
            Icons.arrow_back,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 70,
                color:
                Colors.green,
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Quiz Already Submitted",
                style:
                TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xff003366),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                "This quiz has already been submitted. "
                    "You can review your answers.",
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(
                height: 25,
              ),

              ElevatedButton.icon(
                onPressed: () {
                  context.go(
                    AppRouter
                        .quizReviewPath(
                      widget.courseId,
                      widget.lessonId,
                    ),
                  );
                },
                icon:
                const Icon(
                  Icons.visibility,
                ),
                label:
                const Text(
                  "Review Quiz",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUIZ
  // ============================================================

  Widget _buildQuiz() {
    if (quiz!.questions.isEmpty) {
      return const Center(
        child:
        Text(
          "This quiz has no questions.",
        ),
      );
    }

    final question =
    quiz!.questions[
    currentIndex];

    return Padding(
      padding:
      const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            "Question ${currentIndex + 1} / "
                "${quiz!.questions.length}",
            style:
            const TextStyle(
              color:
              Color(0xff003366),
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          LinearProgressIndicator(
            value:
            (currentIndex + 1) /
                quiz!.questions.length,
            minHeight: 7,
          ),

          const SizedBox(
            height: 20,
          ),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(22),
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              border:
              Border.all(
                color:
                const Color(
                  0xffE4E9F0,
                ),
              ),
            ),
            child:
            Text(
              question.question,
              style:
              const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          ...List.generate(
            question.options.length,
                (index) {
              final selected =
                  selectedAnswers[
                  currentIndex] ==
                      index;

              return GestureDetector(
                onTap: () {
                  if (submitting) {
                    return;
                  }

                  setState(() {
                    selectedAnswers[
                    currentIndex] =
                        index;
                  });
                },
                child:
                Container(
                  margin:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  padding:
                  const EdgeInsets.all(
                    16,
                  ),
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? const Color(
                        0xff003366)
                        : Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color:
                      selected
                          ? const Color(
                          0xff003366)
                          : const Color(
                          0xffE4E9F0),
                    ),
                  ),
                  child:
                  Row(
                    children: [
                      Icon(
                        selected
                            ? Icons
                            .radio_button_checked
                            : Icons
                            .radio_button_off,
                        color: selected
                            ? Colors.white
                            : const Color(
                            0xff003366),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child:
                        Text(
                          question
                              .options[index],
                          style:
                          TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors
                                .black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 20,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              ElevatedButton(
                onPressed:
                currentIndex == 0 ||
                    submitting
                    ? null
                    : () {
                  setState(() {
                    currentIndex--;
                  });
                },
                child:
                const Text(
                  "Previous",
                ),
              ),

              currentIndex ==
                  quiz!.questions
                      .length -
                      1
                  ? ElevatedButton.icon(
                onPressed:
                submitting
                    ? null
                    : _submitQuiz,
                icon:
                submitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.check,
                ),
                label:
                Text(
                  submitting
                      ? "Submitting..."
                      : "Submit Quiz",
                ),
              )
                  : ElevatedButton(
                onPressed:
                submitting
                    ? null
                    : () {
                  setState(() {
                    currentIndex++;
                  });
                },
                child:
                const Text(
                  "Next",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}