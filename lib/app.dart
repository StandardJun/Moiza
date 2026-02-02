import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moiza/config/routes.dart';
import 'package:moiza/config/theme.dart';
import 'package:moiza/providers/auth_provider.dart';
import 'package:moiza/providers/study_provider.dart';
import 'package:moiza/providers/attendance_provider.dart';
import 'package:moiza/providers/penalty_provider.dart';

class MoizaApp extends StatelessWidget {
  const MoizaApp({super.key});

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
            title: '모이자',
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
