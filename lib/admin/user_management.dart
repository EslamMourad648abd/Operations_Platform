import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';


class UserManagement extends StatefulWidget {

  final FirebaseFunctions functions;


  const UserManagement({
    super.key,
    required this.functions,
  });


  @override
  State<UserManagement> createState() =>
      _UserManagementState();

}



class _UserManagementState extends State<UserManagement> {


  List<Map<String,dynamic>> users = [];

  List<Map<String,dynamic>> filteredUsers = [];

  bool loading = true;

  String? error;

  String searchQuery = "";



  @override
  void initState(){

    super.initState();

    _loadUsers();

  }





  Future<void> _loadUsers() async {


    if (!mounted) return;

    setState((){

      loading = true;

      error = null;

    });


    try{


      final callable =
      widget.functions.httpsCallable(
        "listUsers",
      );


      final result =
      await callable();



      final data =
          result.data;



      if(data is Map &&
          data["users"] is List){


        final loaded =
        List<Map<String,dynamic>>.from(
          data["users"],
        );


        if (!mounted) return;

        setState((){

          users = loaded;

          filteredUsers = loaded;

          loading = false;

        });


      }
      else{

        throw Exception(
          "Invalid users response",
        );

      }


    }
    catch(e){


      if (!mounted) return;

      setState((){

        error = e.toString();

        loading = false;

      });


    }


  }







  void _searchUsers(String value){


    setState((){


      searchQuery =
          value.toLowerCase();



      if(value.isEmpty){

        filteredUsers = users;

      }
      else{


        filteredUsers =
            users.where((user){


              final email =
              (user["email"] ?? "")
                  .toString()
                  .toLowerCase();



              final name =
              (user["displayName"] ?? "")
                  .toString()
                  .toLowerCase();



              return email.contains(searchQuery)
                  ||
                  name.contains(searchQuery);


            }).toList();



      }


    });


  }








  Future<void> _addUser(
      Map<String,dynamic> data
      ) async {


    try{


      final callable =
      widget.functions.httpsCallable(
        "createUser",
      );



      await callable(data);



      _showMessage(
        "User created successfully",
        Colors.green,
      );



      _loadUsers();


    }
    catch(e){


      _showMessage(
        e.toString(),
        Colors.red,
      );


    }


  }








  Future<void> _editUser(
      Map<String,dynamic> data
      ) async {


    try{


      final callable =
      widget.functions.httpsCallable(
        "updateUser",
      );



      await callable(data);



      _showMessage(
        "User updated successfully",
        Colors.green,
      );



      _loadUsers();


    }
    catch(e){


      _showMessage(
        e.toString(),
        Colors.red,
      );


    }


  }








  Future<void> _deleteUser(
      String uid
      ) async {


    try{


      final callable =
      widget.functions.httpsCallable(
        "deleteUser",
      );


      await callable({

        "uid":uid,

      });



      _showMessage(
        "User deleted",
        Colors.green,
      );



      _loadUsers();


    }
    catch(e){


      _showMessage(
        e.toString(),
        Colors.red,
      );


    }


  }









  Future<void> _updateRole(
      String uid,
      String role
      ) async {


    try{


      final callable =
      widget.functions.httpsCallable(
        "setUserRole",
      );



      await callable({

        "uid":uid,

        "role":role,

      });



      _loadUsers();


    }
    catch(e){


      _showMessage(
        e.toString(),
        Colors.red,
      );


    }


  }









  void _showMessage(
      String text,
      Color color
      ){


    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(

        content:
        Text(text),

        backgroundColor:
        color,

      ),

    );


  }









  void _showAddDialog(){


    final name =
    TextEditingController();

    final email =
    TextEditingController();

    final password =
    TextEditingController();


    String role = "agent";



    showDialog(

      context: context,

      builder:(context){


        return StatefulBuilder(

          builder:(context,setDialogState){


            return AlertDialog(

              title:
              const Text(
                "Add User",
              ),



              content:
              Column(

                mainAxisSize:
                MainAxisSize.min,

                children:[


                  TextField(

                    controller:name,

                    decoration:
                    const InputDecoration(
                      labelText:"Name",
                    ),

                  ),


                  TextField(

                    controller:email,

                    decoration:
                    const InputDecoration(
                      labelText:"Email",
                    ),

                  ),


                  TextField(

                    controller:password,

                    obscureText:true,

                    decoration:
                    const InputDecoration(
                      labelText:"Password",
                    ),

                  ),



                  DropdownButtonFormField<String>(

                    value:role,


                    decoration:
                    const InputDecoration(
                      labelText:"Role",
                    ),


                    items:
                    _roles(),


                    onChanged:(value){

                      setDialogState((){

                        role=value!;

                      });

                    },


                  ),


                ],

              ),




              actions:[


                TextButton(

                  onPressed:(){

                    Navigator.pop(context);

                  },

                  child:
                  const Text(
                    "Cancel",
                  ),

                ),




                ElevatedButton(

                  onPressed:(){


                    _addUser({

                      "displayName":
                      name.text.trim(),

                      "email":
                      email.text.trim(),

                      "password":
                      password.text.trim(),

                      "role":
                      role,


                    });



                    Navigator.pop(context);


                  },


                  child:
                  const Text(
                    "Create",
                  ),

                ),


              ],


            );


          },

        );


      },

    );


  }









  void _showEditDialog(
      Map<String,dynamic> user
      ){


    final name =
    TextEditingController(
      text:user["displayName"] ?? "",
    );


    final email =
    TextEditingController(
      text:user["email"] ?? "",
    );


    final password =
    TextEditingController();



    String role =
        user["role"] ?? "agent";



    showDialog(

      context:context,

      builder:(context){


        return StatefulBuilder(

          builder:(context,setDialogState){


            return AlertDialog(

              title:
              const Text(
                "Edit User",
              ),



              content:
              Column(

                mainAxisSize:
                MainAxisSize.min,

                children:[


                  TextField(

                    controller:name,

                    decoration:
                    const InputDecoration(
                      labelText:"Name",
                    ),

                  ),



                  TextField(

                    controller:email,

                    decoration:
                    const InputDecoration(
                      labelText:"Email",
                    ),

                  ),



                  TextField(

                    controller:password,

                    obscureText:true,

                    decoration:
                    const InputDecoration(
                      labelText:
                      "New Password (optional)",
                    ),

                  ),



                  DropdownButtonFormField<String>(

                    value:role,

                    items:
                    _roles(),


                    onChanged:(value){

                      setDialogState((){

                        role=value!;

                      });

                    },


                  ),


                ],

              ),




              actions:[


                TextButton(

                  onPressed:(){

                    Navigator.pop(context);

                  },

                  child:
                  const Text(
                    "Cancel",
                  ),

                ),



                ElevatedButton(

                  onPressed:(){


                    _editUser({

                      "uid":
                      user["uid"],


                      "displayName":
                      name.text.trim(),


                      "email":
                      email.text.trim(),


                      "role":
                      role,


                      if(password.text.trim().isNotEmpty)

                        "password":
                        password.text.trim(),


                    });



                    Navigator.pop(context);


                  },


                  child:
                  const Text(
                    "Save",
                  ),

                ),


              ],


            );


          },

        );


      },


    );


  }








  List<DropdownMenuItem<String>> _roles(){


    return const [

      DropdownMenuItem(

        value:"agent",

        child:
        Text(
          "Agent",
        ),

      ),


      DropdownMenuItem(

        value:"trainee",

        child:
        Text(
          "Trainee",
        ),

      ),


      DropdownMenuItem(

        value:"superadmin",

        child:
        Text(
          "Super Admin",
        ),

      ),


    ];

  }









  Future<void> _confirmDelete(
      Map<String,dynamic> user
      ) async {


    final result =
    await showDialog<bool>(

      context:context,

      builder:(context)=>AlertDialog(

        title:
        const Text(
          "Delete User",
        ),


        content:
        Text(
          "Delete ${user["email"]} ?",
        ),


        actions:[


          TextButton(

            onPressed:(){

              Navigator.pop(
                context,
                false,
              );

            },

            child:
            const Text(
              "Cancel",
            ),

          ),



          ElevatedButton(

            onPressed:(){

              Navigator.pop(
                context,
                true,
              );

            },

            child:
            const Text(
              "Delete",
            ),

          ),


        ],

      ),

    );



    if(result == true){

      _deleteUser(
        user["uid"],
      );

    }


  }









  @override
  Widget build(BuildContext context){


    if(loading){

      return const Center(
        child:
        CircularProgressIndicator(),
      );

    }



    if(error != null){

      return Center(
        child:
        Text(
          error!,
          style:
          const TextStyle(
            color:Colors.red,
          ),
        ),
      );

    }




    return Column(

      children:[


        Padding(

          padding:
          const EdgeInsets.all(20),

          child:Row(

            children:[


              const Text(

                "User Management",

                style:
                TextStyle(

                  fontSize:22,

                  fontWeight:
                  FontWeight.bold,

                ),

              ),



              const Spacer(),



              ElevatedButton.icon(

                onPressed:
                _showAddDialog,

                icon:
                const Icon(
                  Icons.add,
                ),

                label:
                const Text(
                  "Add User",
                ),

              ),



              const SizedBox(
                width:20,
              ),



              SizedBox(

                width:250,

                child:TextField(

                  onChanged:
                  _searchUsers,

                  decoration:
                  const InputDecoration(

                    hintText:
                    "Search",

                    prefixIcon:
                    Icon(
                      Icons.search,
                    ),

                  ),

                ),

              ),


            ],

          ),

        ),





        Expanded(

          child:
          ListView.builder(

            itemCount:
            filteredUsers.length,


            itemBuilder:(context,index){


              final user =
              filteredUsers[index];



              return Card(

                margin:
                const EdgeInsets.symmetric(
                  horizontal:20,
                  vertical:6,
                ),


                child:ListTile(


                  title:
                  Text(
                    user["email"] ?? "-",
                  ),



                  subtitle:
                  Text(
                    user["displayName"] ?? "",
                  ),



                  trailing:
                  Row(

                    mainAxisSize:
                    MainAxisSize.min,


                    children:[



                      DropdownButton<String>(

                        value:
                        user["role"] ?? "agent",


                        items:
                        _roles(),


                        onChanged:(value){

                          if(value != null){

                            _updateRole(
                              user["uid"],
                              value,
                            );

                          }

                        },

                      ),




                      IconButton(

                        icon:
                        const Icon(
                          Icons.edit,
                        ),

                        onPressed:(){

                          _showEditDialog(
                            user,
                          );

                        },

                      ),




                      IconButton(

                        icon:
                        const Icon(
                          Icons.delete,
                          color:Colors.red,
                        ),


                        onPressed:(){

                          _confirmDelete(
                            user,
                          );

                        },

                      ),


                    ],

                  ),


                ),

              );


            },

          ),

        )


      ],

    );


  }


}