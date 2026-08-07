import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_progress_model.dart';

class CourseProgressService {

  final FirebaseFirestore firestore;


  CourseProgressService({

    FirebaseFirestore? firestore,

  }) :
        firestore =
            firestore ?? FirebaseFirestore.instance;




  // =====================================================
  // GET COURSE PROGRESS
  // =====================================================

  Future<CourseProgressModel> getCourseProgress({

    required String userId,

    required String courseId,

    required List<String> lessonIds,

  }) async {


    int completedLessons = 0;

    int completedVideos = 0;

    int submittedQuizzes = 0;


    int totalQuizScore = 0;

    int quizCount = 0;



    DateTime? latestCompletionDate;



    for(final lessonId in lessonIds){



      final snapshot =

      await firestore

          .collection("users")

          .doc(userId)

          .collection("training_progress")

          .doc(courseId)

          .collection("lessons")

          .doc(lessonId)

          .get();




      if(!snapshot.exists){

        continue;

      }




      final data =
      snapshot.data();




      if(data?["completed"] == true){

        completedLessons++;


        final completedAt =
        data?["completedAt"];


        if(completedAt != null){

          final date =
          (completedAt as Timestamp)
              .toDate();


          if(latestCompletionDate == null ||
              date.isAfter(latestCompletionDate!)){

            latestCompletionDate = date;

          }

        }

      }




      if(data?["videoCompleted"] == true){

        completedVideos++;

      }




      if(data?["quizSubmitted"] == true){

        submittedQuizzes++;


        final score =
            data?["score"] ?? 0;


        totalQuizScore += score as int;


        quizCount++;

      }



    }




    double percentage = 0;



    if(lessonIds.isNotEmpty){


      percentage =

          (completedLessons / lessonIds.length) * 100;


    }




    double averageQuizScore = 0;



    if(quizCount > 0){

      averageQuizScore =
          totalQuizScore / quizCount;

    }




    final bool courseCompleted =

        lessonIds.isNotEmpty &&

            completedLessons == lessonIds.length;




    print(
      "Course $courseId => "
          "completed: $completedLessons / ${lessonIds.length}, "
          "quiz avg: $averageQuizScore",
    );




    return CourseProgressModel(

      totalLessons:
      lessonIds.length,


      completedLessons:
      completedLessons,


      completedVideos:
      completedVideos,


      submittedQuizzes:
      submittedQuizzes,


      progressPercentage:
      percentage,


      averageQuizScore:
      averageQuizScore,


      courseCompleted:
      courseCompleted,


      completedAt:
      courseCompleted
          ? latestCompletionDate
          : null,

    );

  }


}