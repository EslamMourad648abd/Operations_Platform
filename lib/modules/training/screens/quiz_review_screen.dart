import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../admin/services/training_admin_service.dart';
import '../../../router/app_router.dart';
import '../models/quiz_model.dart';
import '../services/training_progress_service.dart';

class QuizReviewScreen
    extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const QuizReviewScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<QuizReviewScreen>
  createState() =>
      _QuizReviewScreenState();
}

class _QuizReviewScreenState
    extends State<QuizReviewScreen> {
  final TrainingProgressService
  progressService =
  TrainingProgressService();

  final TrainingAdminService
  adminService =
  TrainingAdminService();

  bool loading = true;

  QuizModel? quiz;

  int score = 0;

  bool passed = false;

  List<int?> selectedAnswers = [];

  @override
  void initState() {
    super.initState();

    _loadReview();
  }

  // ============================================================
  // LOAD REVIEW
  // ============================================================

  Future<void> _loadReview() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        return;
      }

      final result =
      await progressService
          .getQuizResult(
        userId: user.uid,
        courseId:
        widget.courseId,
        lessonId:
        widget.lessonId,
      );

      if (result == null) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        return;
      }

      score =
      (result["score"] ?? 0)
      as int;

      passed =
          result["passed"] ??
              false;

      final answers =
          result["answers"]
          as List<dynamic>? ??
              [];

      selectedAnswers =
          answers.map<int?>(
                (e) {
              if (e is Map) {
                return e[
                "selectedAnswer"] as int?;
              }

              return null;
            },
          ).toList();

      final loadedQuiz =
      await adminService.getQuiz(
        courseId:
        widget.courseId,
        lessonId:
        widget.lessonId,
      );

      if (!mounted) return;

      setState(() {
        quiz = loadedQuiz;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        "QUIZ REVIEW ERROR: $e",
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
            "Failed to load quiz review: $e",
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(
      AppRouter.lessonPath(
        widget.courseId,
        widget.lessonId,
      ),
    );
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

    if (quiz == null) {
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
            "Quiz Review",
          ),
          leading:
          IconButton(
            onPressed: _goBack,
            icon:
            const Icon(
              Icons.arrow_back,
            ),
          ),
        ),
        body: const Center(
          child:
          Text(
            "Quiz data not found",
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
          "Quiz Review",
        ),
        leading:
        IconButton(
          onPressed: _goBack,
          icon:
          const Icon(
            Icons.arrow_back,
          ),
        ),
      ),

      body:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildResultCard(),

            const SizedBox(
              height: 25,
            ),

            const Text(
              "Review Answers",
              style:
              TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff003366),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            ...List.generate(
              quiz!.questions.length,
                  (index) {
                return _questionCard(
                  index,
                  quiz!.questions[
                  index],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESULT
  // ============================================================

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(25),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xffE4E9F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            passed
                ? Icons.check_circle
                : Icons.cancel,
            size: 60,
            color:
            passed
                ? Colors.green
                : Colors.red,
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            passed
                ? "Quiz Passed"
                : "Quiz Failed",
            style:
            TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
              color:
              passed
                  ? Colors.green
                  : Colors.red,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            "$score%",
            style:
            const TextStyle(
              fontSize: 40,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            passed
                ? "Congratulations! You passed this quiz."
                : "You did not reach the required passing score.",
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION
  // ============================================================

  Widget _questionCard(
      int index,
      dynamic question,
      ) {
    final selected =
    index <
        selectedAnswers.length
        ? selectedAnswers[
    index]
        : null;

    final correct =
        question.correctAnswerIndex;

    final bool answeredCorrectly =
        selected == correct;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 20,
      ),
      padding:
      const EdgeInsets.all(22),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xffE4E9F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Question ${index + 1}",
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xff003366),
                  ),
                ),
              ),

              Icon(
                answeredCorrectly
                    ? Icons.check_circle
                    : Icons.cancel,
                color:
                answeredCorrectly
                    ? Colors.green
                    : Colors.red,
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          Text(
            question.question,
            style:
            const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            "Your Answer:",
            style:
            TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            selected == null
                ? "Not answered"
                : question
                .options[selected],
            style:
            TextStyle(
              color:
              answeredCorrectly
                  ? Colors.green
                  : Colors.red,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            "Correct Answer:",
            style:
            TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            question.options[
            correct],
            style:
            const TextStyle(
              color: Colors.green,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}