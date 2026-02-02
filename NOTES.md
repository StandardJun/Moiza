# 모이자 (Moiza) - 프로젝트 노트

## 프로젝트 개요
모임 출석 체크와 벌금 자동 계산 앱
- 수익 모델: 광고 기반 (모바일: AdMob, 웹: AdSense)

## 현재 상태: 출석 시스템 고도화 완료

---

## 기술 스택
- **Frontend**: Flutter (iOS, Android, Web)
- **Backend**: Firebase (Auth, Firestore)
- **State Management**: Provider
- **Routing**: go_router 14.x
- **Ads**: AdMob (모바일), AdSense (웹)
- **Hosting**: Cloudflare Pages
- **Repository**: https://github.com/StandardJun/Moiza.git

---

## 완료된 작업

### 1. 프로젝트 이름 변경 ✅
- `study_penalty` → `moiza`
- 클래스명: `StudyPenaltyApp` → `MoizaApp`
- 모든 import 문 업데이트

### 2. 아이디/비밀번호 기반 인증 ✅
- 이메일 → 아이디(username) 변경
- 내부적으로 `username@moiza.app` 형식으로 Firebase Auth 사용
- 아이디 규칙: 4-20자, 영문/숫자/밑줄(_)만 허용
- 중복 확인 기능

### 3. GitHub 연동 ✅
- 원격 저장소: https://github.com/StandardJun/Moiza.git
- 자동 push 가능

### 4. Cloudflare Pages 배포 설정 ✅
- **Build command**:
  ```
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.0-stable.tar.xz | tar xJ && export PATH="$PATH:$PWD/flutter/bin" && flutter build web --release
  ```
- **Build output directory**: `build/web`
- **Framework preset**: None
- SDK 버전: `^3.5.0` (Cloudflare 호환)
- `firebase_options.dart` git에 포함됨

### 5. 광고 시스템 ✅ (2024-02-03 개선)
- **모바일**: AdMob (google_mobile_ads)
  - AdService를 ChangeNotifier로 변경하여 상태 변화 감지
  - BannerAdWidget이 광고 로드 상태 실시간 반영
  - 로딩 중 플레이스홀더 표시
- **웹**: AdSense placeholder 추가
  - `web/index.html`에서 `ca-pub-XXXXXXXXXXXXXXXX` 교체 필요

### 6. 출석 시스템 ✅ (2024-02-03 고도화)
- 인증 단어 방식 (랜덤 한글 단어)
- **인증 단어 권한**: 출석을 시작한 사람만 볼 수 있음 (방장/관리자도 시작자 아니면 못 봄)
- **출석 마감/취소 분리**:
  - 출석 마감: 출석 기록 저장 + 미출석자 결석 처리 + 벌금 자동 생성
  - 출석 취소: 세션만 삭제 (기록 없음)
- **지각 유예 시간**: 출석 마감 후 설정된 시간 내 지각 체크인 가능
  - 모임 생성 시 설정 (기본 10분)
  - 언제든 벌금 규칙에서 수정 가능
  - 지각 체크인 시 결석 → 지각으로 변경 + 벌금도 자동 조정
- 출석 시간 연장 기능

### 7. 권한 시스템 ✅
- 방장(owner) > 관리자(admin) > 일반 멤버
- 방장 위임 기능
- 관리자 추가/제거

### 8. 벌금 규칙 ✅
- 지각, 결석, 과제 미제출 벌금 설정
- **지각 유예 시간 설정** (신규)
- 수정 로그 기록 및 조회

---

## 프로젝트 구조
```
lib/
├── main.dart
├── app.dart (MoizaApp)
├── firebase_options.dart
├── config/
│   ├── constants.dart      # AdMob ID, 상수
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user_model.dart     # username 필드
│   ├── study_group_model.dart  # lastFinishedSession 추가
│   ├── attendance_model.dart   # sessionId 추가
│   └── penalty_model.dart
├── services/
│   ├── auth_service.dart   # 아이디 기반 인증
│   ├── study_service.dart  # finishAttendanceSession, cancelAttendanceSession, lateCheckIn
│   ├── attendance_service.dart
│   ├── penalty_service.dart
│   └── ad_service.dart     # ChangeNotifier로 변경
├── providers/
│   └── study_provider.dart # finishAttendanceSession, cancelAttendanceSession, lateCheckIn
├── screens/
│   ├── attendance/
│   │   └── attendance_screen.dart  # 마감/취소 분리, 지각 체크인 UI
│   └── study/
│       ├── create_study_screen.dart # 지각 유예 시간 설정
│       └── study_detail_screen.dart # 지각 유예 시간 수정
└── widgets/common/
    └── banner_ad_widget.dart  # 광고 상태 실시간 반영
```

---

## 데이터 모델 변경사항

### AttendanceSession
- `lateGracePeriodMinutes`: 지각 유예 시간 (분)
- `userStatuses`: 사용자별 출석 상태 (present/late)
- `isInLateGracePeriod`: 지각 유예 기간 내인지 확인
- `lateGracePeriodEndsAt`: 지각 유예 기간 종료 시간

### AttendanceModel
- `sessionId`: 출석 세션 ID (추가)

### StudyGroupModel
- `lastFinishedSession`: 마감된 마지막 세션 (지각 체크인용)

### PenaltyRule
- `lateGracePeriodMinutes`: 지각 유예 시간 (분, 기본 10분)

---

## Firebase 설정
- **Project ID**: study-penalty
- **Auth**: Email/Password (내부적으로 username@moiza.app 사용)
- **Firestore**: asia-northeast3
- **Web App ID**: 1:928791623594:web:e9efd22e7fc372a5c0ddd3

---

## 남은 작업

### 배포 완료 후
- [ ] Cloudflare 배포 URL 확인
- [ ] AdSense Publisher ID 설정 (`web/index.html`)
- [ ] AdMob 실제 광고 단위 ID 설정 (`lib/config/constants.dart`)
- [ ] Firestore 보안 규칙 강화
- [ ] 앱 아이콘/스플래시 커스터마이징

---

## 실행 방법
```bash
cd "/Users/jun/Jun workstation/study_penalty"
flutter pub get
flutter run -d chrome  # 웹
flutter run            # 모바일
```

---

## 비즈니스 모델
- 무료 앱 (광고 기반)
- 배너 광고: 하단 상시 노출
- 전면 광고: 출석 체크 완료 후
