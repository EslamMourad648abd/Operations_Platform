import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';
import '../models/course_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../widgets/course_card.dart';
import '../widgets/training_stat_card.dart';

class TrainingDashboard extends StatefulWidget {
  const TrainingDashboard({
    super.key,
  });

  @override
  State<TrainingDashboard> createState() =>
      _TrainingDashboardState();
}

class _TrainingDashboardState
    extends State<TrainingDashboard> {
  final FirebaseTrainingRepository
  _repository =
  FirebaseTrainingRepository();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  List<CourseModel>? _courses;

  Map<String, Map<String, dynamic>>
  _progressMap = {};

  bool _loadingCourses = true;
  bool _loadingProgress = true;

  String? _errorMessage;

  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();

    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> _loadDashboard() async {
    final generation =
    ++_loadGeneration;

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loadingCourses = false;
        _loadingProgress = false;
        _courses = [];
        _progressMap = {};
      });

      return;
    }

    try {
      final courses =
      await _repository.getCourses();

      if (!mounted ||
          generation != _loadGeneration) {
        return;
      }

      setState(() {
        _courses = courses;
        _loadingCourses = false;
        _loadingProgress = true;
        _errorMessage = null;
      });

      final progress =
      await _loadCoursesProgress(
        courses: courses,
        userId: user.uid,
      );

      if (!mounted ||
          generation != _loadGeneration) {
        return;
      }

      setState(() {
        _progressMap = progress;
        _loadingProgress = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        'TrainingDashboard error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted ||
          generation != _loadGeneration) {
        return;
      }

      setState(() {
        _loadingCourses = false;
        _loadingProgress = false;
        _errorMessage =
        'Failed to load training data: $e';
      });
    }
  }

  // ============================================================
  // LOAD ALL COURSE PROGRESS
  // ============================================================

  Future<Map<String, Map<String, dynamic>>>
  _loadCoursesProgress({
    required List<CourseModel> courses,
    required String userId,
  }) async {
    if (courses.isEmpty) {
      return {};
    }

    final results =
    await Future.wait(
      courses.map(
            (course) async {
          try {
            return MapEntry(
              course.id,
              await _loadSingleCourseProgress(
                course: course,
                userId: userId,
              ),
            );
          } catch (e) {
            debugPrint(
              'Progress error ${course.id}: $e',
            );

            return MapEntry(
              course.id,
              {
                'progress': 0.0,
                'lessons': 0,
                'duration': 0,
              },
            );
          }
        },
      ),
    );

    return Map.fromEntries(
      results,
    );
  }

  // ============================================================
  // LOAD ONE COURSE
  // ============================================================

  Future<Map<String, dynamic>>
  _loadSingleCourseProgress({
    required CourseModel course,
    required String userId,
  }) async {
    final lessons =
    await _repository.getLessons(
      course.id,
    );

    final totalDuration =
    lessons.fold<int>(
      0,
          (
          total,
          lesson,
          ) =>
      total + lesson.duration,
    );

    if (lessons.isEmpty) {
      return {
        'progress': 0.0,
        'lessons': 0,
        'duration': totalDuration,
      };
    }

    final snapshot =
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('training_progress')
        .doc(course.id)
        .collection('lessons')
        .get(
      const GetOptions(
        source: Source.server,
      ),
    );

    final Map<String, Map<String, dynamic>>
    progressByLesson = {};

    for (final doc
    in snapshot.docs) {
      progressByLesson[doc.id] =
          doc.data();
    }

    double totalProgress = 0;

    for (final lesson in lessons) {
      final data =
          progressByLesson[lesson.id] ??
              {};

      final completed =
          data['completed'] == true;

      final videoCompleted =
          data['videoCompleted'] == true;

      final quizSubmitted =
          data['quizSubmitted'] == true;

      double lessonProgress = 0;

      if (lesson.quizEnabled) {
        if (videoCompleted) {
          lessonProgress += 0.5;
        }

        if (quizSubmitted) {
          lessonProgress += 0.5;
        }

        if (completed) {
          lessonProgress = 1;
        }
      } else {
        if (completed ||
            videoCompleted) {
          lessonProgress = 1;
        }
      }

      totalProgress +=
          lessonProgress;
    }

    final percentage =
        (totalProgress /
            lessons.length) *
            100;

    return {
      'progress': percentage,
      'lessons': lessons.length,
      'duration': totalDuration,
    };
  }

  // ============================================================
  // REFRESH ONE COURSE
  // ============================================================

  Future<void> _refreshCourseProgress(
      CourseModel course,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final data =
      await _loadSingleCourseProgress(
        course: course,
        userId: user.uid,
      );

      if (!mounted) return;

      setState(() {
        _progressMap[course.id] =
            data;
      });
    } catch (e) {
      debugPrint(
        'Course progress refresh error: $e',
      );
    }
  }

  // ============================================================
  // COUNT COURSES
  // ============================================================

  int _countCourses({
    required bool completed,
  }) {
    int count = 0;

    for (final course
    in _progressMap.values) {
      final progress =
      (course['progress'] ?? 0)
          .toDouble();

      if (completed) {
        if (progress >= 100) {
          count++;
        }
      } else {
        if (progress > 0 &&
            progress < 100) {
          count++;
        }
      }
    }

    return count;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loadingCourses) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child:
          CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor:
        const Color(0xffF5F8FC),
        body: Center(
          child: Padding(
            padding:
            const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  _errorMessage!,
                  textAlign:
                  TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed:
                  _loadDashboard,
                  child:
                  const Text(
                    'Retry',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final courses =
        _courses ?? [];

    if (courses.isEmpty) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child:
          Text(
            'No courses available',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),
      body: SafeArea(
        child: Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal:
            MediaQuery.of(context)
                .size
                .width >
                1200
                ? 40
                : 20,
            vertical: 30,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 1600,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================

                  Row(
                    children: [
                      IconButton(
                        padding:
                        EdgeInsets.zero,
                        constraints:
                        const BoxConstraints(),
                        icon:
                        const Icon(
                          Icons.arrow_back,
                          color:
                          Color(0xff003366),
                          size: 28,
                        ),
                        onPressed: () {
                          context.go(
                            AppRouter.home,
                          );
                        },
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Text(
                        'Training Portal',
                        style:
                        TextStyle(
                          fontSize: 34,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Color(0xff003366),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Improve your skills and track your progress',
                    style:
                    TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  Expanded(
                    child:
                    _loadingProgress
                        ? const Center(
                      child:
                      CircularProgressIndicator(),
                    )
                        : Column(
                      children: [
                        // ==========================================
                        // STAT CARDS
                        // ==========================================

                        Row(
                          children: [
                            Expanded(
                              child:
                              TrainingStatCard(
                                title:
                                'Courses',
                                value:
                                '${courses.length}',
                                icon:
                                Icons.menu_book,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child:
                              TrainingStatCard(
                                title:
                                'Completed',
                                value:
                                '${_countCourses(completed: true)}',
                                icon:
                                Icons.check_circle,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child:
                              TrainingStatCard(
                                title:
                                'In Progress',
                                value:
                                '${_countCourses(completed: false)}',
                                icon:
                                Icons.timelapse,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 35,
                        ),

                        const Align(
                          alignment:
                          Alignment.centerLeft,
                          child:
                          Text(
                            'Available Courses',
                            style:
                            TextStyle(
                              fontSize: 24,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        Expanded(
                          child:
                          LayoutBuilder(
                            builder:
                                (
                                context,
                                constraints,
                                ) {
                              int columns;

                              if (constraints
                                  .maxWidth >=
                                  1400) {
                                columns = 3;
                              } else if (constraints
                                  .maxWidth >=
                                  900) {
                                columns = 2;
                              } else {
                                columns = 1;
                              }

                              return GridView
                                  .builder(
                                physics:
                                const BouncingScrollPhysics(),

                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                  columns,
                                  crossAxisSpacing:
                                  25,
                                  mainAxisSpacing:
                                  25,
                                  mainAxisExtent:
                                  400,
                                ),

                                itemCount:
                                courses.length,

                                itemBuilder:
                                    (
                                    context,
                                    index,
                                    ) {
                                  final course =
                                  courses[index];

                                  final data =
                                      _progressMap[
                                      course.id] ??
                                          {};

                                  final progress =
                                  (data['progress'] ??
                                      0)
                                      .toDouble();

                                  final lessonsCount =
                                  (data['lessons'] ??
                                      0) as int;

                                  final duration =
                                  (data['duration'] ??
                                      0) as int;

                                  return CourseCard(
                                    course:
                                    course,
                                    progress:
                                    progress,
                                    lessonsCount:
                                    lessonsCount,
                                    duration:
                                    duration,
                                    onPressed:
                                        () async {
                                          final path = AppRouter.coursePath(course.id);

                                          debugPrint('================================');
                                          debugPrint('COURSE ID: ${course.id}');
                                          debugPrint('COURSE ROUTE: $path');
                                          debugPrint(
                                            'CURRENT URL: ${GoRouterState.of(context).uri}',
                                          );
                                          debugPrint('================================');

                                          context.go(path);
                                        },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}