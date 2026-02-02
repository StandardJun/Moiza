import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:moiza/providers/auth_provider.dart';
import 'package:moiza/screens/auth/login_screen.dart';
import 'package:moiza/screens/auth/signup_screen.dart';
import 'package:moiza/screens/home/home_screen.dart';
import 'package:moiza/screens/study/create_study_screen.dart';
import 'package:moiza/screens/study/join_study_screen.dart';
import 'package:moiza/screens/study/study_detail_screen.dart';
import 'package:moiza/screens/attendance/attendance_screen.dart';
import 'package:moiza/screens/penalty/penalty_report_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String createStudy = '/create-study';
  static const String joinStudy = '/join-study';
  static const String studyDetail = '/study/:id';
  static const String attendance = '/study/:id/attendance';
  static const String penaltyReport = '/study/:id/penalty-report';
}

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.createStudy,
        builder: (context, state) => const CreateStudyScreen(),
      ),
      GoRoute(
        path: AppRoutes.joinStudy,
        builder: (context, state) => const JoinStudyScreen(),
      ),
      GoRoute(
        path: '/study/:id',
        builder: (context, state) {
          final studyId = state.pathParameters['id']!;
          return StudyDetailScreen(studyGroupId: studyId);
        },
      ),
      GoRoute(
        path: '/study/:id/attendance',
        builder: (context, state) {
          final studyId = state.pathParameters['id']!;
          return AttendanceScreen(studyGroupId: studyId);
        },
      ),
      GoRoute(
        path: '/study/:id/penalty-report',
        builder: (context, state) {
          final studyId = state.pathParameters['id']!;
          return PenaltyReportScreen(studyGroupId: studyId);
        },
      ),
    ],
  );
}
