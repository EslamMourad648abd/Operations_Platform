import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../widgets/course_card.dart';
import '../widgets/training_stat_card.dart';
import 'course_details.dart';


class TrainingDashboard extends StatelessWidget {

  const TrainingDashboard({
    super.key,
  });


  @override
  Widget build(BuildContext context) {


    final repository =
    FirebaseTrainingRepository();


    print("TRAINING DASHBOARD BUILT");



    return Scaffold(

      backgroundColor:
      const Color(0xffF5F8FC),



      body:

      SafeArea(

        child:

        Padding(

          padding: EdgeInsets.symmetric(

            horizontal:
            MediaQuery.of(context).size.width > 1200
                ? 40
                : 20,

            vertical:30,

          ),



          child:

          ConstrainedBox(

            constraints:
            const BoxConstraints(

              maxWidth:1600,

            ),



            child:

            Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,



              children: [



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


                    const SizedBox(width:12),


                    const Text(

                      "Training Portal",

                      style: TextStyle(

                        fontSize:34,

                        fontWeight:
                        FontWeight.bold,

                        color:
                        Color(0xff003366),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height:8),



                const SizedBox(height:8),



                const Text(

                  "Improve your skills and track your progress",

                  style:TextStyle(

                    color:
                    Colors.grey,

                    fontSize:16,

                  ),

                ),



                const SizedBox(height:30),



                Row(

                  children: [



                    Expanded(

                      child:

                      FutureBuilder<List<CourseModel>>(


                        future: () {

                          print(
                              "GET COURSES CALLED"
                          );


                          return repository.getCourses();


                        }(),



                        builder:(context,snapshot){



                          if(!snapshot.hasData){


                            return const TrainingStatCard(

                              title:"Courses",

                              value:"0",

                              icon:
                              Icons.menu_book,

                            );


                          }



                          return TrainingStatCard(


                            title:"Courses",


                            value:
                            "${snapshot.data!.length}",


                            icon:
                            Icons.menu_book,


                          );


                        },


                      ),

                    ),



                    const SizedBox(width:20),



                    const Expanded(

                      child:

                      TrainingStatCard(

                        title:"Completed",

                        value:"0",

                        icon:
                        Icons.check_circle,

                      ),

                    ),



                    const SizedBox(width:20),



                    const Expanded(

                      child:

                      TrainingStatCard(

                        title:"In Progress",

                        value:"0",

                        icon:
                        Icons.timelapse,

                      ),

                    ),



                  ],

                ),



                const SizedBox(height:35),



                const Text(

                  "Available Courses",

                  style:

                  TextStyle(

                    fontSize:24,

                    fontWeight:
                    FontWeight.bold,

                  ),

                ),



                const SizedBox(height:20),




                Expanded(

                  child:

                  FutureBuilder<List<CourseModel>>(


                    future:
                    repository.getCourses(),



                    builder:(context,snapshot){



                      if(snapshot.connectionState ==
                          ConnectionState.waiting){


                        return const Center(

                          child:

                          CircularProgressIndicator(),

                        );


                      }



                      if(!snapshot.hasData ||
                          snapshot.data!.isEmpty){


                        return const Center(

                          child:

                          Text(

                            "No courses available",

                          ),

                        );


                      }



                      final courses =
                      snapshot.data!;



                      return LayoutBuilder(


                        builder:(context,constraints){



                          int columns;



                          if(constraints.maxWidth >= 1400){


                            columns = 3;


                          }
                          else if(constraints.maxWidth >= 900){


                            columns = 2;


                          }
                          else{


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



                              // Adjusted for CourseCard content

                              mainAxisExtent:
                              400,


                            ),



                            itemCount:
                            courses.length,



                            itemBuilder:(context,index){


                              final course =
                              courses[index];



                              return CourseCard(


                                course:
                                course,



                                onPressed:(){



                                  Navigator.push(

                                    context,

                                    MaterialPageRoute(

                                      builder:(_)=>

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