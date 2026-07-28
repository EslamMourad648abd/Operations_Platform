
// ------------------------------------------------------
// ✅ Firebase Cloud Functions (Node.js 20 - ESM Safe)
// ------------------------------------------------------

import { onRequest, onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2/options";
import fetch from "node-fetch";
import { initializeApp, getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

// ✅ Initialize Firebase Admin safely for Node.js 20 (ESM)
if (!getApps().length) initializeApp();

const auth = getAuth();


// 🌍 Global settings
setGlobalOptions({
  region: "us-central1",
  timeoutSeconds: 60,
});


// ------------------------------------------------------
// 🔐 Roles Configuration
// ------------------------------------------------------

const allowedRoles = [
  "agent",
  "trainee",
  "superadmin",
];


function validateRole(role) {
  if (!allowedRoles.includes(role)) {
    throw new HttpsError(
      "invalid-argument",
      `Invalid role. Allowed roles: ${allowedRoles.join(", ")}`
    );
  }
}


// ------------------------------------------------------
// 🌐 Bevatel Proxy
// ------------------------------------------------------

export const bevatelProxy = onRequest(async (req, res) => {

  res.set("Access-Control-Allow-Origin", "*");
  res.set(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, DELETE, OPTIONS"
  );
  res.set(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization"
  );


  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }


  try {

    const {
      url,
      method,
      headers,
      body
    } = req.body || {};


    if (!url || !method) {
      return res.status(400).json({
        error:"Missing URL or method"
      });
    }


    console.log("➡️ Forwarding request to:", url);


    const bevatelResponse = await fetch(url,{
      method,
      headers,
      body:
        method !== "GET" && body
          ? JSON.stringify(body)
          : undefined,
    });


    const text = await bevatelResponse.text();


    let data;

    try {
      data = JSON.parse(text);
    }
    catch {
      data = text;
    }


    console.log(
      "✅ Proxy OK:",
      bevatelResponse.status
    );


    return res
      .status(bevatelResponse.status)
      .json(data);


  } catch(err){

    console.error(
      "❌ Proxy error:",
      err
    );


    return res.status(500).json({
      error:"Proxy request failed",
      details:err.message,
    });

  }

});



// ------------------------------------------------------
// 👑 Super Admin Management
// ------------------------------------------------------


// 🔒 Permission helper

function requireSuperAdmin(request){

  if(!request?.auth){

    throw new HttpsError(
      "unauthenticated",
      "You must be logged in."
    );

  }


  if(request.auth.token.role !== "superadmin"){

    throw new HttpsError(
      "permission-denied",
      "Only superadmins allowed."
    );

  }

}



// ------------------------------------------------------
// 👤 List all users
// ------------------------------------------------------

export const listUsers = onCall(async(request)=>{

  try{


    requireSuperAdmin(request);


    const list = await auth.listUsers(1000);



    return {

      users:list.users.map((u)=>({

        uid:u.uid,

        email:u.email,

        displayName:
          u.displayName || "",


        role:
          u.customClaims?.role ||
          "trainee",


        disabled:u.disabled,

      }))

    };


  }
  catch(err){

    console.error(
      "🔥 listUsers failed:",
      err
    );


    throw new HttpsError(
      "internal",
      err.message ||
      "Failed to list users."
    );

  }

});




// ------------------------------------------------------
// ➕ Create user
// ------------------------------------------------------

export const createUser = onCall(async(request)=>{


  try{


    requireSuperAdmin(request);



    const {
      email,
      password,
      displayName,
      role
    } = request.data;



    if(!email || !password){

      throw new HttpsError(
        "invalid-argument",
        "Email and password required."
      );

    }



    const userRole =
      role || "trainee";



    validateRole(userRole);



    const user = await auth.createUser({

      email,

      password,

      displayName,

    });



    await auth.setCustomUserClaims(
      user.uid,
      {
        role:userRole
      }
    );



    return {

      uid:user.uid,

      email:user.email,

      role:userRole

    };


  }
  catch(err){

    console.error(
      "🔥 createUser failed:",
      err
    );


    throw new HttpsError(
      "internal",
      err.message ||
      "Failed to create user."
    );

  }


});





// ------------------------------------------------------
// ✏️ Update user
// ------------------------------------------------------

export const updateUser = onCall(async(request)=>{


  try{


    requireSuperAdmin(request);



    const {

      uid,

      email,

      password,

      displayName,

      role,

      disabled

    } = request.data;



    if(!uid){

      throw new HttpsError(
        "invalid-argument",
        "User UID is required."
      );

    }



    const updateData = {};



    if(email)
      updateData.email=email;


    if(password)
      updateData.password=password;


    if(displayName)
      updateData.displayName=displayName;



    if(typeof disabled === "boolean")
      updateData.disabled=disabled;




    const user =
      await auth.updateUser(
        uid,
        updateData
      );



    if(role){

      validateRole(role);


      await auth.setCustomUserClaims(
        uid,
        {
          role
        }
      );

    }




    return {

      uid:user.uid,

      email:user.email

    };


  }
  catch(err){

    console.error(
      "🔥 updateUser failed:",
      err
    );


    throw new HttpsError(
      "internal",
      err.message ||
      "Failed to update user."
    );

  }


});





// ------------------------------------------------------
// ❌ Delete user
// ------------------------------------------------------

export const deleteUser = onCall(async(request)=>{


  try{


    requireSuperAdmin(request);


    const {
      uid
    } = request.data;



    if(!uid){

      throw new HttpsError(
        "invalid-argument",
        "User UID is required."
      );

    }



    await auth.deleteUser(uid);



    return {
      success:true
    };


  }
  catch(err){


    console.error(
      "🔥 deleteUser failed:",
      err
    );


    throw new HttpsError(
      "internal",
      err.message ||
      "Failed to delete user."
    );

  }


});





// ------------------------------------------------------
// 🔄 Set role
// ------------------------------------------------------

export const setUserRole = onCall(async(request)=>{


  try{


    requireSuperAdmin(request);



    const {
      uid,
      role
    } = request.data;



    if(!uid || !role){

      throw new HttpsError(
        "invalid-argument",
        "UID and role are required."
      );

    }



    validateRole(role);



    await auth.setCustomUserClaims(
      uid,
      {
        role
      }
    );



    return {

      uid,

      role,

      success:true

    };


  }
  catch(err){


    console.error(
      "🔥 setUserRole failed:",
      err
    );


    throw new HttpsError(
      "internal",
      err.message ||
      "Failed to update role."
    );

  }


});