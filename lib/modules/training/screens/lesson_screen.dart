import 'package:bbc_api_tool/modules/training/screens/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/training_progress_service.dart';


import 'quiz_review_screen.dart';
import '../widgets/google_drive_player.dart';
import '../models/lesson_model.dart';


class LessonScreen extends StatefulWidget {

  final LessonModel lesson;


  const LessonScreen({

    super.key,

    required this.lesson,

  });


  @override
  State<LessonScreen> createState() =>
      _LessonScreenState();

}




class _LessonScreenState extends State<LessonScreen> {


  final TrainingProgressService progressService =
  TrainingProgressService();



  bool lessonCompleted = false;

  bool loadingProgress = true;

  bool quizSubmitted = false;

  bool videoCompleted = false;




  @override
  void initState() {

    super.initState();

    _loadProgress();

  }





  Future<void> _loadProgress() async {


    final user =
        FirebaseAuth.instance.currentUser;



    if(user == null){

      if(!mounted) return;


      setState(() {

        loadingProgress = false;

      });


      return;

    }




    final completed =
    await progressService.isLessonCompleted(

      userId:user.uid,

      courseId:widget.lesson.courseId,

      lessonId:widget.lesson.id,

    );




    final submitted =
    await progressService.isQuizSubmitted(

      userId:user.uid,

      courseId:widget.lesson.courseId,

      lessonId:widget.lesson.id,

    );




    final video =
    await progressService.isVideoCompleted(

      userId:user.uid,

      courseId:widget.lesson.courseId,

      lessonId:widget.lesson.id,

    );




    if(!mounted) return;



    setState(() {

      videoCompleted = video;

      lessonCompleted = completed;

      quizSubmitted = submitted;

      loadingProgress = false;

    });


  }






  Future<void> _completeLesson() async {


    final user =
        FirebaseAuth.instance.currentUser;



    if(user == null){

      return;

    }





    if(!videoCompleted){


      await progressService.completeVideo(

        userId:user.uid,

        courseId:widget.lesson.courseId,

        lessonId:widget.lesson.id,

      );



      if(!mounted) return;



      setState(() {

        videoCompleted = true;

      });


    }





    if(widget.lesson.quizEnabled){


      await Navigator.push(

        context,

        MaterialPageRoute(

          builder: (_) => QuizScreen(

            courseId:
            widget.lesson.courseId,

            lessonId:
            widget.lesson.id,

          ),

        ),

      );



      await _loadProgress();


      return;

    }





    await progressService.completeLesson(

      userId:user.uid,

      courseId:widget.lesson.courseId,

      lessonId:widget.lesson.id,

    );



    await _loadProgress();




    if(!mounted) return;



    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content:

        Text(
          "Lesson completed successfully",
        ),

      ),

    );


  }







  Future<void> _reviewQuiz() async {


    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => QuizReviewScreen(

          courseId:
          widget.lesson.courseId,


          lessonId:
          widget.lesson.id,

        ),

      ),

    );



    await _loadProgress();

  }






  @override
  Widget build(BuildContext context) {


    final lesson =
        widget.lesson;



    return Scaffold(

      backgroundColor:
      const Color(0xffF5F8FC),




      appBar: AppBar(

        backgroundColor:
        const Color(0xff003366),

        foregroundColor:
        Colors.white,

        elevation:0,



        title:

        Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children:[


            const Text(

              "Training Portal",

              style:

              TextStyle(

                fontSize:12,

                color:
                Colors.white70,

              ),

            ),




            Text(

              lesson.title,

              style:

              const TextStyle(

                fontWeight:
                FontWeight.bold,

                fontSize:18,

              ),

            ),


          ],

        ),

      ),





      body:

      SingleChildScrollView(

        child:

        Padding(

          padding:
          const EdgeInsets.all(30),



          child:

          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,


            children:[



              Center(

                child:

                ConstrainedBox(

                  constraints:

                  const BoxConstraints(

                    maxWidth:1100,

                  ),




                  child:

                  Container(

                    decoration:

                    BoxDecoration(

                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius.circular(16),


                    ),



                    child:

                    ClipRRect(

                      borderRadius:
                      BorderRadius.circular(16),



                      child:

                      GoogleDrivePlayer(

                        videoUrl:
                        lesson.videoUrl,

                      ),

                    ),

                  ),

                ),

              ),




              const SizedBox(height:20),





              _buildCard(

                child:

                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                  children:[


                    const Text(

                      "Lesson Completion",

                      style:

                      TextStyle(

                        fontSize:18,

                        fontWeight:
                        FontWeight.bold,

                        color:
                        Color(0xff003366),

                      ),

                    ),




                    const SizedBox(height:15),




                    loadingProgress

                        ?

                    const CircularProgressIndicator()



                        :


                    ElevatedButton.icon(

                      onPressed:

                      quizSubmitted

                          ?

                      _reviewQuiz

                          :

                      _completeLesson,



                      icon:

                      Icon(

                        quizSubmitted

                            ?

                        Icons.visibility

                            :

                        Icons.play_arrow,

                      ),




                      label:

                      Text(

                        quizSubmitted

                            ?

                        "Review Quiz"



                            :

                        !videoCompleted &&
                            lesson.quizEnabled

                            ?

                        "Complete Video & Take Quiz"



                            :

                        !videoCompleted

                            ?

                        "Complete Video"



                            :

                        lesson.quizEnabled

                            ?

                        "Take Quiz"



                            :

                        "Complete Lesson",

                      ),

                    ),

                  ],

                ),

              ),





              const SizedBox(height:20),





              _buildCard(

                child:

                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                  children:[



                    const Text(

                      "Lesson Progress",

                      style:

                      TextStyle(

                        fontSize:18,

                        fontWeight:
                        FontWeight.bold,

                        color:
                        Color(0xff003366),

                      ),

                    ),




                    const SizedBox(height:15),




                    LinearProgressIndicator(

                      value:

                      quizSubmitted

                          ?

                      1

                          :

                      videoCompleted

                          ?

                      0.5

                          :

                      0,


                      minHeight:8,

                    ),



                    const SizedBox(height:10),




                    Text(

                      quizSubmitted

                          ?

                      "Completed"


                          :

                      videoCompleted

                          ?

                      "Video completed - Quiz pending"


                          :

                      "Not completed yet",

                    ),

                  ],

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }






  Widget _buildCard({

    required Widget child,

  }) {


    return Container(

      width:
      double.infinity,


      padding:
      const EdgeInsets.all(22),



      decoration:

      BoxDecoration(

        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(16),



        border:

        Border.all(

          color:
          const Color(0xffE4E9F0),

        ),

      ),



      child:
      child,

    );

  }


}