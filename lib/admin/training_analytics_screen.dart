import 'package:flutter/material.dart';

import '../modules/training/models/agent_training_analytics_model.dart';
import '../modules/training/services/training_analytics_service.dart';

import 'agent_training_details_screen.dart';


class TrainingAnalyticsScreen extends StatefulWidget {

  const TrainingAnalyticsScreen({
    super.key,
  });


  @override
  State<TrainingAnalyticsScreen> createState() =>
      _TrainingAnalyticsScreenState();

}



class _TrainingAnalyticsScreenState
    extends State<TrainingAnalyticsScreen> {


  final TrainingAnalyticsService service =
  TrainingAnalyticsService();


  List<AgentTrainingAnalyticsModel> agents = [];


  bool loading = true;




  @override
  void initState() {

    super.initState();

    _loadAnalytics();

  }





  Future<void> _loadAnalytics() async {

    try {


      final result =
      await service.getAllTraineeAnalytics();



      if(!mounted) return;



      setState(() {

        agents = result;

        loading = false;

      });


    }


    catch(e){


      debugPrint(
        "ANALYTICS ERROR: $e",
      );



      if(!mounted) return;



      setState(() {

        loading = false;

      });



      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
          Text(
            "Failed to load analytics",
          ),

          backgroundColor:
          Colors.red,

        ),

      );


    }

  }







  Widget _analyticsCard(
      AgentTrainingAnalyticsModel agent,
      ){



    return InkWell(

      borderRadius:
      BorderRadius.circular(16),


      onTap: (){


        Navigator.push(

          context,

          MaterialPageRoute(

            builder: (_) =>

                AgentTrainingDetailsScreen(

                  agent: agent,

                ),

          ),

        );


      },


      child:

      Card(

        elevation:3,


        margin:

        const EdgeInsets.only(

          bottom:16,

        ),



        shape:

        RoundedRectangleBorder(

          borderRadius:
          BorderRadius.circular(16),

        ),



        child:

        Padding(

          padding:
          const EdgeInsets.all(20),



          child:

          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,


            children: [



              Row(

                children: [


                  CircleAvatar(

                    radius:25,


                    backgroundColor:
                    const Color(
                      0xff003366,
                    ),



                    child:

                    Text(

                      agent.userName.isNotEmpty

                          ?

                      agent.userName[0]
                          .toUpperCase()

                          :

                      "?",



                      style:

                      const TextStyle(

                        color:
                        Colors.white,

                        fontWeight:
                        FontWeight.bold,

                      ),

                    ),

                  ),




                  const SizedBox(
                    width:15,
                  ),




                  Expanded(

                    child:

                    Text(

                      agent.userName,


                      style:

                      const TextStyle(

                        fontSize:18,

                        fontWeight:
                        FontWeight.bold,

                      ),

                    ),

                  ),


                ],

              ),




              const SizedBox(
                height:20,
              ),





              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,


                children: [



                  _stat(
                    "Courses",
                    agent.totalCourses.toString(),
                  ),




                  _stat(
                    "Completed",
                    agent.completedCourses.toString(),
                  ),




                  _stat(
                    "Progress",
                    "${agent.overallProgress.toStringAsFixed(0)}%",
                  ),



                ],

              ),





              const SizedBox(
                height:20,
              ),





              Text(

                "Average Quiz Score",

                style:

                TextStyle(

                  color:
                  Colors.grey.shade700,

                ),

              ),




              const SizedBox(
                height:8,
              ),




              LinearProgressIndicator(

                value:
                agent.averageQuizScore / 100,

                minHeight:
                10,

              ),




              const SizedBox(
                height:8,
              ),





              Align(

                alignment:
                Alignment.centerRight,


                child:

                Text(

                  "${agent.averageQuizScore.toStringAsFixed(1)}%",



                  style:

                  const TextStyle(

                    fontWeight:
                    FontWeight.bold,


                    color:
                    Color(0xff003366),

                  ),

                ),

              ),



            ],

          ),

        ),

      ),

    );

  }







  Widget _stat(
      String title,
      String value,
      ){


    return Column(

      children: [


        Text(

          value,

          style:

          const TextStyle(

            fontSize:18,

            fontWeight:
            FontWeight.bold,

            color:
            Color(0xff003366),

          ),

        ),




        const SizedBox(
          height:4,
        ),




        Text(

          title,

          style:

          const TextStyle(

            color:
            Colors.grey,

          ),

        ),


      ],

    );

  }







  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:
      const Color(0xffF5F8FC),



      appBar:

      AppBar(

        title:
        const Text(
          "Training Analytics",
        ),

      ),




      body:

      loading

          ?

      const Center(

        child:
        CircularProgressIndicator(),

      )


          :


      agents.isEmpty


          ?

      const Center(

        child:
        Text(
          "No trainee data available",
        ),

      )

          :


      RefreshIndicator(

        onRefresh:
        _loadAnalytics,


        child:

        ListView.builder(

          padding:
          const EdgeInsets.all(20),


          itemCount:
          agents.length,


          itemBuilder:

              (context,index){


            return _analyticsCard(

              agents[index],

            );


          },

        ),

      ),

    );

  }

}