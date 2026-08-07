import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_training_analytics_model.dart';


class TrainingAnalyticsService {


  final FirebaseFirestore firestore;


  TrainingAnalyticsService({

    FirebaseFirestore? firestore,

  }) :

        firestore =
            firestore ?? FirebaseFirestore.instance;




  // =====================================================
  // GET ALL TRAINEE ANALYTICS
  // =====================================================

  Future<List<AgentTrainingAnalyticsModel>>
  getAllTraineeAnalytics() async {



    final usersSnapshot =

    await firestore

        .collection("users")

        .where(
      "role",
      isEqualTo: "trainee",
    )

        .get();





    final coursesSnapshot =

    await firestore

        .collection("courses")

        .get();




    final Map<String,String> courseNames = {};



    for(final course in coursesSnapshot.docs){


      final data = course.data();


      courseNames[course.id] =
          data["title"] ?? course.id;


    }





    List<AgentTrainingAnalyticsModel>
    analytics = [];





    for(final userDoc in usersSnapshot.docs){



      final userData =
      userDoc.data();



      final userId =
          userDoc.id;



      final userName =
      (userData["displayName"] != null &&
          userData["displayName"].toString().trim().isNotEmpty)
          ? userData["displayName"]
          : userData["email"] ?? "Unknown";






      final progressSnapshot =

      await firestore

          .collection("users")

          .doc(userId)

          .collection("training_progress")

          .get();





      if(progressSnapshot.docs.isEmpty){

        analytics.add(

          AgentTrainingAnalyticsModel(

            userId: userId,

            userName: userName,

            totalCourses: 0,

            completedCourses: 0,

            overallProgress: 0,

            averageQuizScore: 0,

            courses: [],

          ),

        );


        continue;

      }





      List<CourseAnalyticsModel>
      userCourses = [];



      double totalProgress = 0;


      double totalQuizScore = 0;


      int completedCourses = 0;







      for(final courseDoc in progressSnapshot.docs){



        final courseId =
            courseDoc.id;




        final courseName =
            courseNames[courseId]
                ??
                courseId;







        final lessonsSnapshot =

        await firestore

            .collection("users")

            .doc(userId)

            .collection("training_progress")

            .doc(courseId)

            .collection("lessons")

            .get();






        if(lessonsSnapshot.docs.isEmpty){

          continue;

        }







        int completedLessons = 0;


        int totalScore = 0;


        int quizCount = 0;







        for(final lessonDoc
        in lessonsSnapshot.docs){



          final data =
          lessonDoc.data();





          if(data["completed"] == true){

            completedLessons++;

          }





          if(data["quizSubmitted"] == true){



            totalScore +=

            (data["score"] ?? 0)
            as int;



            quizCount++;


          }




        }








        final totalLessons =
            lessonsSnapshot.docs.length;





        final double progress =



        totalLessons == 0

            ?

        0

            :

        (completedLessons /
            totalLessons) *
            100;








        final double quizScore =



        quizCount == 0

            ?

        0

            :

        totalScore / quizCount;








        final bool completed =



            completedLessons ==
                totalLessons;






        if(completed){

          completedCourses++;

        }







        totalProgress += progress;


        totalQuizScore += quizScore;









        userCourses.add(



          CourseAnalyticsModel(



            courseId:
            courseId,



            courseName:
            courseName,



            totalLessons:
            totalLessons,



            completedLessons:
            completedLessons,



            progress:
            progress,



            quizScore:
            quizScore,



            completed:
            completed,



          ),


        );



      }








      final totalCourses =
          userCourses.length;







      analytics.add(



        AgentTrainingAnalyticsModel(



          userId:
          userId,



          userName:
          userName,



          totalCourses:
          totalCourses,



          completedCourses:
          completedCourses,



          overallProgress:



          totalCourses == 0

              ?

          0

              :

          totalProgress /
              totalCourses,





          averageQuizScore:



          totalCourses == 0

              ?

          0

              :

          totalQuizScore /
              totalCourses,





          courses:
          userCourses,



        ),


      );




    }







    return analytics;



  }



}