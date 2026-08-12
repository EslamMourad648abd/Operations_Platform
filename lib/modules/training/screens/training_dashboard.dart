
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../services/course_progress_service.dart';
import '../widgets/course_card.dart';
import '../widgets/training_stat_card.dart';
import 'course_details.dart';
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
  // ============================================================
  // SERVICES
  // ============================================================
  final FirebaseTrainingRepository _repository =
  FirebaseTrainingRepository();
  final CourseProgressService _progressService =
  CourseProgressService();
  // ============================================================
  // STATE
  // ============================================================
  List<CourseModel>? _courses;
  Map<String, Map<String, dynamic>> _progressMap = {};
  bool _loadingCourses = true;
  bool _loadingProgress = true;
  String? _errorMessage;
  // ============================================================
  // INITIAL LOAD
  // ============================================================
  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }
  // ============================================================
  // LOAD COURSES + PROGRESS
  // ============================================================
  Future<void> _loadDashboard() async {
    final user =
        FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _loadingProgress = false;
        _courses = [];
      });
      return;
    }
    try {
      // --------------------------------------------------------
      // LOAD COURSES
      // --------------------------------------------------------
      final courses =
      await _repository.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _loadingCourses = false;
        _loadingProgress = true;
        _errorMessage = null;
      });
      // --------------------------------------------------------
      // LOAD PROGRESS
      // --------------------------------------------------------
      final progressMap =
      await _loadCoursesProgress(
        courses: courses,
        repository: _repository,
        progressService: _progressService,
        userId: user.uid,
      );
      if (!mounted) return;
      setState(() {
        _progressMap = progressMap;
        _loadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _loadingProgress = false;
        _errorMessage =
        "Failed to load training data: $e";
      });
    }
  }
  // ============================================================
  // LOAD COURSE PROGRESS + LESSON INFORMATION
  // ============================================================
  Future<Map<String, Map<String, dynamic>>>
  _loadCoursesProgress({
    required List<CourseModel> courses,
    required FirebaseTrainingRepository repository,
    required CourseProgressService progressService,
    required String userId,
  }) async {
    final Map<String, Map<String, dynamic>>
    progressMap = {};
    for (final course in courses) {
      // --------------------------------------------------------
      // GET LESSONS
      // --------------------------------------------------------
      final lessons =
      await repository.getLessons(
        course.id,
      );
      // --------------------------------------------------------
      // GET LESSON IDS
      // --------------------------------------------------------
      final lessonIds = lessons
          .map((lesson) => lesson.id)
          .toList();
      // --------------------------------------------------------
      // CALCULATE TOTAL COURSE DURATION
      //
      // Lesson duration is stored in seconds.
      // --------------------------------------------------------
      int totalDuration = 0;
      for (final lesson in lessons) {
        totalDuration += lesson.duration;
      }
      // --------------------------------------------------------
      // GET PERSISTED COURSE PROGRESS
      // --------------------------------------------------------
      final courseProgress =
      await progressService.getCourseProgress(
        userId: userId,
        courseId: course.id,
        lessonIds: lessonIds,
      );
      // --------------------------------------------------------
      // CALCULATE COURSE PROGRESS
      //
      // Each lesson:
      //
      // Video completed = 50%
      // Quiz submitted  = 50%
      //
      // Example:
      //
      // 4 lessons
      //
      // 2 videos completed = 100 points
      // 1 quiz submitted   = 50 points
      //
      // Total = 150 / 4 = 37.5%
      // --------------------------------------------------------
      double coursePercentage = 0;
      if (lessons.isNotEmpty) {
        final double totalProgressPoints =
            (courseProgress.completedVideos * 50) +
                (courseProgress.submittedQuizzes * 50);
        coursePercentage =
            totalProgressPoints / lessons.length;
      }
      // --------------------------------------------------------
      // STORE COURSE INFORMATION
      // --------------------------------------------------------
      progressMap[course.id] = {
        "progress": coursePercentage,
        "lessons": lessonIds.length,
        "duration": totalDuration,
      };
    }
    return progressMap;
  }
  // ============================================================
  // REFRESH PROGRESS ONLY
  //
  // IMPORTANT:
  // We do NOT reload the entire page.
  // We keep the existing courses and only fetch their progress.
  // ============================================================
  Future<void> _refreshProgress() async {
    final user =
        FirebaseAuth.instance.currentUser;
    final courses = _courses;
    if (user == null ||
        courses == null ||
        courses.isEmpty) {
      return;
    }
    try {
      final newProgressMap =
      await _loadCoursesProgress(
        courses: courses,
        repository: _repository,
        progressService: _progressService,
        userId: user.uid,
      );
      if (!mounted) return;
      setState(() {
        _progressMap = newProgressMap;
      });
    } catch (e) {
      // --------------------------------------------------------
      // Do not destroy the currently displayed progress if the
      // refresh fails.
      //
      // The existing data remains visible.
      // --------------------------------------------------------
      debugPrint(
        "Failed to refresh course progress: $e",
      );
    }
  }
  // ============================================================
  // COUNT COMPLETED / IN-PROGRESS COURSES
  // ============================================================
  int _countCourses({
    required bool completed,
  }) {
    int count = 0;
    for (final course in _progressMap.values) {
      final double progress =
      (course["progress"] ?? 0).toDouble();
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
  Widget build(BuildContext context) {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------
    if (_loadingCourses) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor:
        const Color(0xffF5F8FC),
        body: Center(
          child: Text(
            _errorMessage!,
          ),
        ),
      );
    }
    // ----------------------------------------------------------
    // COURSES
    // ----------------------------------------------------------
    final courses =
        _courses ?? [];
    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------
    if (courses.isEmpty) {
      return const Scaffold(
        backgroundColor:
        Color(0xffF5F8FC),
        body: Center(
          child: Text(
            "No courses available",
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
            MediaQuery.of(context).size.width >
                1200
                ? 40
                : 20,
            vertical: 30,
          ),
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color:
                        Color(0xff003366),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Text(
                      "Training Portal",
                      style: TextStyle(
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
                  "Improve your skills and track your progress",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                // ==================================================
                // CONTENT
                // ==================================================
                Expanded(
                  child: _loadingProgress
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
                              "Courses",
                              value:
                              "${courses.length}",
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
                              "Completed",
                              value:
                              "${_countCourses(
                                completed: true,
                              )}",
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
                              "In Progress",
                              value:
                              "${_countCourses(
                                completed: false,
                              )}",
                              icon:
                              Icons.timelapse,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      // ==========================================
                      // AVAILABLE COURSES
                      // ==========================================
                      const Align(
                        alignment:
                        Alignment.centerLeft,
                        child: Text(
                          "Available Courses",
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
                      // ==========================================
                      // COURSE GRID
                      // ==========================================
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
                            return GridView.builder(
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
                                final double
                                progress =
                                (data[
                                "progress"] ??
                                    0)
                                    .toDouble();
                                final int
                                lessonsCount =
                                (data[
                                "lessons"] ??
                                    0)
                                as int;
                                final int
                                duration =
                                (data[
                                "duration"] ??
                                    0)
                                as int;
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
                                    // ------------------------------------------------
                                    // OPEN COURSE DETAILS
                                    // ------------------------------------------------
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                            CourseDetails(
                                              course:
                                              course,
                                            ),
                                      ),
                                    );
                                    // ------------------------------------------------
                                    // USER RETURNED FROM COURSE DETAILS
                                    //
                                    // Refresh ONLY the course progress.
                                    //
                                    // No page/browser refresh.
                                    // No reload of the whole dashboard.
                                    // ------------------------------------------------
                                    if (mounted) {
                                      await _refreshProgress();
                                    }
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
    );
  }
}