import 'package:bbc_api_tool/modules/training/screens/quiz_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../admin/services/training_admin_service.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';

import '../services/training_progress_service.dart';




class QuizScreen extends StatefulWidget {


  final String courseId;

  final String lessonId;



  const QuizScreen({

    super.key,

    required this.courseId,

    required this.lessonId,

  });



  @override
  State<QuizScreen> createState() =>
      _QuizScreenState();

}




class _QuizScreenState
    extends State<QuizScreen> {


  final TrainingAdminService adminService =
  TrainingAdminService();


  final TrainingProgressService progressService =
  TrainingProgressService();



  QuizModel? quiz;



  bool loading = true;

  bool submitting = false;



  int currentIndex = 0;



  List<int?> selectedAnswers = [];





  @override
  void initState() {

    super.initState();

    _loadQuiz();

  }





  Future _loadQuiz() async {


    final result =
    await adminService.getQuiz(

      courseId: widget.courseId,

      lessonId: widget.lessonId,

    );



    if(!mounted) return;



    if(result != null && result.questions.isNotEmpty){

      quiz = result;

      selectedAnswers =
          List.generate(
            result.questions.length,
                (_) => null,
          );

    }
    else {

      quiz = result;

    }



    setState(() {

      loading = false;

    });


  }







  Future _submitQuiz() async {


    if(quiz == null){

      return;

    }



    final unanswered =
    selectedAnswers.contains(null);



    if(unanswered){


      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content:
          Text(
              "Please answer all questions"
          ),

        ),

      );


      return;

    }





    setState(() {

      submitting = true;

    });





    int correct = 0;



    List<Map<String,dynamic>> answers=[];



    for(int i=0;
    i<quiz!.questions.length;
    i++){



      final question =
      quiz!.questions[i];



      final selected =
      selectedAnswers[i]!;



      if(selected ==
          question.correctAnswerIndex){

        correct++;

      }




      answers.add({

        "questionId":
        question.id,


        "selectedAnswer":
        selected,


        "correctAnswer":
        question.correctAnswerIndex,


      });



    }






    final score =
    ((correct /
        quiz!.questions.length)
        *100)
        .round();




    final passed =
        score >= quiz!.passingScore;





    final user =
        FirebaseAuth.instance.currentUser;



    if(user == null){

      return;

    }





    await progressService.submitQuiz(

      userId:user.uid,

      courseId:widget.courseId,

      lessonId:widget.lessonId,

      score:score,

      passed:passed,

      answers:answers,

    );





    if(!mounted)return;



    setState(() {

      submitting=false;

    });





    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder:(context)=>

            QuizReviewScreen(

              courseId:
              widget.courseId,

              lessonId:
              widget.lessonId,

            ),

      ),

    );



  }









  @override
  Widget build(BuildContext context) {



    return Scaffold(


      backgroundColor:
      const Color(0xffF5F8FC),




      appBar: AppBar(

        backgroundColor:
        const Color(0xff003366),

        foregroundColor:
        Colors.white,


        title:
        const Text(

          "Lesson Quiz",

        ),

      ),





      body:

      loading

          ?

      const Center(

        child:
        CircularProgressIndicator(),

      )

          : quiz == null

          ?

      const Center(

        child:
        Text(
            "Quiz not available"
        ),

      )

          : _buildQuiz(),



    );


  }









  Widget _buildQuiz(){


    if (quiz!.questions.isEmpty) {

      return const Center(
        child: Text(
          "This quiz has no questions.",
        ),
      );

    }


    final QuizQuestionModel question =
    quiz!.questions[currentIndex];



    return Padding(

      padding:
      const EdgeInsets.all(30),


      child:

      Column(


        crossAxisAlignment:
        CrossAxisAlignment.start,


        children: [




          Text(

            "Question ${currentIndex+1} / ${quiz!.questions.length}",


            style:
            const TextStyle(

              color:
              Color(0xff003366),

              fontSize:16,

              fontWeight:
              FontWeight.bold,

            ),

          ),





          const SizedBox(
              height:20
          ),






          Container(

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


              border:Border.all(

                color:
                const Color(0xffE4E9F0),

              ),

            ),




            child:

            Text(

              question.question,


              style:
              const TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),



          ),






          const SizedBox(
              height:20
          ),





          ...List.generate(

              question.options.length,

                  (index){



                final selected =
                    selectedAnswers[currentIndex]
                        ==
                        index;



                return GestureDetector(


                  onTap:(){


                    setState(() {


                      selectedAnswers[currentIndex]
                      =
                          index;


                    });


                  },



                  child:

                  Container(

                    margin:
                    const EdgeInsets.only(
                        bottom:12
                    ),


                    padding:
                    const EdgeInsets.all(16),



                    decoration:
                    BoxDecoration(

                      color:
                      selected

                          ?
                      const Color(0xff003366)
                          :
                      Colors.white,


                      borderRadius:
                      BorderRadius.circular(12),


                      border:Border.all(

                        color:
                        const Color(0xffE4E9F0),

                      ),

                    ),



                    child:

                    Text(

                      question.options[index],


                      style:

                      TextStyle(

                        color:
                        selected
                            ?
                        Colors.white
                            :
                        Colors.black87,


                      ),


                    ),



                  ),


                );

              }

          ),







          const Spacer(),






          Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,


            children: [



              ElevatedButton(

                onPressed:
                currentIndex == 0

                    ?
                null

                    :

                    (){

                  setState(() {

                    currentIndex--;

                  });

                },


                child:
                const Text(
                    "Previous"
                ),

              ),






              currentIndex ==
                  quiz!.questions.length-1


                  ?

              ElevatedButton.icon(

                onPressed:
                submitting
                    ?
                null
                    :
                _submitQuiz,


                icon:
                const Icon(
                    Icons.check
                ),


                label:
                submitting

                    ?
                const Text(
                    "Submitting..."
                )

                    :
                const Text(
                    "Submit Quiz"
                ),

              )

                  :

              ElevatedButton(

                onPressed:(){


                  setState(() {

                    currentIndex++;

                  });


                },


                child:
                const Text(
                    "Next"
                ),

              ),



            ],


          ),




        ],


      ),


    );


  }



}