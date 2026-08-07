import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../services/course_progress_service.dart';
import '../widgets/course_card.dart';
import '../widgets/training_stat_card.dart';
import 'course_details.dart';
class TrainingDashboard extends StatelessWidget {
  const TrainingDashboard({
    super.key,
  });
  // ============================================================
  // LOAD COURSE PROGRESS + LESSON INFORMATION
  // ============================================================
  Future<Map<String, Map<String, dynamic>>> _loadCoursesProgress({
    required List<CourseModel> courses,
    required FirebaseTrainingRepository repository,
    required CourseProgressService progressService,
    required String userId,
  }) async {
    final Map<String, Map<String, dynamic>> progressMap = {};
    for (final course in courses) {
      // --------------------------------------------------------
      // Get the actual lessons belonging to this course
      // --------------------------------------------------------
      final lessons = await repository.getLessons(
        course.id,
      );
      // --------------------------------------------------------
      // Get lesson IDs
      // --------------------------------------------------------
      final lessonIds = lessons
          .map((lesson) => lesson.id)
          .toList();
      // --------------------------------------------------------
      // Calculate total course duration
      //
      // Lesson duration is stored internally as seconds.
      //
      // Example:
      // 117 seconds = 1:57
      // 60 seconds  = 1:00
      // --------------------------------------------------------
      int totalDuration = 0;
      for (final lesson in lessons) {
        totalDuration += lesson.duration;
      }
      // --------------------------------------------------------
      // Get user progress using ONLY existing lesson IDs
      // --------------------------------------------------------
      final progress = await progressService.getCourseProgress(
        userId: userId,
        courseId: course.id,
        lessonIds: lessonIds,
      );
      // --------------------------------------------------------
      // Store all calculated course information
      // --------------------------------------------------------
      progressMap[course.id] = {
        "progress": progress.progressPercentage,
        "lessons": lessonIds.length,
        "duration": totalDuration,
      };
    }
    return progressMap;
  }
  // ============================================================
  // COUNT COMPLETED / IN-PROGRESS COURSES
  // ============================================================
  Future<int> _countCourses({
    required Map<String, Map<String, dynamic>> progressMap,
    required bool completed,
  }) async {
    int count = 0;
    for (final course in progressMap.values) {
      final double progress =
      (course["progress"] ?? 0).toDouble();
      if (completed) {
        if (progress >= 100) {
          count++;
        }
      } else {
        if (progress > 0 && progress < 100) {
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
    final repository = FirebaseTrainingRepository();
    final progressService = CourseProgressService();
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xffF5F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
            MediaQuery.of(context).size.width > 1200
                ? 40
                : 20,
            vertical: 30,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1600,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xff003366),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Training Portal",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff003366),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Improve your skills and track your progress",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                // ==================================================
                // COURSES
                // ==================================================
                Expanded(
                  child: FutureBuilder<List<CourseModel>>(
                    future: repository.getCourses(),
                    builder: (context, snapshot) {
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      // ------------------------------------------------
                      // ERROR
                      // ------------------------------------------------
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Failed to load courses: ${snapshot.error}",
                          ),
                        );
                      }
                      // ------------------------------------------------
                      // EMPTY
                      // ------------------------------------------------
                      if (!snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            "No courses available",
                          ),
                        );
                      }
                      final courses = snapshot.data!;
                      // ------------------------------------------------
                      // LOAD PROGRESS
                      // ------------------------------------------------
                      return FutureBuilder<
                          Map<String, Map<String, dynamic>>>(
                        future: user == null
                            ? Future.value({})
                            : _loadCoursesProgress(
                          courses: courses,
                          repository: repository,
                          progressService:
                          progressService,
                          userId: user.uid,
                        ),
                        builder:
                            (context, progressSnapshot) {
                          // ------------------------------------------------
                          // PROGRESS LOADING
                          // ------------------------------------------------
                          if (progressSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child:
                              CircularProgressIndicator(),
                            );
                          }
                          // ------------------------------------------------
                          // PROGRESS ERROR
                          // ------------------------------------------------
                          if (progressSnapshot.hasError) {
                            return Center(
                              child: Text(
                                "Failed to load training progress: "
                                    "${progressSnapshot.error}",
                              ),
                            );
                          }
                          final progressMap =
                              progressSnapshot.data ?? {};
                          // ------------------------------------------------
                          // DASHBOARD CONTENT
                          // ------------------------------------------------
                          return Column(
                            children: [
                              // ==========================================
                              // STAT CARDS
                              // ==========================================
                              Row(
                                children: [
                                  Expanded(
                                    child: TrainingStatCard(
                                      title: "Courses",
                                      value:
                                      "${courses.length}",
                                      icon:
                                      Icons.menu_book,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: FutureBuilder<int>(
                                      future: _countCourses(
                                        progressMap:
                                        progressMap,
                                        completed: true,
                                      ),
                                      builder:
                                          (context, snapshot) {
                                        return TrainingStatCard(
                                          title: "Completed",
                                          value:
                                          "${snapshot.data ?? 0}",
                                          icon:
                                          Icons.check_circle,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: FutureBuilder<int>(
                                      future: _countCourses(
                                        progressMap:
                                        progressMap,
                                        completed: false,
                                      ),
                                      builder:
                                          (context, snapshot) {
                                        return TrainingStatCard(
                                          title: "In Progress",
                                          value:
                                          "${snapshot.data ?? 0}",
                                          icon:
                                          Icons.timelapse,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 35),
                              // ==========================================
                              // AVAILABLE COURSES
                              // ==========================================
                              const Align(
                                alignment:
                                Alignment.centerLeft,
                                child: Text(
                                  "Available Courses",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // ==========================================
                              // COURSE GRID
                              // ==========================================
                              Expanded(
                                child: LayoutBuilder(
                                  builder:
                                      (context, constraints) {
                                    int columns;
                                    if (constraints.maxWidth >=
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
                                          (context, index) {
                                        final course =
                                        courses[index];
                                        final data =
                                            progressMap[
                                            course.id] ??
                                                {};
                                        final double progress =
                                        (data["progress"] ??
                                            0)
                                            .toDouble();
                                        final int lessonsCount =
                                        (data["lessons"] ??
                                            0)
                                        as int;
                                        final int duration =
                                        (data["duration"] ??
                                            0)
                                        as int;
                                        return CourseCard(
                                          course: course,
                                          progress: progress,
                                          lessonsCount:
                                          lessonsCount,
                                          duration: duration,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CourseDetails(
                                                      course:
                                                      course,
                                                    ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
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