import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../admin/services/training_admin_service.dart';
import '../models/quiz_model.dart';
import '../services/training_progress_service.dart';


class QuizReviewScreen extends StatefulWidget {

  final String courseId;
  final String lessonId;


  const QuizReviewScreen({

    super.key,

    required this.courseId,

    required this.lessonId,

  });



  @override
  State<QuizReviewScreen> createState() =>
      _QuizReviewScreenState();

}



class _QuizReviewScreenState
    extends State<QuizReviewScreen> {


  final TrainingProgressService progressService =
  TrainingProgressService();


  final TrainingAdminService adminService =
  TrainingAdminService();



  bool loading = true;


  QuizModel? quiz;


  int score = 0;


  bool passed = false;


  List<int?> selectedAnswers = [];



  @override
  void initState() {

    super.initState();

    _loadReview();

  }




  Future<void> _loadReview() async {


    final user =
        FirebaseAuth.instance.currentUser;



    if(user == null){

      return;

    }




    final result =
    await progressService.getQuizResult(

      userId: user.uid,

      courseId: widget.courseId,

      lessonId: widget.lessonId,

    );




    if(result == null){


      if(!mounted) return;


      setState(() {

        loading = false;

      });


      return;

    }





    score =
        result["score"] ?? 0;


    passed =
        result["passed"] ?? false;





    final answers =
        result["answers"] as List<dynamic>? ?? [];



    selectedAnswers =
        answers.map<int?>((e){


          return e["selectedAnswer"] as int?;


        }).toList();





    final loadedQuiz =
    await adminService.getQuiz(

      courseId: widget.courseId,

      lessonId: widget.lessonId,

    );



    if(!mounted) return;




    setState(() {


      quiz = loadedQuiz;


      loading = false;


    });


  }






  @override
  Widget build(BuildContext context){



    if(loading){


      return const Scaffold(

        body:

        Center(

          child:
          CircularProgressIndicator(),

        ),

      );


    }





    if(quiz == null){


      return Scaffold(


        appBar:

        AppBar(

          title:
          const Text(
            "Quiz Review",
          ),

        ),



        body:

        const Center(

          child:

          Text(
            "Quiz data not found",
          ),

        ),


      );


    }






    return Scaffold(


      backgroundColor:
      const Color(0xffF5F8FC),



      appBar:

      AppBar(


        backgroundColor:
        const Color(0xff003366),


        foregroundColor:
        Colors.white,


        title:
        const Text(
          "Quiz Review",
        ),


      ),





      body:


      SingleChildScrollView(


        padding:
        const EdgeInsets.all(30),



        child:

        Column(


          crossAxisAlignment:
          CrossAxisAlignment.start,



          children:[



            _buildResultCard(),





            const SizedBox(
              height:25,
            ),






            const Text(

              "Review Answers",

              style:

              TextStyle(

                fontSize:20,

                fontWeight:
                FontWeight.bold,

                color:
                Color(0xff003366),

              ),

            ),






            const SizedBox(
              height:20,
            ),






            ...List.generate(

              quiz!.questions.length,


                  (index){


                return _questionCard(

                  index,

                  quiz!.questions[index],

                );


              },


            ),



          ],


        ),


      ),



    );


  }






  Widget _buildResultCard(){



    return Container(


      width:
      double.infinity,



      padding:
      const EdgeInsets.all(25),




      decoration:

      BoxDecoration(


        color:
        Colors.white,



        borderRadius:
        BorderRadius.circular(18),



      ),





      child:

      Column(


        children:[




          Icon(


            passed

                ?

            Icons.check_circle

                :

            Icons.cancel,



            size:60,



            color:

            passed

                ?

            Colors.green

                :

            Colors.red,


          ),




          const SizedBox(
            height:15,
          ),




          Text(


            passed

                ?

            "Quiz Passed"

                :

            "Quiz Failed",



            style:

            TextStyle(


              fontSize:24,


              fontWeight:
              FontWeight.bold,



              color:

              passed

                  ?

              Colors.green

                  :

              Colors.red,


            ),



          ),




          const SizedBox(
            height:10,
          ),





          Text(

            "$score%",


            style:

            const TextStyle(

              fontSize:40,

              fontWeight:
              FontWeight.bold,

            ),

          ),



        ],


      ),


    );


  }







  Widget _questionCard(
      int index,
      dynamic question,
      ){



    final selected =

    index < selectedAnswers.length

        ?

    selectedAnswers[index]

        :

    null;




    final correct =
        question.correctAnswerIndex;



    return Container(



      margin:

      const EdgeInsets.only(

        bottom:20,

      ),




      padding:

      const EdgeInsets.all(22),




      decoration:

      BoxDecoration(


        color:
        Colors.white,



        borderRadius:
        BorderRadius.circular(16),



      ),




      child:


      Column(


        crossAxisAlignment:
        CrossAxisAlignment.start,



        children:[



          Text(

            "Question ${index+1}",


            style:

            const TextStyle(


              fontWeight:
              FontWeight.bold,


              color:
              Color(0xff003366),


            ),


          ),





          const SizedBox(
            height:15,
          ),






          Text(


            question.question,


            style:

            const TextStyle(


              fontSize:17,


              fontWeight:
              FontWeight.bold,


            ),


          ),





          const SizedBox(
            height:15,
          ),






          const Text(

            "Your Answer:",


            style:

            TextStyle(

              fontWeight:
              FontWeight.bold,

            ),


          ),





          Text(


            selected == null

                ?

            "Not answered"

                :

            question.options[selected],


          ),






          const SizedBox(
            height:10,
          ),





          const Text(

            "Correct Answer:",


            style:

            TextStyle(

              fontWeight:
              FontWeight.bold,

            ),


          ),





          Text(

            question.options[correct],

          ),



        ],


      ),


    );

  }



}