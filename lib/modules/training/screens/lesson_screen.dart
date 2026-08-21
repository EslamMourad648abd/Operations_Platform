import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../models/lesson_model.dart';
import '../services/training_progress_service.dart';
import '../widgets/google_drive_player.dart';

class LessonScreen extends StatefulWidget {
  final LessonModel lesson;

  const LessonScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonScreen> createState() =>
      _LessonScreenState();
}

class _LessonScreenState
    extends State<LessonScreen> {
  final TrainingProgressService
  progressService =
  TrainingProgressService();

  bool lessonCompleted = false;

  bool loadingProgress = true;

  bool quizSubmitted = false;

  bool videoCompleted = false;

  bool processingAction = false;

  bool get quizEnabled =>
      widget.lesson.quizEnabled;

  @override
  void initState() {
    super.initState();

    _loadProgress();
  }

  // ============================================================
  // LOAD PROGRESS
  // ============================================================

  Future<void> _loadProgress() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        loadingProgress = false;
      });

      return;
    }

    try {
      final completed =
      await progressService
          .isLessonCompleted(
        userId: user.uid,
        courseId:
        widget.lesson.courseId,
        lessonId:
        widget.lesson.id,
      );

      final submitted =
      await progressService
          .isQuizSubmitted(
        userId: user.uid,
        courseId:
        widget.lesson.courseId,
        lessonId:
        widget.lesson.id,
      );

      final video =
      await progressService
          .isVideoCompleted(
        userId: user.uid,
        courseId:
        widget.lesson.courseId,
        lessonId:
        widget.lesson.id,
      );

      final effectiveCompleted =
      quizEnabled
          ? completed
          : (completed || video);

      if (!quizEnabled &&
          video &&
          !completed) {
        try {
          await progressService
              .completeLesson(
            userId: user.uid,
            courseId:
            widget.lesson.courseId,
            lessonId:
            widget.lesson.id,
          );
        } catch (e) {
          debugPrint(
            "LESSON COMPLETION SYNC ERROR: $e",
          );
        }
      }

      if (!mounted) return;

      setState(() {
        videoCompleted = video;
        lessonCompleted =
            effectiveCompleted;
        quizSubmitted =
            quizEnabled && submitted;
        loadingProgress = false;
      });
    } catch (e) {
      debugPrint(
        "LESSON PROGRESS ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loadingProgress = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load lesson progress: $e",
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    }
  }

// ============================================================
// COMPLETE LESSON / VIDEO
// ============================================================

  Future<void> _completeLesson() async {
    if (processingAction) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      processingAction = true;
    });

    try {
      // --------------------------------------------------------
      // VIDEO
      // --------------------------------------------------------

      if (!videoCompleted) {
        await progressService.completeVideo(
          userId: user.uid,
          courseId: widget.lesson.courseId,
          lessonId: widget.lesson.id,
        );

        if (!mounted) return;

        setState(() {
          videoCompleted = true;
        });
      }

      // --------------------------------------------------------
      // QUIZ ENABLED
      // --------------------------------------------------------

      if (quizEnabled) {
        if (!mounted) return;

        final quizPath = AppRouter.quizPath(
          widget.lesson.courseId,
          widget.lesson.id,
        );

        debugPrint('================================');
        debugPrint('OPENING QUIZ');
        debugPrint(
          'COURSE ID: ${widget.lesson.courseId}',
        );
        debugPrint(
          'LESSON ID: ${widget.lesson.id}',
        );
        debugPrint(
          'QUIZ ROUTE: $quizPath',
        );
        debugPrint(
          'CURRENT URL: '
              '${GoRouterState.of(context).uri}',
        );
        debugPrint('================================');

        setState(() {
          processingAction = false;
        });

         context.go(quizPath);

        if (!mounted) return;

        // Reload the lesson state after returning
        await _loadProgress();

        return;
      }

      // --------------------------------------------------------
      // QUIZ DISABLED
      // --------------------------------------------------------

      await progressService.completeLesson(
        userId: user.uid,
        courseId: widget.lesson.courseId,
        lessonId: widget.lesson.id,
      );

      if (!mounted) return;

      await _loadProgress();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Lesson completed successfully",
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        "COMPLETE LESSON ERROR: $e",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update lesson: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          processingAction = false;
        });
      }
    }
  }

// ============================================================
// REVIEW QUIZ
// ============================================================

  Future<void> _reviewQuiz() async {
    if (!quizEnabled || !quizSubmitted) {
      return;
    }

    final reviewPath = AppRouter.quizReviewPath(
      widget.lesson.courseId,
      widget.lesson.id,
    );

    debugPrint('================================');
    debugPrint('OPENING QUIZ REVIEW');
    debugPrint(
      'COURSE ID: ${widget.lesson.courseId}',
    );
    debugPrint(
      'LESSON ID: ${widget.lesson.id}',
    );
    debugPrint(
      'QUIZ REVIEW ROUTE: $reviewPath',
    );
    debugPrint(
      'CURRENT URL: '
          '${GoRouterState.of(context).uri}',
    );
    debugPrint('================================');

    context.go(reviewPath);

    if (!mounted) return;

    await _loadProgress();
  }

// ============================================================
// BACK
// ============================================================

  void _goBack() {
    debugPrint('================================');
    debugPrint('LESSON BACK');
    debugPrint(
      'CURRENT URL: '
          '${GoRouterState.of(context).uri}',
    );
    debugPrint('================================');

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go(
      AppRouter.coursePath(
        widget.lesson.courseId,
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
    final lesson =
        widget.lesson;

    double lessonProgress = 0;

    String progressText;

    if (lessonCompleted) {
      lessonProgress = 1;
      progressText = "Completed";
    } else if (!quizEnabled) {
      if (videoCompleted) {
        lessonProgress = 1;
        progressText = "Completed";
      } else {
        lessonProgress = 0;
        progressText =
        "Not completed yet";
      }
    } else if (videoCompleted) {
      lessonProgress = 0.5;
      progressText =
      "Video completed - Quiz pending";
    } else {
      lessonProgress = 0;
      progressText =
      "Not completed yet";
    }

    String buttonText;
    IconData buttonIcon;
    VoidCallback? buttonAction;

    if (lessonCompleted) {
      if (quizEnabled &&
          quizSubmitted) {
        buttonText = "Review Quiz";
        buttonIcon =
            Icons.visibility;
        buttonAction =
            _reviewQuiz;
      } else {
        buttonText =
        "Lesson Completed";
        buttonIcon =
            Icons.check_circle;
        buttonAction = null;
      }
    } else if (!videoCompleted) {
      buttonText = quizEnabled
          ? "Complete Video & Take Quiz"
          : "Complete Video";

      buttonIcon =
          Icons.play_arrow;

      buttonAction =
          _completeLesson;
    } else if (quizEnabled) {
      buttonText = "Take Quiz";
      buttonIcon = Icons.quiz;
      buttonAction =
          _completeLesson;
    } else {
      buttonText = "Complete Lesson";
      buttonIcon = Icons.check;
      buttonAction =
          _completeLesson;
    }

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff003366),
        foregroundColor:
        Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: _goBack,
          icon:
          const Icon(
            Icons.arrow_back,
          ),
        ),

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              "Training Portal",
              style:
              TextStyle(
                fontSize: 12,
                color:
                Colors.white70,
              ),
            ),
            Text(
              lesson.title,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
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
            // ==================================================
            // VIDEO / URL CONTENT
            // ==================================================

            Center(
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(
                  maxWidth: 1100,
                ),
                child: Container(
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                    child:
                    GoogleDrivePlayer(
                      videoUrl:
                      lesson.videoUrl,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // URL INFORMATION
            // ==================================================

            if (lesson.videoUrl
                .trim()
                .isNotEmpty)
              _buildUrlCard(
                lesson.videoUrl,
              ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // COMPLETION
            // ==================================================

            _buildCard(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lesson Completion",
                    style:
                    TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xff003366),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (loadingProgress)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      height: 46,
                      child:
                      ElevatedButton.icon(
                        onPressed:
                        processingAction
                            ? null
                            : buttonAction,
                        icon:
                        processingAction
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
                            : Icon(
                          buttonIcon,
                        ),
                        label:
                        Text(
                          processingAction
                              ? "Updating..."
                              : buttonText,
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xff003366,
                          ),
                          foregroundColor:
                          Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // PROGRESS
            // ==================================================

            _buildCard(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lesson Progress",
                    style:
                    TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xff003366),
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  LinearProgressIndicator(
                    value:
                    lessonProgress,
                    minHeight: 8,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    progressText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // URL CARD
  // ============================================================

  Widget _buildUrlCard(
      String url,
      ) {
    return _buildCard(
      child: Row(
        children: [
          const Icon(
            Icons.link,
            color:
            Color(0xff003366),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              url,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}