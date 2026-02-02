# 모이자 (Moiza)

스터디 그룹 출석 체크와 벌금 자동 계산 앱

## Features

- 스터디 그룹 생성 및 참여 (초대 코드)
- 출석 체크 시스템 (인증 단어 방식)
- 벌금 규칙 설정 및 자동 계산
- 방장/관리자 권한 관리
- 크로스 플랫폼 (iOS, Android, Web)

## Tech Stack

- Flutter 3.x
- Firebase (Auth, Firestore)
- Provider (State Management)
- go_router (Navigation)

## Getting Started

```bash
# 의존성 설치
flutter pub get

# 웹으로 실행
flutter run -d chrome

# iOS/Android 실행
flutter run
```

## Project Structure

```
lib/
├── config/         # 설정 (상수, 라우터, 테마)
├── models/         # 데이터 모델
├── providers/      # 상태 관리
├── screens/        # UI 화면
├── services/       # Firebase 서비스
└── widgets/        # 공통 위젯
```
# Moiza
