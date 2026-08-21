import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../platform/dashboard.dart';
import '../modules/login.dart';
import '../modules/bbc_api.dart';
import '../modules/training/screens/training_dashboard.dart';
import '../modules/training/screens/course_details.dart';
import '../modules/training/screens/lesson_screen.dart';
import '../modules/training/screens/quiz_screen.dart';
import '../modules/training/screens/quiz_review_screen.dart';
import '../modules/training/models/course_model.dart';
import '../modules/training/models/lesson_model.dart';
import '../modules/training/repositories/firebase_training_repository.dart';
import '../admin/super_admin_console.dart';

class AppRouter {
  // ============================================================
  // MAIN ROUTES
  // ============================================================

  static const login = '/login';

  static const home = '/home';

  static const bbcApi = '/bbc-api';

  static const training = '/training';

  // ============================================================
  // ADMIN CONSOLE ROUTES
  // ============================================================

  static const adminConsole =
      '/admin-console';

  static const adminUsers =
      '/admin-console/users';

  static const adminTrainingManagement =
      '/admin-console/training-management';

  static const adminAnalytics =
      '/admin-console/analytics';

  // ============================================================
  // TRAINING ROUTES
  // ============================================================

  static const course =
      '/training/course/:courseId';

  static const lesson =
      '/training/course/:courseId/lesson/:lessonId';

  static const quiz =
      '/training/course/:courseId/lesson/:lessonId/quiz';

  static const quizReview =
      '/training/course/:courseId/lesson/:lessonId/quiz/review';

  // ============================================================
  // URL HELPERS
  // ============================================================

  static String coursePath(
      String courseId,
      ) {
    return '/training/course/'
        '${Uri.encodeComponent(courseId)}';
  }

  static String lessonPath(
      String courseId,
      String lessonId,
      ) {
    return '${coursePath(courseId)}/lesson/'
        '${Uri.encodeComponent(lessonId)}';
  }

  static String quizPath(
      String courseId,
      String lessonId,
      ) {
    return '${lessonPath(courseId, lessonId)}/quiz';
  }

  static String quizReviewPath(
      String courseId,
      String lessonId,
      ) {
    return '${quizPath(courseId, lessonId)}/review';
  }

  // ============================================================
  // ROUTER
  // ============================================================

  static final GoRouter router = GoRouter(
    initialLocation: login,

    debugLogDiagnostics: true,

    // ==========================================================
    // AUTH GUARD
    // ==========================================================

    redirect: (
        context,
        state,
        ) async {
      final user =
          FirebaseAuth.instance.currentUser;

      final location =
          state.uri.path;

      final isLogin =
          location == login;

      // --------------------------------------------------------
      // NOT LOGGED IN
      // --------------------------------------------------------

      if (user == null) {
        if (isLogin) {
          return null;
        }

        return login;
      }

      // --------------------------------------------------------
      // LOAD LATEST ROLE
      // --------------------------------------------------------

      try {
        await AuthService.loadUserRole();
      } catch (e) {
        debugPrint(
          'Router role loading failed: $e',
        );
      }

      // --------------------------------------------------------
      // ALREADY LOGGED IN -> LOGIN
      // --------------------------------------------------------

      if (isLogin) {
        return home;
      }

      // --------------------------------------------------------
      // ADMIN CONSOLE
      // --------------------------------------------------------

      if (location == adminConsole ||
          location == adminUsers ||
          location == adminTrainingManagement ||
          location == adminAnalytics) {
        if (AuthService.isSuperAdmin) {
          return null;
        }

        return home;
      }

      // --------------------------------------------------------
      // BBC API
      // --------------------------------------------------------

      if (location == bbcApi ||
          location.startsWith('$bbcApi/')) {
        if (AuthService.isSuperAdmin ||
            AuthService.isAgent ||
            AuthService.isTrainee) {
          return null;
        }

        return home;
      }

      // --------------------------------------------------------
      // TRAINING
      // --------------------------------------------------------

      if (location == training ||
          location.startsWith('$training/')) {
        if (AuthService.isSuperAdmin ||
            AuthService.isTrainee) {
          return null;
        }

        return home;
      }

      return null;
    },

    // ==========================================================
    // ROUTES
    // ==========================================================

    routes: [
      // ========================================================
      // LOGIN
      // ========================================================

      GoRoute(
        path: login,

        name: 'login',

        builder: (
            context,
            state,
            ) {
          return const LoginPage();
        },
      ),

      // ========================================================
      // PLATFORM DASHBOARD
      // ========================================================

      GoRoute(
        path: home,

        name: 'home',

        builder: (
            context,
            state,
            ) {
          return const PlatformDashboard();
        },
      ),

      // ========================================================
      // BBC API
      // ========================================================

      GoRoute(
        path: bbcApi,

        name: 'bbc-api',

        builder: (
            context,
            state,
            ) {
          return const BbcApiHomeScreen();
        },
      ),

      // ========================================================
      // TRAINING DASHBOARD
      // ========================================================

      GoRoute(
        path: training,

        name: 'training',

        builder: (
            context,
            state,
            ) {
          return const TrainingDashboard();
        },
      ),

      // ========================================================
      // COURSE
      // ========================================================

      GoRoute(
        path: course,

        name: 'training-course',

        builder: (
            context,
            state,
            ) {
          final courseId =
          state.pathParameters['courseId'];

          if (courseId == null ||
              courseId.isEmpty) {
            return const _RouteErrorPage(
              message:
              'Course ID is missing.',
            );
          }

          return _CourseRouteLoader(
            courseId: courseId,
          );
        },
      ),

      // ========================================================
      // LESSON
      // ========================================================

      GoRoute(
        path: lesson,

        name: 'training-lesson',

        builder: (
            context,
            state,
            ) {
          final courseId =
          state.pathParameters['courseId'];

          final lessonId =
          state.pathParameters['lessonId'];

          if (courseId == null ||
              courseId.isEmpty ||
              lessonId == null ||
              lessonId.isEmpty) {
            return const _RouteErrorPage(
              message:
              'Course or lesson ID is missing.',
            );
          }

          return _LessonRouteLoader(
            courseId: courseId,
            lessonId: lessonId,
          );
        },
      ),

      // ========================================================
      // QUIZ
      // ========================================================

      GoRoute(
        path: quiz,

        name: 'training-quiz',

        builder: (
            context,
            state,
            ) {
          final courseId =
          state.pathParameters['courseId'];

          final lessonId =
          state.pathParameters['lessonId'];

          if (courseId == null ||
              courseId.isEmpty ||
              lessonId == null ||
              lessonId.isEmpty) {
            return const _RouteErrorPage(
              message:
              'Course or lesson ID is missing.',
            );
          }

          return QuizScreen(
            courseId: courseId,
            lessonId: lessonId,
          );
        },
      ),

      // ========================================================
      // QUIZ REVIEW
      // ========================================================

      GoRoute(
        path: quizReview,

        name: 'training-quiz-review',

        builder: (
            context,
            state,
            ) {
          final courseId =
          state.pathParameters['courseId'];

          final lessonId =
          state.pathParameters['lessonId'];

          if (courseId == null ||
              courseId.isEmpty ||
              lessonId == null ||
              lessonId.isEmpty) {
            return const _RouteErrorPage(
              message:
              'Course or lesson ID is missing.',
            );
          }

          return QuizReviewScreen(
            courseId: courseId,
            lessonId: lessonId,
          );
        },
      ),

      // ========================================================
      // ADMIN CONSOLE
      //
      // Base URL:
      // /admin-console
      //
      // Opens Users by default.
      // ========================================================

      GoRoute(
        path: adminConsole,

        name: 'admin-console',

        redirect: (
            context,
            state,
            ) {
          return adminUsers;
        },

        builder: (
            context,
            state,
            ) {
          return const PlatformAdminConsole();
        },
      ),

      // ========================================================
      // ADMIN USERS
      // ========================================================

      GoRoute(
        path: adminUsers,

        name: 'admin-users',

        builder: (
            context,
            state,
            ) {
          return const PlatformAdminConsole();
        },
      ),

      // ========================================================
      // ADMIN TRAINING MANAGEMENT
      // ========================================================

      GoRoute(
        path: adminTrainingManagement,

        name: 'admin-training-management',

        builder: (
            context,
            state,
            ) {
          return const PlatformAdminConsole();
        },
      ),

      // ========================================================
      // ADMIN ANALYTICS
      // ========================================================

      GoRoute(
        path: adminAnalytics,

        name: 'admin-analytics',

        builder: (
            context,
            state,
            ) {
          return const PlatformAdminConsole();
        },
      ),
    ],

    // ==========================================================
    // ERROR
    // ==========================================================

    errorBuilder: (
        context,
        state,
        ) {
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Page not found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  state.uri.toString(),
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                ElevatedButton(
                  onPressed: () {
                    context.go(home);
                  },

                  child:
                  const Text(
                    'Go to Dashboard',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// COURSE ROUTE LOADER
// ============================================================

class _CourseRouteLoader
    extends StatefulWidget {
  final String courseId;

  const _CourseRouteLoader({
    required this.courseId,
  });

  @override
  State<_CourseRouteLoader> createState() =>
      _CourseRouteLoaderState();
}

class _CourseRouteLoaderState
    extends State<_CourseRouteLoader> {
  final FirebaseTrainingRepository
  _repository =
  FirebaseTrainingRepository();

  CourseModel? _course;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadCourse();
  }

  Future<void> _loadCourse() async {
    try {
      final courses =
      await _repository.getCourses();

      CourseModel? found;

      for (final course in courses) {
        if (course.id == widget.courseId) {
          found = course;
          break;
        }
      }

      if (!mounted) return;

      if (found == null) {
        setState(() {
          _loading = false;
          _error =
          'Course not found.';
        });

        return;
      }

      setState(() {
        _course = found;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
        'Failed to load course: $e';
      });
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const _RouteLoadingPage();
    }

    if (_error != null ||
        _course == null) {
      return _RouteErrorPage(
        message:
        _error ?? 'Course not found.',
      );
    }

    return CourseDetails(
      course: _course!,
    );
  }
}

// ============================================================
// LESSON ROUTE LOADER
// ============================================================

class _LessonRouteLoader
    extends StatefulWidget {
  final String courseId;
  final String lessonId;

  const _LessonRouteLoader({
    required this.courseId,
    required this.lessonId,
  });

  @override
  State<_LessonRouteLoader> createState() =>
      _LessonRouteLoaderState();
}

class _LessonRouteLoaderState
    extends State<_LessonRouteLoader> {
  final FirebaseTrainingRepository
  _repository =
  FirebaseTrainingRepository();

  LessonModel? _lesson;

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lessons =
      await _repository.getLessons(
        widget.courseId,
      );

      LessonModel? found;

      for (final lesson in lessons) {
        if (lesson.id == widget.lessonId) {
          found = lesson;
          break;
        }
      }

      if (!mounted) return;

      if (found == null) {
        setState(() {
          _loading = false;
          _error =
          'Lesson not found.';
        });

        return;
      }

      setState(() {
        _lesson = found;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
        'Failed to load lesson: $e';
      });
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const _RouteLoadingPage();
    }

    if (_error != null ||
        _lesson == null) {
      return _RouteErrorPage(
        message:
        _error ?? 'Lesson not found.',
      );
    }

    return LessonScreen(
      lesson: _lesson!,
    );
  }
}

// ============================================================
// LOADING PAGE
// ============================================================

class _RouteLoadingPage
    extends StatelessWidget {
  const _RouteLoadingPage();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const Scaffold(
      backgroundColor:
      Color(0xffF5F8FC),

      body: Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xff003366),
        ),
      ),
    );
  }
}

// ============================================================
// ROUTE ERROR PAGE
// ============================================================

class _RouteErrorPage
    extends StatelessWidget {
  final String message;

  const _RouteErrorPage({
    required this.message,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
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
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                message,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              ElevatedButton(
                onPressed: () {
                  context.go(
                    AppRouter.training,
                  );
                },

                child:
                const Text(
                  'Back to Training',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}