# BBC Operations Platform

An internal operations platform built with Flutter and Firebase for managing onboarding workflows, operational activities, training, API tooling, and platform administration.

## Overview

BBC Operations Platform brings multiple internal workflows into a unified platform while maintaining separate workspaces and access boundaries for different user roles.

The platform currently provides five application surfaces:

* **BBC Operations Platform** — master workspace with combined dashboards and platform access
* **BBC Support Platform** — dedicated workspace for support operations
* **BBC Onboarding Platform** — client onboarding and activation workflows
* **BEVATEL Training Portal** — courses, lessons, quizzes, progress, and certificates
* **BBC API Tool** — internal API testing and documentation

The application uses role-aware routing and platform-specific access controls to determine which areas each authenticated user can access.

## Platform Modules

### Operations & Onboarding

The operations module provides a structured workspace for managing onboarding activities and client records.

Capabilities include:

* Operations dashboard
* Client management
* Client workspaces
* Client overview
* Activation management
* Channel management
* Verification workflows
* Chatbot management
* Group management
* Client activity
* User-level tasks
* Operational reports

The client workspace is organized into dedicated sections so that different parts of the onboarding lifecycle can be managed independently.

### Support

The Support Platform provides a dedicated platform surface for support-oriented workflows while sharing the same underlying authentication and platform infrastructure.

Access is restricted according to the configured platform roles.

### Training Portal

The BEVATEL Training Portal provides an internal learning environment with:

* Training dashboard
* Course catalog
* Course details
* Lessons
* Quizzes
* Quiz review
* Training progress
* Certificates

Training content and progress are integrated with the platform's Firebase-backed data layer.

### BBC API Tool

The BBC API Tool provides an internal workspace for API testing and documentation.

It is available as both part of the master platform and as a standalone platform surface.

### Administration

The Super Admin Console provides administrative functionality including:

* User management
* Training management
* Analytics
* Meta / WhatsApp administration
* Platform logs

Administrative routes are protected by role-based access checks.

## Authentication & Access Control

The platform uses Firebase Authentication and role-aware routing.

Platform access is separated according to configured roles and platform types, including:

* `superadmin`
* `onboarding_agent`
* `support_agent`
* `trainee`
* `agent`

The master platform can expose the combined application experience, while standalone platform builds restrict navigation to the relevant workspace.

Protected routes are evaluated before navigation, and restricted areas redirect unauthorized users to an appropriate platform location.

## Architecture

The application is structured as a Flutter application with Firebase services providing the backend infrastructure.

### Frontend

* Flutter
* Dart
* Material UI
* GoRouter
* Modular feature-based structure

### Backend

* Firebase Authentication
* Cloud Firestore
* Firebase Cloud Functions
* Firebase Storage
* Firebase Admin SDK

### Integrations & Services

The backend contains integrations and service functionality for platform operations, including:

* Bevatel API communication
* Meta / WhatsApp related operations
* Zoho CRM integration
* Google APIs
* PDF generation
* Server-side proxy functions

Sensitive integration credentials and server-side operations are handled through the backend rather than being exposed directly to the Flutter client.

## Application Structure

The main application code is organized around platform-level services and functional modules.

```text
lib/
├── admin_console/
├── modules/
│   ├── bbc_api_tool/
│   ├── login/
│   ├── operations/
│   └── training/
├── platform/
├── router/
├── services/
└── ...
```

The backend is maintained separately under:

```text
functions/
```

with Firebase Cloud Functions providing server-side operations and integrations.

## Platform Configuration

The application supports multiple platform configurations from the same codebase.

```text
Platform
├── Master
├── Support
├── Onboarding
├── Training
└── API Tool
```

Each platform configuration defines its:

* Platform type
* Display title
* Description
* Allowed roles
* Landing route
* Primary visual configuration

This allows the same application codebase to support multiple operational entry points while maintaining platform-specific navigation and access rules.

## Routing

Navigation is managed through GoRouter.

The application includes protected route groups for:

```text
/login

/home

/bbc-api

/training
/training/courses
/training/progress
/training/certificates
/training/course/:courseId
/training/course/:courseId/lesson/:lessonId
/training/course/:courseId/lesson/:lessonId/quiz

/operations
/operations/onboarding
/operations/onboarding/clients
/operations/onboarding/tasks
/operations/onboarding/reports
/operations/onboarding/client/:clientId
/operations/onboarding/client/:clientId/overview
/operations/onboarding/client/:clientId/activation
/operations/onboarding/client/:clientId/channels
/operations/onboarding/client/:clientId/verification
/operations/onboarding/client/:clientId/chatbot
/operations/onboarding/client/:clientId/group
/operations/onboarding/client/:clientId/activity

/admin-console
/admin-console/users
/admin-console/training-management
/admin-console/analytics
/admin-console/meta-whatsapp
/admin-console/logs
```

Route guards verify authentication and platform/role access before allowing navigation.

## Technology Stack

| Layer               | Technology                                      |
| ------------------- | ----------------------------------------------- |
| Application         | Flutter                                         |
| Language            | Dart                                            |
| Navigation          | GoRouter                                        |
| Authentication      | Firebase Authentication                         |
| Database            | Cloud Firestore                                 |
| Backend             | Firebase Cloud Functions                        |
| Server SDK          | Firebase Admin SDK                              |
| Storage             | Firebase Storage                                |
| External APIs       | Bevatel, Meta / WhatsApp, Zoho CRM, Google APIs |
| Document Generation | PDF generation through backend services         |

## Project Structure

```text
Operations_Platform/
│
├── lib/
│   ├── admin_console/
│   ├── modules/
│   │   ├── bbc_api_tool/
│   │   ├── login/
│   │   ├── operations/
│   │   └── training/
│   ├── platform/
│   ├── router/
│   └── services/
│
├── functions/
│   └── Firebase Cloud Functions
│
├── assets/
│
├── android/
├── ios/
├── web/
│
├── firebase.json
├── pubspec.yaml
└── ...
```

## Development

### Prerequisites

Install the required development tooling for:

* Flutter
* Dart
* Node.js
* Firebase CLI

The exact runtime versions should follow the versions defined by the project configuration and Firebase Functions package configuration.

### Flutter

Install dependencies:

```bash
flutter pub get
```

Run the application locally:

```bash
flutter run
```

For web development:

```bash
flutter run -d chrome
```

### Firebase Functions

The backend is located in:

```text
functions/
```

Install backend dependencies:

```bash
cd functions
npm install
```

Firebase deployment should be performed using the project's existing Firebase configuration and deployment scripts.

## Deployment

The repository contains deployment configuration for Firebase and separate platform builds.

The deployment setup supports platform-specific web builds for the different application surfaces rather than treating the entire system as a single undifferentiated frontend.

Before deploying changes, verify:

1. Flutter dependencies
2. Firebase configuration
3. Cloud Functions dependencies
4. Target platform/build configuration
5. Authentication and authorization behavior
6. Environment-specific configuration

## Security

The platform handles authenticated internal workflows and integrates with external services.

Security-sensitive operations should remain on the backend, including:

* API credentials
* External service authentication
* Privileged administrative operations
* Server-side integrations
* Protected API proxy functionality

Client-side role checks are used for navigation and user experience, while privileged backend operations should be protected independently by server-side authorization.

Do not commit credentials, private keys, access tokens, or other secrets to the repository.

## Current Status

The platform is an actively developed internal system with multiple operational modules and platform-specific entry points.

The repository currently combines functionality that originally existed around the BBC API Tool with newer operations, onboarding, training, and administrative capabilities.

As the platform continues to evolve, documentation and architecture should be kept aligned with the implemented application structure.

## Repository

**Operations Platform**

GitHub:
https://github.com/EslamMourad648abd/Operations_Platform

## License

This project is intended for internal use.
