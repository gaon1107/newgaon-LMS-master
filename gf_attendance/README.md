# GF Attendance - 가온 출결관리 시스템

기존 Android 출결 앱을 Flutter로 완전히 재개발한 최신 버전의 출결 관리 시스템입니다.

## 📱 주요 기능

### 🔐 인증 방식
- **얼굴인식**: Google ML Kit을 활용한 실시간 얼굴 인식
- **키패드 입력**: 학번을 직접 입력하여 출결 처리
- **수동 입력**: 관리자가 직접 출결 상태 입력

### 📊 출결 관리
- 실시간 출결 체크 (등원, 수업출석, 하원, 지각, 조퇴)
- 출결 현황 조회 및 통계
- 학생별, 날짜별, 강의별 출결 관리
- 출결 데이터 엑셀 내보내기

### 👥 학생 관리
- 학생 정보 등록 및 수정
- 학생 검색 (이름, 학번)
- 얼굴 템플릿 등록 및 관리
- 학생별 출결 이력 조회

## 🏗️ 기술 스택

### Frontend (Flutter)
- **Flutter**: 3.0+
- **Dart**: 3.0+
- **상태관리**: Provider
- **HTTP 통신**: Dio, HTTP
- **얼굴인식**: Google ML Kit Face Detection
- **카메라**: Camera Plugin
- **로컬저장**: SharedPreferences
- **반응형 UI**: Flutter ScreenUtil

### Backend (Node.js)
- **Node.js**: Express.js
- **데이터베이스**: MySQL
- **인증**: JWT
- **파일업로드**: Multer
- **보안**: Helmet, CORS

## 📁 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── student_model.dart
│   └── attendance_model.dart
├── services/                 # 비즈니스 로직
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── attendance_service.dart
├── screens/                  # 화면 위젯
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   └── main_screen.dart
├── widgets/                  # 재사용 컴포넌트
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── attendance_summary_card.dart
│   ├── student_search_bar.dart
│   └── attendance_action_buttons.dart
└── utils/                    # 유틸리티
    ├── app_constants.dart
    └── app_theme.dart
```

## 🚀 시작하기

### 1. 개발 환경 설정

```bash
# Flutter 설치 확인
flutter doctor

# 의존성 설치
flutter pub get
```

### 2. 백엔드 서버 실행

```bash
# LMS 백엔드 디렉토리로 이동
cd ../backend

# 의존성 설치
npm install

# 서버 실행
npm start
```

### 3. 앱 실행

```bash
# Android 에뮬레이터 또는 실제 기기에서 실행
flutter run

# iOS 시뮬레이터에서 실행
flutter run -d ios
```

## 🔧 설정

### API 엔드포인트 설정

`lib/utils/app_constants.dart` 파일에서 백엔드 서버 주소를 설정하세요:

```dart
static const String baseUrl = 'http://localhost:5000/api';
```

### 권한 설정

앱에서 사용하는 주요 권한:
- **카메라**: 얼굴인식 기능
- **인터넷**: API 통신
- **저장소**: 파일 업로드/다운로드

## 📋 기존 앱과의 호환성

이 Flutter 앱은 기존 Android 앱의 다음 요소들을 동일하게 구현했습니다:

### 🎨 UI/UX
- 동일한 색상 팔레트 (가온 그린 테마)
- 유사한 레이아웃 구조
- 동일한 출결 상태 코드 체계

### 📡 API 호환성
- 기존 백엔드 API와 완전 호환
- 동일한 데이터 모델 구조
- 기존 디바이스 ID 체계 유지

### 🔑 인증 방식
- 얼굴인식 + 키패드 이중 인증
- 동일한 출결 상태 코드 (0: 등원, 1: 수업출석, 2: 하원, 3: 지각, 4: 조퇴)
- 기존 데이터베이스 스키마와 호환

## 🛠️ 개발 계획

### Phase 1: 기본 기능 (완료)
- [x] 프로젝트 설정 및 구조 생성
- [x] 기본 UI 컴포넌트 구현
- [x] API 서비스 레이어 구현
- [x] 인증 시스템 구현

### Phase 2: 핵심 기능 (진행 중)
- [ ] 얼굴인식 기능 구현
- [ ] 키패드 입력 기능 구현
- [ ] 출결 체크 기능 구현
- [ ] 학생 관리 기능 구현

### Phase 3: 고급 기능 (예정)
- [ ] 출결 통계 및 리포트
- [ ] 오프라인 모드 지원
- [ ] 푸시 알림
- [ ] 다국어 지원

## 🤝 기여하기

1. 이 저장소를 포크하세요
2. 새로운 기능 브랜치를 생성하세요 (`git checkout -b feature/새기능`)
3. 변경사항을 커밋하세요 (`git commit -am '새기능 추가'`)
4. 브랜치에 푸시하세요 (`git push origin feature/새기능`)
5. Pull Request를 생성하세요

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 생성하거나 개발팀에 연락주세요.

---

**가온 출결관리 시스템 v2.0 - Flutter Edition** 🚀