import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_training_analytics_model.dart';

class TrainingAnalyticsService {
  final FirebaseFirestore firestore;

  TrainingAnalyticsService({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  // ============================================================
  // GET ALL TRAINEE ANALYTICS
  // ============================================================

  Future<List<AgentTrainingAnalyticsModel>>
  getAllTraineeAnalytics() async {
    // ----------------------------------------------------------
    // GET TRAINEES
    // ----------------------------------------------------------

    final usersSnapshot = await firestore
        .collection("users")
        .where(
      "role",
      isEqualTo: "trainee",
    )
        .get();

    // ----------------------------------------------------------
    // GET ALL TRAINING COURSES
    // ----------------------------------------------------------

    final coursesSnapshot = await firestore
        .collection("training_courses")
        .get();

    // ----------------------------------------------------------
    // CACHE COURSE INFORMATION
    // ----------------------------------------------------------

    final Map<String, String> courseNames = {};

    final Map<String, List<String>> courseLessonIds = {};

    for (final courseDoc in coursesSnapshot.docs) {
      final courseId = courseDoc.id;

      final courseData = courseDoc.data();

      courseNames[courseId] =
          courseData["title"]?.toString() ?? courseId;

      // --------------------------------------------------------
      // GET ACTUAL COURSE LESSONS
      // --------------------------------------------------------

      final lessonsSnapshot = await firestore
          .collection("training_courses")
          .doc(courseId)
          .collection("lessons")
          .get();

      courseLessonIds[courseId] = lessonsSnapshot.docs
          .map(
            (lessonDoc) => lessonDoc.id,
      )
          .toList();
    }

    // ----------------------------------------------------------
    // FINAL ANALYTICS
    // ----------------------------------------------------------

    final List<AgentTrainingAnalyticsModel> analytics = [];

    // ==========================================================
    // EACH TRAINEE
    // ==========================================================

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;

      final userData = userDoc.data();

      final userName =
      (userData["displayName"] != null &&
          userData["displayName"]
              .toString()
              .trim()
              .isNotEmpty)
          ? userData["displayName"].toString()
          : userData["email"]?.toString() ?? "Unknown";

      // --------------------------------------------------------
      // COURSE ANALYTICS
      // --------------------------------------------------------

      final List<CourseAnalyticsModel> userCourses = [];

      double totalProgress = 0;

      // --------------------------------------------------------
      // GLOBAL QUIZ TOTALS
      //
      // These are based on individual submitted quizzes.
      // --------------------------------------------------------

      int totalQuizScore = 0;

      int totalSubmittedQuizzes = 0;

      int completedCourses = 0;

      // ========================================================
      // CHECK EACH REAL COURSE
      // ========================================================

      for (final courseDoc in coursesSnapshot.docs) {
        final courseId = courseDoc.id;

        final List<String> actualLessonIds =
            courseLessonIds[courseId] ?? [];

        // ------------------------------------------------------
        // Ignore courses that contain no lessons.
        // ------------------------------------------------------

        if (actualLessonIds.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // GET TRAINEE LESSON PROGRESS DIRECTLY
        //
        // IMPORTANT:
        //
        // We intentionally do NOT query:
        //
        // training_progress/{courseId}
        //
        // because your Firestore structure can have the
        // "lessons" subcollection without the parent document.
        // ------------------------------------------------------

        final progressLessonsSnapshot = await firestore
            .collection("users")
            .doc(userId)
            .collection("training_progress")
            .doc(courseId)
            .collection("lessons")
            .get();

        // ------------------------------------------------------
        // If trainee has no progress for this course,
        // don't show the course in their analytics yet.
        // ------------------------------------------------------

        if (progressLessonsSnapshot.docs.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // SET OF ACTUAL COURSE LESSON IDS
        // ------------------------------------------------------

        final Set<String> actualLessonIdSet =
        actualLessonIds.toSet();

        int completedLessons = 0;

        int courseTotalQuizScore = 0;

        int courseQuizCount = 0;

        DateTime? latestCompletionDate;

        // ======================================================
        // PROCESS TRAINEE LESSON PROGRESS
        // ======================================================

        for (final lessonProgressDoc
        in progressLessonsSnapshot.docs) {
          final lessonId = lessonProgressDoc.id;

          // ----------------------------------------------------
          // Only process lessons that actually belong to
          // the current course.
          // ----------------------------------------------------

          if (!actualLessonIdSet.contains(lessonId)) {
            continue;
          }

          final data = lessonProgressDoc.data();

          // ----------------------------------------------------
          // LESSON COMPLETION
          // ----------------------------------------------------

          if (data["completed"] == true) {
            completedLessons++;

            final completedAt =
            data["completedAt"];

            if (completedAt is Timestamp) {
              final date = completedAt.toDate();

              if (latestCompletionDate == null ||
                  date.isAfter(latestCompletionDate!)) {
                latestCompletionDate = date;
              }
            }
          }

          // ----------------------------------------------------
          // QUIZ
          // ----------------------------------------------------

          if (data["quizSubmitted"] == true) {
            final num score =
                (data["score"] as num?) ?? 0;

            final int scoreValue = score.toInt();

            courseTotalQuizScore += scoreValue;

            courseQuizCount++;

            // --------------------------------------------------
            // IMPORTANT:
            //
            // Add individual quiz scores to the global total.
            //
            // We DO NOT add the course average here.
            // --------------------------------------------------

            totalQuizScore += scoreValue;

            totalSubmittedQuizzes++;
          }
        }

        // --------------------------------------------------------
        // TOTAL LESSONS
        // --------------------------------------------------------

        final int totalLessons =
            actualLessonIds.length;

        // --------------------------------------------------------
        // COURSE PROGRESS
        // --------------------------------------------------------

        final double progress =
        totalLessons == 0
            ? 0
            : (completedLessons / totalLessons) * 100;

        // --------------------------------------------------------
        // COURSE QUIZ AVERAGE
        // --------------------------------------------------------

        final double quizScore =
        courseQuizCount == 0
            ? 0
            : courseTotalQuizScore /
            courseQuizCount;

        // --------------------------------------------------------
        // COURSE COMPLETION
        // --------------------------------------------------------

        final bool completed =
            totalLessons > 0 &&
                completedLessons >= totalLessons;

        if (completed) {
          completedCourses++;
        }

        totalProgress += progress;

        // ========================================================
        // CERTIFICATE
        // ========================================================

        final String certificateId =
            "${userId}_$courseId";

        final certificateSnapshot =
        await firestore
            .collection("certificates")
            .doc(certificateId)
            .get();

        bool certificateIssued = false;

        String? certificateUrl;

        DateTime? certificateIssuedAt;

        if (certificateSnapshot.exists) {
          final certificateData =
          certificateSnapshot.data();

          certificateIssued = true;

          // ------------------------------------------------------
          // CERTIFICATE URL
          // ------------------------------------------------------

          certificateUrl =
              certificateData?["certificateUrl"]
                  ?.toString();

          // ------------------------------------------------------
          // CERTIFICATE ISSUED DATE
          // ------------------------------------------------------

          final issuedAt =
          certificateData?["issuedAt"];

          if (issuedAt is Timestamp) {
            certificateIssuedAt =
                issuedAt.toDate();
          }

          // ------------------------------------------------------
          // NOTE:
          //
          // The certificate document remains the source of truth
          // for whether a certificate has already been issued.
          // ------------------------------------------------------
        }

        // ========================================================
        // COURSE ANALYTICS
        // ========================================================

        userCourses.add(
          CourseAnalyticsModel(
            courseId: courseId,
            courseName:
            courseNames[courseId] ?? courseId,
            totalLessons: totalLessons,
            completedLessons:
            completedLessons,
            progress: progress,
            quizScore: quizScore,
            completed: completed,
            certificateIssued:
            certificateIssued,
            certificateUrl:
            certificateUrl,
            certificateIssuedAt:
            certificateIssuedAt,
          ),
        );
      }

      // ==========================================================
      // TOTAL COURSES
      // ==========================================================

      final int totalCourses =
          userCourses.length;

      // ==========================================================
      // OVERALL PROGRESS
      // ==========================================================

      final double overallProgress =
      totalCourses == 0
          ? 0
          : totalProgress / totalCourses;

      // ==========================================================
      // OVERALL QUIZ SCORE
      //
      // Example:
      //
      // Course A:
      // 100, 80, 90
      //
      // Course B:
      // 60
      //
      // Result:
      //
      // (100 + 80 + 90 + 60) / 4 = 82.5%
      //
      // A course with no submitted quizzes does NOT contribute
      // a zero to the average.
      // ==========================================================

      final double averageQuizScore =
      totalSubmittedQuizzes == 0
          ? 0
          : totalQuizScore /
          totalSubmittedQuizzes;

      // ==========================================================
      // TRAINEE ANALYTICS MODEL
      // ==========================================================

      analytics.add(
        AgentTrainingAnalyticsModel(
          userId: userId,
          userName: userName,
          totalCourses: totalCourses,
          completedCourses:
          completedCourses,
          overallProgress:
          overallProgress,
          averageQuizScore:
          averageQuizScore,
          courses: userCourses,
        ),
      );
    }

    return analytics;
  }
}