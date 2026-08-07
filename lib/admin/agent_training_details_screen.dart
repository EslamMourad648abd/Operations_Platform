import 'package:flutter/material.dart';

import '../modules/training/models/agent_training_analytics_model.dart';



class AgentTrainingDetailsScreen extends StatelessWidget {


  final AgentTrainingAnalyticsModel agent;



  const AgentTrainingDetailsScreen({

    super.key,

    required this.agent,

  });




  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      const Color(0xffF5F8FC),



      appBar:

      AppBar(

        title:

        Text(

          agent.userName,

        ),

      ),




      body:

      ListView(

        padding:
        const EdgeInsets.all(20),


        children: [


          _summaryCard(),



          const SizedBox(
            height:20,
          ),




          const Text(

            "Courses",

            style:

            TextStyle(

              fontSize:22,

              fontWeight:
              FontWeight.bold,

            ),

          ),




          const SizedBox(
            height:12,
          ),




          ...agent.courses.map(

                  (course) =>

                  _courseCard(course)

          ),


        ],

      ),

    );

  }







  Widget _summaryCard(){


    return Card(

      child:

      Padding(

        padding:
        const EdgeInsets.all(20),


        child:

        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            const Text(

              "Training Summary",

              style:

              TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

              ),

            ),




            const SizedBox(
              height:15,
            ),




            Text(
              "Total Courses: ${agent.totalCourses}",
            ),




            Text(
              "Completed Courses: ${agent.completedCourses}",
            ),




            Text(
              "Overall Progress: ${agent.overallProgress.toStringAsFixed(1)}%",
            ),




            Text(
              "Average Quiz Score: ${agent.averageQuizScore.toStringAsFixed(1)}%",
            ),



          ],

        ),

      ),

    );


  }







  Widget _courseCard(
      CourseAnalyticsModel course,
      ){


    return Card(


      margin:

      const EdgeInsets.only(

        bottom:15,

      ),



      child:

      Padding(

        padding:
        const EdgeInsets.all(16),


        child:

        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [



            Text(

              course.courseName,

              style:

              const TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),





            const SizedBox(
              height:10,
            ),





            Text(
              "Lessons: ${course.completedLessons}/${course.totalLessons}",
            ),




            Text(
              "Progress: ${course.progress.toStringAsFixed(1)}%",
            ),




            Text(
              "Quiz Score: ${course.quizScore.toStringAsFixed(1)}%",
            ),




            Text(

              course.completed

                  ?

              "Completed"

                  :

              "In Progress",



              style:

              TextStyle(

                color:

                course.completed

                    ?

                Colors.green

                    :

                Colors.orange,


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