import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../services/certificate_service.dart';
import '../widgets/lesson_tile.dart';
import '../widgets/progress_bar.dart';

class CourseDetails extends StatefulWidget {
  final CourseModel course;

  const CourseDetails({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetails> createState() =>
      _CourseDetailsState();
}

class _CourseDetailsState
    extends State<CourseDetails>
    with SingleTickerProviderStateMixin {
  final FirebaseTrainingRepository repository =
  FirebaseTrainingRepository();

  final CertificateService certificateService =
  CertificateService();

  double progress = 0;

  bool loadingProgress = true;

  bool openingCertificate = false;

  List<LessonModel> lessons = [];

  Map<String, Map<String, bool>> lessonProgress = {};

  int totalDuration = 0;

  bool _completionStateInitialized = false;

  bool _previousCourseCompleted = false;

  bool _completionCelebrationShown = false;

  late AnimationController _celebrationController;

  late Animation<double> _scaleAnimation;

  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _celebrationController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(milliseconds: 900),
        );

    _scaleAnimation =
        CurvedAnimation(
          parent:
          _celebrationController,
          curve:
          Curves.elasticOut,
        );

    _fadeAnimation =
        CurvedAnimation(
          parent:
          _celebrationController,
          curve:
          Curves.easeOut,
        );

    _loadData();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _formatDuration(
      int seconds,
      ) {
    final minutes =
        seconds ~/ 60;

    final remainingSeconds =
        seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      final loadedLessons =
      await repository.getLessons(
        widget.course.id,
      );

      int calculatedDuration = 0;

      for (final lesson
      in loadedLessons) {
        calculatedDuration +=
            lesson.duration;
      }

      final user =
          FirebaseAuth.instance.currentUser;

      final Map<String, Map<String, bool>>
      progressMap = {};

      double totalLessonProgress = 0;

      bool celebrationShown = false;

      if (user != null) {
        final progressSnapshot =
        await FirebaseFirestore
            .instance
            .collection("users")
            .doc(user.uid)
            .collection("training_progress")
            .doc(widget.course.id)
            .collection("lessons")
            .get(
          const GetOptions(
            source:
            Source.server,
          ),
        );

        final Map<String,
            Map<String, dynamic>>
        firestoreProgress = {};

        for (final doc
        in progressSnapshot.docs) {
          firestoreProgress[doc.id] =
              doc.data();
        }

        for (final lesson
        in loadedLessons) {
          final data =
              firestoreProgress[
              lesson.id] ??
                  {};

          final rawCompleted =
              data["completed"] == true;

          final quizSubmitted =
              data["quizSubmitted"] ==
                  true;

          final videoCompleted =
              data["videoCompleted"] ==
                  true;

          final effectiveCompleted =
          lesson.quizEnabled
              ? rawCompleted
              : (rawCompleted ||
              videoCompleted);

          double lessonProgressValue =
          0;

          if (lesson.quizEnabled) {
            if (videoCompleted) {
              lessonProgressValue +=
              0.5;
            }

            if (quizSubmitted) {
              lessonProgressValue +=
              0.5;
            }

            if (rawCompleted) {
              lessonProgressValue =
              1;
            }
          } else {
            if (effectiveCompleted) {
              lessonProgressValue =
              1;
            }
          }

          totalLessonProgress +=
              lessonProgressValue;

          progressMap[lesson.id] = {
            "completed":
            effectiveCompleted,
            "quizSubmitted":
            lesson.quizEnabled
                ? quizSubmitted
                : false,
            "videoCompleted":
            videoCompleted,
          };
        }

        final courseProgressDoc =
        await FirebaseFirestore
            .instance
            .collection("users")
            .doc(user.uid)
            .collection("training_progress")
            .doc(widget.course.id)
            .get(
          const GetOptions(
            source:
            Source.server,
          ),
        );

        if (courseProgressDoc
            .exists) {
          final data =
          courseProgressDoc
              .data();

          celebrationShown =
              data?[
              "completionCelebrationShown"] ==
                  true;
        }
      }

      final newProgress =
      loadedLessons.isEmpty
          ? 0.0
          : totalLessonProgress /
          loadedLessons.length;

      if (!mounted) return;

      setState(() {
        lessons =
            loadedLessons;

        lessonProgress =
            progressMap;

        totalDuration =
            calculatedDuration;

        progress =
            newProgress;

        loadingProgress =
        false;

        _completionCelebrationShown =
            celebrationShown;
      });

      _checkCompletionTransition();
    } catch (e) {
      debugPrint(
        "COURSE DETAILS ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        loadingProgress = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(
            "Failed to load course data: $e",
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  bool get _courseCompleted {
    if (lessons.isEmpty) {
      return false;
    }

    for (final lesson
    in lessons) {
      final status =
      lessonProgress[lesson.id];

      if (status == null ||
          status["completed"] != true) {
        return false;
      }
    }

    return true;
  }

  void _checkCompletionTransition() {
    if (!mounted) return;

    final currentCompleted =
        _courseCompleted;

    if (!_completionStateInitialized) {
      _completionStateInitialized =
      true;

      _previousCourseCompleted =
          currentCompleted;

      return;
    }

    final justCompleted =
        !_previousCourseCompleted &&
            currentCompleted;

    _previousCourseCompleted =
        currentCompleted;

    if (!justCompleted ||
        _completionCelebrationShown) {
      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) async {
        if (!mounted) return;

        await _markCelebrationShown();

        if (!mounted) return;

        await _showCompletionPopup(
          firstCompletion: true,
        );
      },
    );
  }

  Future<void> _markCelebrationShown() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("training_progress")
          .doc(widget.course.id)
          .set(
        {
          "completionCelebrationShown":
          true,
          "completed": true,
          "completedAt":
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        _completionCelebrationShown =
        true;
      });
    } catch (e) {
      debugPrint(
        "CELEBRATION FLAG ERROR: $e",
      );
    }
  }

  // ============================================================
  // CERTIFICATE
  // ============================================================

  Future<void> _showCompletionPopup({
    required bool firstCompletion,
  }) async {
    if (openingCertificate) {
      return;
    }

    if (firstCompletion) {
      _celebrationController.reset();

      await _celebrationController
          .forward();

      if (!mounted) return;
    }

    setState(() {
      openingCertificate = true;
    });

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) {
          return _CertificateDialog(
            course: widget.course,
            certificateService:
            certificateService,
            firstCompletion:
            firstCompletion,
            scaleAnimation:
            _scaleAnimation,
            fadeAnimation:
            _fadeAnimation,
          );
        },
      );
    } finally {
      if (!mounted) return;

      setState(() {
        openingCertificate = false;
      });
    }
  }

// ============================================================
// OPEN LESSON
// ============================================================

  Future<void> _openLesson(
      LessonModel lesson,
      ) async {
    final path = AppRouter.lessonPath(
      widget.course.id,
      lesson.id,
    );

    debugPrint('================================');
    debugPrint('LESSON ID: ${lesson.id}');
    debugPrint('COURSE ID: ${widget.course.id}');
    debugPrint('LESSON ROUTE: $path');
    debugPrint(
      'CURRENT URL: ${GoRouterState.of(context).uri}',
    );
    debugPrint('================================');

    context.go(path);

    if (!mounted) return;

    // Reload lesson/video/quiz progress after returning
    await _loadData();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xff003366),
        foregroundColor:
        Colors.white,

        leading: IconButton(
          icon:
          const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                AppRouter.training,
              );
            }
          },
        ),

        title:
        Text(widget.course.title),
      ),

      body: loadingProgress
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style:
              const TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              widget.course.description,
              style:
              const TextStyle(
                fontSize: 16,
                color:
                Colors.grey,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            const Text(
              "Course Progress",
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            ProgressBar(
              value: progress,
            ),

            const SizedBox(
              height: 30,
            ),

            if (_courseCompleted)
              _buildCertificateCard(),

            if (_courseCompleted)
              const SizedBox(
                height: 30,
              ),

            Row(
              children: [
                _InfoCard(
                  icon:
                  Icons.menu_book,
                  title:
                  "Lessons",
                  value:
                  lessons.length
                      .toString(),
                ),

                const SizedBox(
                  width: 12,
                ),

                _InfoCard(
                  icon:
                  Icons.timer,
                  title:
                  "Duration",
                  value:
                  _formatDuration(
                    totalDuration,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 35,
            ),

            const Text(
              "Lessons",
              style:
              TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (lessons.isEmpty)
              const Padding(
                padding:
                EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "No lessons available",
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount:
                lessons.length,
                itemBuilder:
                    (
                    context,
                    index,
                    ) {
                  final lesson =
                  lessons[index];

                  final status =
                      lessonProgress[
                      lesson.id] ??
                          {};

                  return LessonTile(
                    lesson: lesson,
                    completed:
                    status[
                    "completed"] ??
                        false,
                    quizSubmitted:
                    lesson.quizEnabled
                        ? (status[
                    "quizSubmitted"] ??
                        false)
                        : false,
                    videoCompleted:
                    status[
                    "videoCompleted"] ??
                        false,
                    onPressed: () {
                      _openLesson(
                        lesson,
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CERTIFICATE CARD
  // ============================================================

  Widget _buildCertificateCard() {
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
          const Color(0xffD7E7F5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.workspace_premium,
                color:
                Color(0xff003366),
                size: 30,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Course Completed!",
                      style:
                      TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xff003366),
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      "Certificate available",
                      style:
                      TextStyle(
                        color:
                        Colors.green,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            "Congratulations! You have successfully "
                "completed all lessons in this course.",
          ),

          const SizedBox(
            height: 18,
          ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child:
            ElevatedButton.icon(
              onPressed:
              openingCertificate
                  ? null
                  : () {
                _showCompletionPopup(
                  firstCompletion:
                  false,
                );
              },
              icon:
              openingCertificate
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons.workspace_premium,
              ),
              label:
              Text(
                openingCertificate
                    ? "Opening Certificate..."
                    : "View Certificate",
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xff003366,
                ),
                foregroundColor:
                Colors.white,
                disabledBackgroundColor:
                Colors.grey,
                disabledForegroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CERTIFICATE DIALOG
// ============================================================

class _CertificateDialog
    extends StatefulWidget {
  final CourseModel course;

  final CertificateService
  certificateService;

  final bool firstCompletion;

  final Animation<double>
  scaleAnimation;

  final Animation<double>
  fadeAnimation;

  const _CertificateDialog({
    required this.course,
    required this.certificateService,
    required this.firstCompletion,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  State<_CertificateDialog>
  createState() =>
      _CertificateDialogState();
}

class _CertificateDialogState
    extends State<_CertificateDialog> {
  String? certificateUrl;

  String? certificateViewType;

  bool generating = true;

  String? error;

  @override
  void initState() {
    super.initState();

    _generateCertificate();
  }

  Future<void> _generateCertificate() async {
    try {
      final url =
      await widget
          .certificateService
          .generateCertificate(
        courseId:
        widget.course.id,
      );

      if (!mounted) return;

      final viewType =
          'certificate-pdf-${DateTime.now().microsecondsSinceEpoch}';

      final iframe =
      html.IFrameElement()
        ..src = url
        ..style.border = '0'
        ..style.outline = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.backgroundColor =
            'white'
        ..allowFullscreen = true;

      ui_web.platformViewRegistry
          .registerViewFactory(
        viewType,
            (int viewId) => iframe,
      );

      setState(() {
        certificateUrl = url;
        certificateViewType =
            viewType;
        generating = false;
      });
    } catch (e) {
      debugPrint(
        "CERTIFICATE POPUP ERROR: $e",
      );

      if (!mounted) return;

      setState(() {
        generating = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 12,
      insetPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(24),
      ),
      child: SizedBox(
        width:
        MediaQuery.of(context)
            .size
            .width
            .clamp(
          320.0,
          1000.0,
        ),
        height:
        MediaQuery.of(context)
            .size
            .height
            .clamp(
          500.0,
          900.0,
        ) *
            0.88,
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                24,
                20,
                16,
                14,
              ),
              child: Row(
                children: [
                  widget.firstCompletion
                      ? FadeTransition(
                    opacity:
                    widget.fadeAnimation,
                    child:
                    ScaleTransition(
                      scale:
                      widget.scaleAnimation,
                      child:
                      _buildHeaderIcon(),
                    ),
                  )
                      : _buildHeaderIcon(),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.firstCompletion
                              ? "Course Completed!"
                              : "Course Completed",
                          style:
                          const TextStyle(
                            fontSize: 23,
                            fontWeight:
                            FontWeight.w700,
                            color:
                            Color(0xff003366),
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          widget.course.title,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    onPressed:
                    generating
                        ? null
                        : () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    icon:
                    const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
            ),

            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  0,
                ),
                child: Column(
                  children: [
                    if (widget.firstCompletion)
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.celebration,
                              size: 20,
                              color:
                              Color(0xff003366),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child:
                              Text(
                                generating
                                    ? "Your certificate is being prepared..."
                                    : "Congratulations! Your certificate is ready.",
                                style:
                                const TextStyle(
                                  fontSize: 14,
                                  color:
                                  Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child:
                      _buildCertificateArea(),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Padding(
                      padding:
                      const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: SizedBox(
                        width:
                        double.infinity,
                        height: 46,
                        child:
                        OutlinedButton(
                          onPressed:
                          generating
                              ? null
                              : () {
                            Navigator.of(
                              context,
                            ).pop();
                          },
                          child:
                          const Text(
                            "Close",
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration:
      const BoxDecoration(
        color:
        Color(0xffEAF4FF),
        shape: BoxShape.circle,
      ),
      child:
      const Icon(
        Icons.workspace_premium,
        size: 32,
        color:
        Color(0xff003366),
      ),
    );
  }

  Widget _buildCertificateArea() {
    if (generating) {
      return Container(
        width: double.infinity,
        decoration:
        BoxDecoration(
          color:
          const Color(0xffF8FBFE),
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color:
            const Color(0xffE2EDF6),
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child:
                CircularProgressIndicator(
                  color:
                  Color(0xff003366),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Preparing your certificate",
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xff003366),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        decoration:
        BoxDecoration(
          color:
          const Color(0xfffff7f7),
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                "Unable to load certificate",
                style:
                TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (certificateUrl != null &&
        certificateViewType != null) {
      return ClipRRect(
        borderRadius:
        BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          child:
          HtmlElementView(
            viewType:
            certificateViewType!,
          ),
        ),
      );
    }

    return const SizedBox();
  }
}

// ============================================================
// INFO CARD
// ============================================================

class _InfoCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(
              height: 8,
            ),
            Text(
              title,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              value,
              style:
              const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}