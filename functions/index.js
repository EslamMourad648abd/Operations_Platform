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
import {
  getStorage,
} from "firebase-admin/storage";
import PDFDocument from "pdfkit";
import drive from "./google_drive_services.js";
// ------------------------------------------------------
// Initialize Firebase Admin
// ------------------------------------------------------
if (!getApps().length) {
  initializeApp();
}
const auth = getAuth();
const db = getFirestore();
const storage = getStorage();
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
      let finalRole = role;
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
        .set(
          {
            displayName:
              finalDisplayName,
            email:
              finalEmail,
            role:
              finalRole,
            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );
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
        success:
          true,
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
        .set(
          {
            role,
            updatedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );
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
          .collection("training_courses")
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
        .collection("training_courses")
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
          .set(
            {
              displayName,
              email,
              role,
              updatedAt:
                FieldValue.serverTimestamp(),
            },
            {
              merge: true,
            }
          );
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
  // =====================================================
  // GENERATE / REGENERATE CERTIFICATE
  // =====================================================
  //
  // Certificate generation rules:
  //
  // - Authenticated trainee only
  // - Course must be 100% completed
  // - Actual course lessons are the source of truth
  // - Quiz score is calculated server-side
  // - Certificate is ALWAYS regenerated
  // - Existing certificate PDF is overwritten
  // - Existing certificate Firestore document is updated
  // - PDF is A4 LANDSCAPE
  // - Bevatel corporate identity
  //
  // =====================================================
  export const generateCertificate = onCall(
    async (request) => {
      try {
        // =================================================
        // AUTHENTICATION
        // =================================================
        if (!request.auth) {
          throw new HttpsError(
            "unauthenticated",
            "Authentication required"
          );
        }
        const userId = request.auth.uid;
        const courseId =
          request.data?.courseId;
        if (!courseId) {
          throw new HttpsError(
            "invalid-argument",
            "courseId is required"
          );
        }
        console.log(
          "=============================================="
        );
        console.log(
          "GENERATE CERTIFICATE START"
        );
        console.log(
          "User:",
          userId
        );
        console.log(
          "Course:",
          courseId
        );
        // =================================================
        // GET USER
        // =================================================
        const userRecord =
          await auth.getUser(userId);
        const userName =
          resolveDisplayName(
            userRecord.displayName,
            userRecord.email
          );
        console.log(
          "Trainee:",
          userName
        );
        // =================================================
        // GET COURSE
        // =================================================
        const courseRef =
          db
            .collection("training_courses")
            .doc(courseId);
        const courseSnapshot =
          await courseRef.get();
        if (!courseSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "Course not found"
          );
        }
        const courseData =
          courseSnapshot.data() || {};
        const courseTitle =
          courseData.title ||
          courseId;
        console.log(
          "Course title:",
          courseTitle
        );
        // =================================================
        // GET ACTUAL COURSE LESSONS
        // =================================================
        const courseLessonsSnapshot =
          await courseRef
            .collection("lessons")
            .get();
        if (
          courseLessonsSnapshot.empty
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Course has no lessons"
          );
        }
        const actualLessonIds =
          new Set(
            courseLessonsSnapshot.docs.map(
              (doc) => doc.id
            )
          );
        const totalLessons =
          courseLessonsSnapshot.size;
        console.log(
          "Actual course lessons:",
          totalLessons
        );
        // =================================================
        // GET USER PROGRESS
        // =================================================
        const progressSnapshot =
          await db
            .collection("users")
            .doc(userId)
            .collection("training_progress")
            .doc(courseId)
            .collection("lessons")
            .get();
        if (
          progressSnapshot.empty
        ) {
          throw new HttpsError(
            "failed-precondition",
            "No course progress found"
          );
        }
        // =================================================
        // CALCULATE COMPLETION
        // =================================================
        let completedLessons = 0;
        let totalQuizScore = 0;
        let submittedQuizCount = 0;
        let latestCompletionDate =
          null;
        for (
          const lessonDoc
          of progressSnapshot.docs
        ) {
          // -----------------------------------------------
          // Ignore old/orphaned progress
          // -----------------------------------------------
          if (
            !actualLessonIds.has(
              lessonDoc.id
            )
          ) {
            continue;
          }
          const data =
            lessonDoc.data() || {};
          // -----------------------------------------------
          // COMPLETION
          // -----------------------------------------------
          if (
            data.completed === true
          ) {
            completedLessons++;
            const completedAt =
              data.completedAt;
            if (
              completedAt &&
              typeof completedAt.toDate ===
                "function"
            ) {
              const completionDate =
                completedAt.toDate();
              if (
                latestCompletionDate === null ||
                completionDate >
                  latestCompletionDate
              ) {
                latestCompletionDate =
                  completionDate;
              }
            }
          }
          // -----------------------------------------------
          // QUIZ
          // -----------------------------------------------
          if (
            data.quizSubmitted === true
          ) {
            const score =
              Number(
                data.score ?? 0
              );
            if (
              Number.isFinite(score)
            ) {
              totalQuizScore += score;
              submittedQuizCount++;
            }
          }
        }
        // =================================================
        // VERIFY 100%
        // =================================================
        console.log(
          "Completed lessons:",
          completedLessons,
          "/",
          totalLessons
        );
        if (
          totalLessons === 0 ||
          completedLessons < totalLessons
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Course must be 100% completed before generating a certificate"
          );
        }
        // =================================================
        // AVERAGE QUIZ SCORE
        // =================================================
        const averageQuizScore =
          submittedQuizCount === 0
            ? 0
            : totalQuizScore /
              submittedQuizCount;
        console.log(
          "Quiz count:",
          submittedQuizCount
        );
        console.log(
          "Quiz average:",
          averageQuizScore
        );
        // =================================================
        // CERTIFICATE ID
        // =================================================
        const certificateId =
          `${userId}_${courseId}`;
        const certificateRef =
          db
            .collection("certificates")
            .doc(certificateId);
        // =================================================
        // GET EXISTING CERTIFICATE
        // =================================================
        const existingCertificate =
          await certificateRef.get();

        const existingData =
          existingCertificate.exists
            ? existingCertificate.data() || {}
            : {};

        // =================================================
        // RETURN EXISTING CERTIFICATE
        // =================================================
        //
        // A certificate is generated only once per
        // trainee + course.
        //
        // If a valid certificate already exists,
        // return it immediately.
        //
        // This prevents:
        // - generating another PDF
        // - deleting the existing PDF
        // - uploading another PDF
        // - updating the Firestore certificate record
        //
        // =================================================

        if (
          existingCertificate.exists &&
          existingData.certificateUrl &&
          existingData.storagePath
        ) {
          console.log(
            "Existing certificate found."
          );

          console.log(
            "Returning existing certificate without regeneration."
          );

          return {
            success: true,
            existing: true,
            regenerated: false,
            certificate: {
              id: certificateId,
              userId:
                existingData.userId || userId,
              traineeName:
                existingData.traineeName || userName,
              courseId:
                existingData.courseId || courseId,
              courseTitle:
                existingData.courseTitle || courseTitle,
              certificateNumber:
                existingData.certificateNumber,
              certificateUrl:
                existingData.certificateUrl,
              issuedAt:
                existingData.issuedAt || null,
              storagePath:
                existingData.storagePath,
              totalLessons:
                existingData.totalLessons ??
                totalLessons,
              completedLessons:
                existingData.completedLessons ??
                completedLessons,
              averageQuizScore:
                existingData.averageQuizScore ??
                averageQuizScore,
              submittedQuizCount:
                existingData.submittedQuizCount ??
                submittedQuizCount,
              totalQuizScore:
                existingData.totalQuizScore ??
                totalQuizScore,
            },
          };
        }
        // =================================================
        // PRESERVE CERTIFICATE NUMBER
        // =================================================
        const certificateNumber =
          existingData.certificateNumber ||
          `CERT-${new Date().getFullYear()}-${Date.now()}`;
        // =================================================
        // ISSUED DATE
        // =================================================
        const issuedAt =
          latestCompletionDate ||
          new Date();
        // =================================================
        // STORAGE PATH
        // =================================================
        //
        // Same path intentionally.
        //
        // Saving the new PDF here replaces the previous
        // certificate file.
        //
        // =================================================
        const storagePath =
          `certificates/${userId}/${courseId}/certificate.pdf`;
      // =================================================
      // PDF GENERATION
      // =================================================

      console.log(
        "Generating refined A4 LANDSCAPE certificate PDF..."
      );

      const pdfBuffer =
        await new Promise(
          (resolve, reject) => {
            const document =
              new PDFDocument({
                size: "A4",
                layout: "landscape",
                margin: 0,
                info: {
                  Title:
                    `Certificate of Completion - ${courseTitle}`,
                  Author:
                    "Bevatel",
                  Subject:
                    "Training Certificate",
                  Creator:
                    "Bevatel Training Portal",
                },
              });

            const chunks = [];

            document.on(
              "data",
              (chunk) => {
                chunks.push(chunk);
              }
            );

            document.on(
              "end",
              () => {
                resolve(
                  Buffer.concat(chunks)
                );
              }
            );

            document.on(
              "error",
              reject
            );

            // =================================================
            // COLORS
            // =================================================

            const NAVY =
              "#152B5B";

            const DARK_NAVY =
              "#10244D";

            const BLUE =
              "#315F98";

            const LIGHT_BLUE =
              "#76A7D1";

            const PALE_BLUE =
              "#B8D0E4";

            const PINK =
              "#F5E9EC";

            const LIGHT_PINK =
              "#F9F0F2";

            const DARK_TEXT =
              "#252B35";

            const GREY =
              "#6D7480";

            const WHITE =
              "#FFFFFF";

            const SOFT_GREY =
              "#A7ADB6";

            // =================================================
            // PAGE SIZE
            // =================================================

            const pageWidth =
              document.page.width;

            const pageHeight =
              document.page.height;

            // =================================================
            // BASE BACKGROUND
            // =================================================

            document
              .rect(
                0,
                0,
                pageWidth,
                pageHeight
              )
              .fill(
                PINK
              );

            // =================================================
            // MAIN NAVY RIGHT PANEL
            // =================================================

            /*
             * The reference certificate has a large dark
             * geometric area occupying the right side.
             */

            document
              .save()
              .moveTo(
                pageWidth * 0.57,
                0
              )
              .lineTo(
                pageWidth,
                0
              )
              .lineTo(
                pageWidth,
                pageHeight
              )
              .lineTo(
                pageWidth * 0.44,
                pageHeight
              )
              .bezierCurveTo(
                pageWidth * 0.50,
                pageHeight * 0.77,
                pageWidth * 0.54,
                pageHeight * 0.47,
                pageWidth * 0.57,
                0
              )
              .closePath()
              .fill(
                NAVY
              )
              .restore();

            // =================================================
            // INNER BLUE CURVE
            // =================================================

            document
              .save()
              .moveTo(
                pageWidth * 0.54,
                0
              )
              .bezierCurveTo(
                pageWidth * 0.51,
                pageHeight * 0.38,
                pageWidth * 0.47,
                pageHeight * 0.72,
                pageWidth * 0.40,
                pageHeight
              )
              .lineTo(
                pageWidth * 0.44,
                pageHeight
              )
              .bezierCurveTo(
                pageWidth * 0.51,
                pageHeight * 0.69,
                pageWidth * 0.55,
                pageHeight * 0.37,
                pageWidth * 0.58,
                0
              )
              .closePath()
              .fill(
                BLUE
              )
              .restore();

            // =================================================
            // SECOND BLUE SHADE
            // =================================================

            document
              .save()
              .moveTo(
                pageWidth * 0.59,
                0
              )
              .bezierCurveTo(
                pageWidth * 0.57,
                pageHeight * 0.35,
                pageWidth * 0.53,
                pageHeight * 0.70,
                pageWidth * 0.47,
                pageHeight
              )
              .lineTo(
                pageWidth * 0.50,
                pageHeight
              )
              .bezierCurveTo(
                pageWidth * 0.56,
                pageHeight * 0.70,
                pageWidth * 0.60,
                pageHeight * 0.32,
                pageWidth * 0.62,
                0
              )
              .closePath()
              .fill(
                DARK_NAVY
              )
              .restore();

            // =================================================
            // BEVATEL BRANDING
            // =================================================

            /*
             * Kept as text because the current function does not
             * have an actual Bevatel logo asset available.
             */

            document
              .fillColor(
                WHITE
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(18)
              .text(
                "BEVATEL",
                pageWidth - 160,
                38,
                {
                  width: 115,
                  align: "right",
                }
              );

            document
              .fillColor(
                "#D6DDEA"
              )
              .font(
                "Helvetica"
              )
              .fontSize(6.5)
              .text(
                "BUSINESS CHAT",
                pageWidth - 160,
                61,
                {
                  width: 115,
                  align: "right",
                  characterSpacing: 0.6,
                }
              );

            // =================================================
            // DECORATIVE BRAND CIRCLE
            // =================================================

            const brandCircleX =
              pageWidth - 58;

            const brandCircleY =
              92;

            document
              .save()
              .circle(
                brandCircleX,
                brandCircleY,
                19
              )
              .fill(
                "#D8E3EC"
              )
              .restore();

            document
              .save()
              .circle(
                brandCircleX - 5,
                brandCircleY - 5,
                13
              )
              .fill(
                BLUE
              )
              .restore();

            document
              .save()
              .circle(
                brandCircleX + 5,
                brandCircleY + 5,
                9
              )
              .fill(
                "#6D9D80"
              )
              .restore();

            // =================================================
            // CERTIFICATE TITLE
            // =================================================

            document
              .fillColor(
                WHITE
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(38)
              .text(
                "CERTIFICATE",
                pageWidth * 0.61,
                125,
                {
                  width:
                    pageWidth * 0.34,
                  align: "left",
                  characterSpacing: 0.6,
                }
              );

            document
              .fillColor(
                "#E4D4DA"
              )
              .font(
                "Helvetica"
              )
              .fontSize(17)
              .text(
                "OF COMPLETION",
                pageWidth * 0.615,
                178,
                {
                  width:
                    pageWidth * 0.32,
                  align: "left",
                  characterSpacing: 1.4,
                }
              );

            // =================================================
            // SMALL DECORATIVE LINE
            // =================================================

            document
              .moveTo(
                pageWidth * 0.615,
                207
              )
              .lineTo(
                pageWidth * 0.75,
                207
              )
              .lineWidth(1)
              .strokeColor(
                LIGHT_BLUE
              )
              .stroke();

            // =================================================
            // MAIN CONTENT AREA
            // =================================================

            const contentWidth =
              pageWidth * 0.43;

            const contentX =
              pageWidth * 0.055;

            // =================================================
            // INTRODUCTION
            // =================================================

            document
              .fillColor(
                GREY
              )
              .font(
                "Helvetica"
              )
              .fontSize(11)
              .text(
                "This certificate is proudly presented to",
                contentX,
                125,
                {
                  width:
                    contentWidth,
                  align: "center",
                }
              );

            // =================================================
            // TRAINEE NAME
            // =================================================

            let traineeFontSize =
              31;

            const traineeNameWidth =
              contentWidth - 35;

            while (
              traineeFontSize > 18 &&
              document.widthOfString(
                userName,
                {
                  font:
                    "Helvetica-Bold",
                  size:
                    traineeFontSize,
                }
              ) >
                traineeNameWidth
            ) {
              traineeFontSize--;
            }

            document
              .fillColor(
                NAVY
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(
                traineeFontSize
              )
              .text(
                userName,
                contentX + 17,
                157,
                {
                  width:
                    traineeNameWidth,
                  align: "center",
                }
              );

            // =================================================
            // NAME DECORATIVE LINE
            // =================================================

            const nameLineWidth =
              150;

            const nameLineX =
              contentX +
              (
                contentWidth -
                nameLineWidth
              ) /
                2;

            document
              .moveTo(
                nameLineX,
                203
              )
              .lineTo(
                nameLineX +
                  nameLineWidth,
                203
              )
              .lineWidth(1.2)
              .strokeColor(
                BLUE
              )
              .stroke();

            // =================================================
            // COMPLETION MESSAGE
            // =================================================

            document
              .fillColor(
                DARK_TEXT
              )
              .font(
                "Helvetica"
              )
              .fontSize(10.5)
              .text(
                "for successfully completing the training course",
                contentX,
                225,
                {
                  width:
                    contentWidth,
                  align: "center",
                }
              );

            // =================================================
            // COURSE TITLE
            // =================================================

            let courseFontSize =
              21;

            const courseWidth =
              contentWidth - 35;

            while (
              courseFontSize > 13 &&
              document.widthOfString(
                courseTitle,
                {
                  font:
                    "Helvetica-Bold",
                  size:
                    courseFontSize,
                }
              ) >
                courseWidth
            ) {
              courseFontSize--;
            }

            document
              .fillColor(
                NAVY
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(
                courseFontSize
              )
              .text(
                courseTitle,
                contentX + 17,
                255,
                {
                  width:
                    courseWidth,
                  align: "center",
                  lineGap: 3,
                }
              );

            // =================================================
            // APPRECIATION TEXT
            // =================================================

            const appreciationText =
              "Your commitment, dedication, professionalism, and consistent "
              +
              "effort have contributed to the successful completion of "
              +
              "this training journey. We appreciate your continued pursuit "
              +
              "of learning and professional development.";

            document
              .fillColor(
                DARK_TEXT
              )
              .font(
                "Helvetica"
              )
              .fontSize(8.5)
              .text(
                appreciationText,
                contentX + 20,
                315,
                {
                  width:
                    contentWidth - 40,
                  align: "center",
                  lineGap: 3,
                }
              );

            // =================================================
            // COMPLETION STATEMENT
            // =================================================

            document
              .fillColor(
                GREY
              )
              .font(
                "Helvetica"
              )
              .fontSize(8)
              .text(
                `Successfully completed ${completedLessons} of ${totalLessons} lessons`
                +
                ` • Average quiz score: ${averageQuizScore.toFixed(1)}%`,
                contentX + 15,
                375,
                {
                  width:
                    contentWidth - 30,
                  align: "center",
                }
              );

            // =================================================
            // SIGNATURE AREA
            // =================================================

            const signatureY =
              pageHeight - 83;

            const signatureWidth =
              125;

            const signature1X =
              48;

            const signature2X =
              210;

            const signature3X =
              372;

            // -----------------------------------------------
            // Signature 1
            // -----------------------------------------------

            document
              .moveTo(
                signature1X,
                signatureY
              )
              .lineTo(
                signature1X +
                  signatureWidth,
                signatureY
              )
              .lineWidth(0.7)
              .strokeColor(
                SOFT_GREY
              )
              .stroke();

            document
              .fillColor(
                DARK_TEXT
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(7)
              .text(
                "TRAINING DEPARTMENT",
                signature1X,
                signatureY + 7,
                {
                  width:
                    signatureWidth,
                  align: "center",
                }
              );

            document
              .fillColor(
                GREY
              )
              .font(
                "Helvetica"
              )
              .fontSize(6.5)
              .text(
                "Bevatel",
                signature1X,
                signatureY + 19,
                {
                  width:
                    signatureWidth,
                  align: "center",
                }
              );

            // -----------------------------------------------
            // Signature 2
            // -----------------------------------------------

            document
              .moveTo(
                signature2X,
                signatureY
              )
              .lineTo(
                signature2X +
                  signatureWidth,
                signatureY
              )
              .lineWidth(0.7)
              .strokeColor(
                SOFT_GREY
              )
              .stroke();

            document
              .fillColor(
                DARK_TEXT
              )
              .font(
                "Helvetica-Bold"
              )
              .fontSize(7)
              .text(
                "BEVATEL",
                signature2X,
                signatureY + 7,
                {
                  width:
                    signatureWidth,
                  align: "center",
                }
              );

            document
              .fillColor(
                GREY
              )
              .font(
                "Helvetica"
              )
              .fontSize(6.5)
              .text(
                "Authorized Signature",
                signature2X,
                signatureY + 19,
                {
                  width:
                    signatureWidth,
                  align: "center",
                }
              );

            // =================================================
            // DATE
            // =================================================

            document
              .fillColor(
                GREY
              )
              .font(
                "Helvetica"
              )
              .fontSize(7)
              .text(
                `Issued: ${formatCertificateDate(issuedAt)}`,
                contentX,
                pageHeight - 25,
                {
                  width:
                    contentWidth,
                  align: "center",
                }
              );

            // =================================================
            // CERTIFICATE NUMBER
            // =================================================

            document
              .fillColor(
                "#D5DCE6"
              )
              .font(
                "Helvetica"
              )
              .fontSize(6)
              .text(
                `Certificate No: ${certificateNumber}`,
                pageWidth * 0.63,
                pageHeight - 32,
                {
                  width:
                    pageWidth * 0.30,
                  align: "right",
                }
              );

            // =================================================
            // RIGHT PANEL DECORATIVE ELEMENTS
            // =================================================

            // Large soft circle

            document
              .save()
              .circle(
                pageWidth * 0.80,
                pageHeight * 0.66,
                36
              )
              .fill(
                "#223E70"
              )
              .restore();

            // Inner circle

            document
              .save()
              .circle(
                pageWidth * 0.80 - 8,
                pageHeight * 0.66 - 8,
                20
              )
              .fill(
                BLUE
              )
              .restore();

            // Green accent circle

            document
              .save()
              .circle(
                pageWidth * 0.80 + 9,
                pageHeight * 0.66 + 7,
                12
              )
              .fill(
                "#6D9C7A"
              )
              .restore();

            // Small outline circle

            document
              .save()
              .circle(
                pageWidth * 0.91,
                pageHeight * 0.76,
                13
              )
              .lineWidth(2)
              .strokeColor(
                "#D6E0EB"
              )
              .stroke()
              .restore();

            // =================================================
            // RIGHT PANEL SMALL TEXT
            // =================================================

            document
              .fillColor(
                "#D8E1EF"
              )
              .font(
                "Helvetica"
              )
              .fontSize(7)
              .text(
                "TRAINING PORTAL",
                pageWidth * 0.66,
                pageHeight - 65,
                {
                  width:
                    pageWidth * 0.27,
                  align: "right",
                  characterSpacing: 1.2,
                }
              );

            // =================================================
            // FINISH PDF
            // =================================================

            document.end();
          }
        );

      console.log(
        "Refined certificate PDF generated successfully."
      );

      console.log(
        "PDF byte size:",
        pdfBuffer.length
      );
        // =================================================
        // FIREBASE STORAGE
        // =================================================
        const bucket =
          storage.bucket();
        const file =
          bucket.file(
            storagePath
          );
        // =================================================
        // DELETE OLD FILE FIRST
        // =================================================
        //
        // This guarantees that the previous certificate
        // cannot remain in Storage.
        //
        // ignoreNotFound prevents failure when the file
        // does not exist.
        //
        // =================================================
        try {
          await file.delete({
            ignoreNotFound: true,
          });
          console.log(
            "Old certificate PDF deleted."
          );
        } catch (deleteError) {
          console.warn(
            "Could not delete old certificate:",
            deleteError.message
          );
        }
        // =================================================
        // UPLOAD NEW PDF
        // =================================================
        await file.save(
          pdfBuffer,
          {
            resumable: false,
            metadata: {
              contentType:
                "application/pdf",
              cacheControl:
                "no-cache, no-store, must-revalidate",
              metadata: {
                userId,
                courseId,
                certificateNumber,
                averageQuizScore:
                  averageQuizScore.toString(),
                generatedAt:
                  new Date()
                    .toISOString(),
              },
            },
          }
        );
        console.log(
          "New certificate PDF uploaded."
        );
        // =================================================
        // GENERATE FRESH SIGNED URL
        // =================================================
        const [
          certificateUrl,
        ] =
          await file.getSignedUrl({
            action: "read",
            expires:
              "03-09-2491",
          });
        console.log(
          "Fresh certificate URL generated."
        );
        // =================================================
        // STORE CERTIFICATE DOCUMENT
        // =================================================
        await certificateRef.set(
          {
            userId,
            traineeName:
              userName,
            courseId,
            courseTitle,
            certificateNumber,
            certificateUrl,
            issuedAt,
            storagePath,
            totalLessons,
            completedLessons,
            averageQuizScore,
            submittedQuizCount,
            totalQuizScore,
            createdAt:
              existingCertificate.exists
                ? (
                    existingData.createdAt ||
                    FieldValue.serverTimestamp()
                  )
                : FieldValue.serverTimestamp(),
            updatedAt:
              FieldValue.serverTimestamp(),
            regeneratedAt:
              FieldValue.serverTimestamp(),
          },
          {
            merge: true,
          }
        );
        console.log(
          "Certificate Firestore record updated."
        );
        console.log(
          "GENERATE CERTIFICATE COMPLETE"
        );
        console.log(
          "=============================================="
        );
        // =================================================
        // RETURN
        // =================================================
        return {
          success: true,
          existing:
            existingCertificate.exists,
          regenerated: true,
          certificate: {
            id:
              certificateId,
            userId,
            traineeName:
              userName,
            courseId,
            courseTitle,
            certificateNumber,
            certificateUrl,
            issuedAt,
            storagePath,
            totalLessons,
            completedLessons,
            averageQuizScore,
            submittedQuizCount,
            totalQuizScore,
          },
        };
      } catch (error) {
        console.error(
          "GENERATE CERTIFICATE ERROR:",
          error
        );
        if (
          error instanceof HttpsError
        ) {
          throw error;
        }
        throw new HttpsError(
          "internal",
          error.message ||
            "Failed to generate certificate"
        );
      }
    }
  );
  // =====================================================
  // CERTIFICATE DATE FORMAT
  // =====================================================
  function formatCertificateDate(
    date
  ) {
    if (!date) {
      return "";
    }
    return new Intl.DateTimeFormat(
      "en-US",
      {
        month: "short",
        day: "numeric",
        year: "numeric",
      }
    ).format(date);
  }
  // =====================================================
  // DRAW CERTIFICATE STAT CARD
  // =====================================================
  function drawStatCard(
    document,
    x,
    y,
    width,
    height,
    label,
    value,
    borderColor,
    backgroundColor,
    valueColor,
    labelColor
  ) {
    // ---------------------------------------------------
    // Background
    // ---------------------------------------------------
    document
      .roundedRect(
        x,
        y,
        width,
        height,
        8
      )
      .fillAndStroke(
        backgroundColor,
        borderColor
      );
    // ---------------------------------------------------
    // Label
    // ---------------------------------------------------
    document
      .fillColor(
        labelColor
      )
      .font(
        "Helvetica-Bold"
      )
      .fontSize(8)
      .text(
        label,
        x,
        y + 12,
        {
          width,
          align: "center",
        }
      );
    // ---------------------------------------------------
    // Value
    // ---------------------------------------------------
    document
      .fillColor(
        valueColor
      )
      .font(
        "Helvetica-Bold"
      )
      .fontSize(17)
      .text(
        value,
        x,
        y + 32,
        {
          width,
          align: "center",
        }
      );
  }