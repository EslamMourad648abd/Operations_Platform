import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../services/training_progress_service.dart';
import '../widgets/progress_bar.dart';
import '../widgets/lesson_tile.dart';
import 'lesson_screen.dart';
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
    extends State<CourseDetails> {
  final FirebaseTrainingRepository repository =
  FirebaseTrainingRepository();
  final TrainingProgressService progressService =
  TrainingProgressService();
  double progress = 0;
  bool loadingProgress = true;
  List<LessonModel> lessons = [];
  Map<String, Map<String, bool>> lessonProgress = {};
  // Total duration of all lessons in seconds.
  int totalDuration = 0;
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  // ============================================================
  // FORMAT DURATION
  // ============================================================
  //
  // Firebase stores lesson duration as TOTAL SECONDS.
  //
  // Examples:
  // 343 seconds -> 05:43
  // 300 seconds -> 05:00
  // 83 seconds  -> 01:23
  //
  // This method is only for display.
  // The Firebase value itself is NOT modified.
  // ============================================================
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
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
      // ========================================================
      // CALCULATE TOTAL COURSE DURATION
      // ========================================================
      //
      // Each lesson contains its own duration in seconds.
      //
      // Example:
      //
      // Lesson 1 = 343 seconds
      // Lesson 2 = 300 seconds
      // Lesson 3 = 83 seconds
      //
      // Total = 726 seconds = 12:06
      //
      // This makes the course duration dynamic and ensures
      // it always reflects the actual lessons in Firestore.
      // ========================================================
      int calculatedTotalDuration = 0;
      for (final lesson in loadedLessons) {
        calculatedTotalDuration += lesson.duration;
      }
      final user =
          FirebaseAuth.instance.currentUser;
      int completedCount = 0;
      final Map<String, Map<String, bool>>
      progressMap = {};
      if (user != null) {
        for (final lesson in loadedLessons) {
          final completed =
          await progressService.isLessonCompleted(
            userId: user.uid,
            courseId: widget.course.id,
            lessonId: lesson.id,
          );
          final quizSubmitted =
          await progressService.isQuizSubmitted(
            userId: user.uid,
            courseId: widget.course.id,
            lessonId: lesson.id,
          );
          final videoCompleted =
          await progressService.isVideoCompleted(
            userId: user.uid,
            courseId: widget.course.id,
            lessonId: lesson.id,
          );
          if (completed) {
            completedCount++;
          }
          progressMap[lesson.id] = {
            "completed": completed,
            "quizSubmitted": quizSubmitted,
            "videoCompleted": videoCompleted,
          };
        }
      }
      if (!mounted) return;
      setState(() {
        lessons = loadedLessons;
        lessonProgress = progressMap;
        totalDuration =
            calculatedTotalDuration;
        progress = loadedLessons.isEmpty
            ? 0
            : completedCount /
            loadedLessons.length;
        loadingProgress = false;
      });
    } catch (e) {
      debugPrint(
        "COURSE DETAILS LOAD ERROR: $e",
      );
      if (!mounted) return;
      setState(() {
        loadingProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load course data: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ============================================================
  // OPEN LESSON
  // ============================================================
  Future<void> _openLesson(
      LessonModel lesson,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
        ),
      ),
    );
    // Reload progress and lesson data after
    // returning from the lesson screen.
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
      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        title: Text(
          widget.course.title,
        ),
        elevation: 0,
      ),
      // ========================================================
      // BODY
      // ========================================================
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
            // ==================================================
            // COURSE TITLE
            // ==================================================
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
            // ==================================================
            // COURSE DESCRIPTION
            // ==================================================
            Text(
              widget.course.description,
              style:
              const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 25,
            ),
            // ==================================================
            // COURSE PROGRESS
            // ==================================================
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
            // ==================================================
            // COURSE INFORMATION
            // ==================================================
            Row(
              children: [
                // =============================================
                // LESSONS COUNT
                // =============================================
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
                // =============================================
                // COURSE DURATION
                // =============================================
                //
                // IMPORTANT:
                //
                // This is calculated from the actual lessons:
                //
                // lesson.duration + lesson.duration + ...
                //
                // The value is stored/displayed as HH:MM style
                // through _formatDuration().
                //
                // widget.course.duration is intentionally NOT
                // used here.
                // =============================================
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
            // ==================================================
            // LESSONS TITLE
            // ==================================================
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
            // ==================================================
            // EMPTY LESSONS
            // ==================================================
            if (lessons.isEmpty)
              const Center(
                child: Padding(
                  padding:
                  EdgeInsets.all(30),
                  child: Text(
                    "No lessons available",
                  ),
                ),
              )
            // ==================================================
            // LESSON LIST
            // ==================================================
            else
              ListView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                itemCount:
                lessons.length,
                itemBuilder:
                    (context, index) {
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
                    status[
                    "quizSubmitted"] ??
                        false,
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
            // ======================================================
            // ICON
            // ======================================================
            Icon(icon),
            const SizedBox(
              height: 8,
            ),
            // ======================================================
            // TITLE
            // ======================================================
            Text(
              title,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            // ======================================================
            // VALUE
            // ======================================================
            Text(
              value,
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
    );
  }
}