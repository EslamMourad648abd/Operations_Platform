// ------------------------------------------------------
// Firebase Cloud Functions (Node.js 20 - ESM Safe)
// ------------------------------------------------------
import {
  onRequest,
  onCall,
  HttpsError,
} from "firebase-functions/v2/https";
import {
  setGlobalOptions,
} from "firebase-functions/v2/options";
import fetch from "node-fetch";
import {
  initializeApp,
  getApps,
} from "firebase-admin/app";
import {
  getAuth,
} from "firebase-admin/auth";
import {
  getFirestore,
  FieldValue,
} from "firebase-admin/firestore";
import drive from "./google_drive_services.js";
// ------------------------------------------------------
// Initialize Firebase Admin
// ------------------------------------------------------
if (!getApps().length) {
  initializeApp();
}
const auth = getAuth();
const db = getFirestore();
// ------------------------------------------------------
// Global Settings
// ------------------------------------------------------
setGlobalOptions({
  region: "us-central1",
  timeoutSeconds: 60,
});
// ------------------------------------------------------
// Roles Configuration
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
// Helper: Resolve Display Name
// ------------------------------------------------------
//
// Rule:
// 1. Use displayName when it is not empty.
// 2. Otherwise use email.
// 3. Never return "Unknown".
// ------------------------------------------------------
function resolveDisplayName(displayName, email) {
  const name =
    typeof displayName === "string"
      ? displayName.trim()
      : "";
  const userEmail =
    typeof email === "string"
      ? email.trim()
      : "";
  return name || userEmail;
}
// ------------------------------------------------------
// Bevatel Proxy
// ------------------------------------------------------
export const bevatelProxy = onRequest(
  async (req, res) => {
    res.set(
      "Access-Control-Allow-Origin",
      "*"
    );
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
        body,
      } = req.body || {};
      if (!url || !method) {
        return res.status(400).json({
          error: "Missing URL or method",
        });
      }
      console.log(
        "➡️ Forwarding request to:",
        url
      );
      const response = await fetch(
        url,
        {
          method,
          headers,
          body:
            method !== "GET" && body
              ? JSON.stringify(body)
              : undefined,
        }
      );
      const text =
        await response.text();
      let data;
      try {
        data = JSON.parse(text);
      } catch {
        data = text;
      }
      return res
        .status(response.status)
        .json(data);
    } catch (error) {
      console.error(
        "Proxy error:",
        error
      );
      return res.status(500).json({
        error:
          error.message ||
          "Proxy request failed",
      });
    }
  }
);
// ------------------------------------------------------
// Super Admin Permission
// ------------------------------------------------------
function requireSuperAdmin(request) {
  if (!request?.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication required"
    );
  }
  if (
    request.auth.token.role !==
    "superadmin"
  ) {
    throw new HttpsError(
      "permission-denied",
      "Super admin only"
    );
  }
}
// ------------------------------------------------------
// List Users
// ------------------------------------------------------
export const listUsers =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const snapshot =
        await db
          .collection("users")
          .get();
      return {
        users:
          snapshot.docs.map((doc) => {
            const data =
              doc.data();
            const email =
              data.email ?? "";
            const displayName =
              resolveDisplayName(
                data.displayName,
                email
              );
            return {
              uid:
                doc.id,
              email:
                email,
              displayName:
                displayName,
              role:
                data.role ?? "trainee",
            };
          }),
      };
    } catch (error) {
      console.error(
        "LIST USERS ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Failed to list users"
      );
    }
  });
// ------------------------------------------------------
// Create User
// ------------------------------------------------------
export const createUser =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const {
        email,
        password,
        displayName,
        role,
      } = request.data;
      if (!email || !password) {
        throw new HttpsError(
          "invalid-argument",
          "Email and password required"
        );
      }
      const normalizedEmail =
        email.trim();
      const resolvedDisplayName =
        resolveDisplayName(
          displayName,
          normalizedEmail
        );
      const userRole =
        role ?? "trainee";
      validateRole(userRole);
      // ----------------------------------------------
      // Create Firebase Authentication user
      // ----------------------------------------------
      const user =
        await auth.createUser({
          email:
            normalizedEmail,
          password,
          displayName:
            resolvedDisplayName,
        });
      // ----------------------------------------------
      // Set Firebase Auth role claim
      // ----------------------------------------------
      await auth.setCustomUserClaims(
        user.uid,
        {
          role: userRole,
        }
      );
      // ----------------------------------------------
      // Create Firestore user document
      // ----------------------------------------------
      await db
        .collection("users")
        .doc(user.uid)
        .set({
          displayName:
            resolvedDisplayName,
          email:
            normalizedEmail,
          role:
            userRole,
          createdAt:
            FieldValue.serverTimestamp(),
        });
      return {
        uid:
          user.uid,
        email:
          normalizedEmail,
        displayName:
          resolvedDisplayName,
        role:
          userRole,
        success:
          true,
      };
    } catch (error) {
      console.error(
        "CREATE USER ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Failed creating user"
      );
    }
  });
// ------------------------------------------------------
// Update User
// ------------------------------------------------------
export const updateUser =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const {
        uid,
        email,
        password,
        displayName,
        role,
        disabled,
      } = request.data;
      if (!uid) {
        throw new HttpsError(
          "invalid-argument",
          "UID required"
        );
      }
      // ----------------------------------------------
      // Get current Firebase Auth user
      // ----------------------------------------------
      const currentUser =
        await auth.getUser(uid);
      const finalEmail =
        email !== undefined &&
        email !== null &&
        email.toString().trim() !== ""
          ? email.toString().trim()
          : currentUser.email ?? "";
      const finalDisplayName =
        resolveDisplayName(
          displayName,
          finalEmail
        );
      // ----------------------------------------------
      // Update Firebase Authentication
      // ----------------------------------------------
      const updateData = {};
      if (
        email !== undefined &&
        email !== null &&
        email.toString().trim() !== ""
      ) {
        updateData.email =
          email.toString().trim();
      }
      if (
        password !== undefined &&
        password !== null &&
        password.toString().trim() !== ""
      ) {
        updateData.password =
          password.toString().trim();
      }
      // Always update displayName.
      //
      // If the admin clears the name,
      // it becomes the email instead.
      updateData.displayName =
        finalDisplayName;
      if (
        typeof disabled ===
        "boolean"
      ) {
        updateData.disabled =
          disabled;
      }
      const user =
        await auth.updateUser(
          uid,
          updateData
        );
      // ----------------------------------------------
      // Update Firebase Auth role
      // ----------------------------------------------
      let finalRole =
        role;
      if (role) {
        validateRole(role);
        await auth.setCustomUserClaims(
          uid,
          {
            role,
          }
        );
      } else {
        finalRole =
          currentUser.customClaims?.role ??
          "trainee";
      }
      // ----------------------------------------------
      // Update Firestore user document
      // ----------------------------------------------
      await db
        .collection("users")
        .doc(uid)
        .set({
          displayName:
            finalDisplayName,
          email:
            finalEmail,
          role:
            finalRole,
          updatedAt:
            FieldValue.serverTimestamp(),
        }, {
          merge: true,
        });
      return {
        success:
          true,
        uid:
          user.uid,
        email:
          finalEmail,
        displayName:
          finalDisplayName,
        role:
          finalRole,
      };
    } catch (error) {
      console.error(
        "UPDATE USER ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Failed updating user"
      );
    }
  });
// ------------------------------------------------------
// Delete User
// ------------------------------------------------------
export const deleteUser =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const {
        uid,
      } = request.data;
      if (!uid) {
        throw new HttpsError(
          "invalid-argument",
          "UID required"
        );
      }
      // Delete Firebase Authentication user
      await auth.deleteUser(uid);
      // Delete Firestore user document
      await db
        .collection("users")
        .doc(uid)
        .delete();
      return {
        success: true,
      };
    } catch (error) {
      console.error(
        "DELETE USER ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Failed deleting user"
      );
    }
  });
// ------------------------------------------------------
// Set User Role
// ------------------------------------------------------
export const setUserRole =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const {
        uid,
        role,
      } = request.data;
      if (!uid || !role) {
        throw new HttpsError(
          "invalid-argument",
          "UID and role required"
        );
      }
      validateRole(role);
      // ----------------------------------------------
      // Update Firebase Auth claim
      // ----------------------------------------------
      await auth.setCustomUserClaims(
        uid,
        {
          role,
        }
      );
      // ----------------------------------------------
      // Update Firestore role
      // ----------------------------------------------
      await db
        .collection("users")
        .doc(uid)
        .set({
          role,
          updatedAt:
            FieldValue.serverTimestamp(),
        }, {
          merge: true,
        });
      return {
        success:
          true,
        uid,
        role,
      };
    } catch (error) {
      console.error(
        "SET ROLE ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Failed updating role"
      );
    }
  });
// ------------------------------------------------------
// Sync Google Drive Lessons
// ------------------------------------------------------
export const syncCourseLessons =
  onCall(async (request) => {
    console.log(
      "SYNC COURSE LESSONS START"
    );
    try {
      requireSuperAdmin(request);
      const {
        courseId,
        folderId,
      } = request.data;
      if (!courseId || !folderId) {
        throw new HttpsError(
          "invalid-argument",
          "courseId and folderId required"
        );
      }
      // ----------------------------------------------
      // Read Google Drive videos
      // ----------------------------------------------
      const response =
        await drive.files.list({
          q:
            `'${folderId}' in parents and mimeType contains 'video/' and trashed = false`,
          fields:
            "files(id,name,webViewLink)",
        });
      const files =
        response.data.files || [];
      console.log(
        "Videos found:",
        files.length
      );
      // ----------------------------------------------
      // Lessons collection
      // ----------------------------------------------
      const lessonsRef =
        db
          .collection("courses")
          .doc(courseId)
          .collection("lessons");
      const batch =
        db.batch();
      let created = 0;
      // ----------------------------------------------
      // Process videos
      // ----------------------------------------------
      for (
        const file of files
      ) {
        const existing =
          await lessonsRef
            .where(
              "videoId",
              "==",
              file.id
            )
            .get();
        if (!existing.empty) {
          continue;
        }
        batch.set(
          lessonsRef.doc(),
          {
            title:
              file.name,
            videoUrl:
              file.webViewLink,
            videoId:
              file.id,
            createdAt:
              FieldValue.serverTimestamp(),
          }
        );
        created++;
      }
      await batch.commit();
      // ----------------------------------------------
      // Update course lesson count
      // ----------------------------------------------
      const snapshot =
        await lessonsRef.get();
      await db
        .collection("courses")
        .doc(courseId)
        .update({
          lessonsCount:
            snapshot.size,
        });
      return {
        success:
          true,
        lessonsFound:
          files.length,
        lessonsCreated:
          created,
        totalLessons:
          snapshot.size,
      };
    } catch (error) {
      console.error(
        "SYNC LESSONS ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Sync failed"
      );
    }
  });
// =====================================================
// MIGRATE USER ROLES TO FIRESTORE
// =====================================================
export const migrateUserRolesToFirestore =
  onCall(async (request) => {
    try {
      requireSuperAdmin(request);
      const list =
        await auth.listUsers(1000);
      let migrated = 0;
      for (
        const user of list.users
      ) {
        const role =
          user.customClaims?.role;
        if (!role) {
          continue;
        }
        const email =
          user.email ?? "";
        const displayName =
          resolveDisplayName(
            user.displayName,
            email
          );
        await db
          .collection("users")
          .doc(user.uid)
          .set({
            displayName,
            email,
            role,
            updatedAt:
              FieldValue.serverTimestamp(),
          }, {
            merge: true,
          });
        migrated++;
      }
      return {
        success:
          true,
        migrated,
      };
    } catch (error) {
      console.error(
        "MIGRATION ERROR:",
        error
      );
      throw new HttpsError(
        "internal",
        error.message ||
          "Migration failed"
      );
    }
  });