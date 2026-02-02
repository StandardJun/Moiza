import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:study_penalty/app.dart';
import 'package:study_penalty/services/ad_service.dart';
import 'package:study_penalty/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 한국어 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  // 광고 서비스 초기화
  await AdService().initialize();

  runApp(const StudyPenaltyApp());
}
