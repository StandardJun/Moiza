import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_penalty/config/routes.dart';
import 'package:study_penalty/config/theme.dart';
import 'package:study_penalty/providers/auth_provider.dart';
import 'package:study_penalty/providers/study_provider.dart';
import 'package:study_penalty/providers/attendance_provider.dart';
import 'package:study_penalty/providers/penalty_provider.dart';

class StudyPenaltyApp extends StatelessWidget {
  const StudyPenaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudyProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => PenaltyProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final router = createRouter(authProvider);

          return MaterialApp.router(
            title: '스터디 벌금',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            locale: const Locale('ko', 'KR'),
          );
        },
      ),
    );
  }
}
