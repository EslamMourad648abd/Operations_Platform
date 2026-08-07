import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'training_management.dart';
import 'user_management.dart';
import 'training_analytics_screen.dart';



class PlatformAdminConsole extends StatefulWidget {

  const PlatformAdminConsole({
    super.key,
  });


  @override
  State<PlatformAdminConsole> createState() =>
      _PlatformAdminConsoleState();

}



class _PlatformAdminConsoleState
    extends State<PlatformAdminConsole> {


  FirebaseFunctions? _functions;


  int selectedIndex = 0;


  bool loading = true;


  String? error;





  @override
  void initState(){

    super.initState();

    _initializeFunctions();

  }






  Future<void> _initializeFunctions() async {

    try {


      if(Firebase.apps.isEmpty){

        await Firebase.initializeApp();

      }





      await FirebaseAuth.instance
          .authStateChanges()
          .first;





      _functions =
          FirebaseFunctions.instanceFor(

            region: 'us-central1',

          );





      if(!mounted) return;


      setState(() {

        loading = false;

      });


    }


    catch(e){


      if(!mounted) return;


      setState((){

        error = e.toString();

        loading = false;

      });


    }

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






    if(error != null){


      return Scaffold(

        body:

        Center(

          child:

          Text(

            error!,

            style:

            const TextStyle(

              color: Colors.red,

              fontSize:16,

            ),

          ),

        ),

      );


    }








    final pages = [



      UserManagement(

        functions: _functions!,

      ),





      TrainingManagement(

        functions: _functions!,

      ),






      const TrainingAnalyticsScreen(),



    ];









    return Scaffold(


      backgroundColor:
      const Color(0xffF5F2F7),






      body:

      Row(


        children: [





          NavigationRail(



            selectedIndex:
            selectedIndex,



            labelType:
            NavigationRailLabelType.all,



            onDestinationSelected:(index){



              setState((){


                selectedIndex = index;



              });



            },







            destinations: const [







              NavigationRailDestination(


                icon:

                Icon(
                  Icons.people,
                ),


                label:

                Text(
                  "Users",
                ),


              ),







              NavigationRailDestination(


                icon:

                Icon(
                  Icons.school,
                ),



                label:

                Text(
                  "Training",
                ),



              ),








              NavigationRailDestination(


                icon:

                Icon(
                  Icons.analytics,
                ),



                label:

                Text(
                  "Analytics",
                ),



              ),






            ],



          ),







          const VerticalDivider(

            width:1,

          ),







          Expanded(


            child:

            pages[selectedIndex],


          )




        ],


      ),


    );


  }


}