# Newgaon LMS - 프로젝트 분석 문서

## 📋 프로젝트 개요
**학원 관리 시스템 (Learning Management System)**
- React 18 + Vite 기반 웹 애플리케이션
- Material-UI (MUI) 컴포넌트 라이브러리 사용
- 학생, 강사, 출석, 메시지 관리 통합 시스템

---

## 🚀 개발 환경 & 실행
```bash
# 개발 서버 실행
npm run dev          # http://localhost:3000

# 빌드
npm run build

# 프로덕션 미리보기
npm preview
```

---

## 📁 프로젝트 구조

```
src/
├── components/          # 재사용 가능한 컴포넌트
│   ├── Layout.jsx      # 메인 레이아웃 (사이드바, 헤더)
│   ├── FileManager.jsx # 파일 관리 컴포넌트
│   └── dashboard/      # 대시보드 관련 컴포넌트
│       ├── DashboardHeader.jsx
│       ├── AttendanceView.jsx
│       ├── RecentHistory.jsx
│       └── GroupMessageModal.jsx
├── contexts/           # React Context 상태 관리
│   ├── AuthContext.jsx      # 인증 관리
│   ├── LMSContext.jsx       # 학원 데이터 관리
│   └── AttendanceContext.jsx # 출석 관리
├── pages/              # 페이지 컴포넌트
│   ├── HomePage.jsx           # 로그인 페이지
│   ├── RegisterPage.jsx       # 회원가입
│   ├── PasswordResetPage.jsx  # 비밀번호 재설정
│   ├── DashboardPage.jsx      # 메인 대시보드
│   ├── AttendanceDailyPage.jsx   # 일일 출석 관리
│   ├── AttendanceMonthlyPage.jsx # 월별 출석 현황
│   ├── StudentPage.jsx        # 학생 관리
│   ├── TeacherPage.jsx        # 강사 관리
│   ├── LecturePage.jsx        # 강의 관리
│   ├── MessagePage.jsx        # 메시지 관리
│   ├── FilePage.jsx           # 파일 관리
│   └── account/               # 계정 관련 페이지
│       ├── SettingsPage.jsx   # SMS 서비스 설정
│       ├── LicensePage.jsx    # 라이센스 관리
│       ├── PaymentPage.jsx    # 결제 관리
│       └── ProfilePage.jsx    # 프로필 관리
└── services/           # API 서비스
    ├── authService.js  # 인증 API
    └── apiService.js   # 기본 API 서비스
```

---

## 🎯 주요 기능 모듈

### 1. 인증 시스템 (AuthContext)
- 로그인/로그아웃 관리
- 사용자 세션 관리
- 관리자 권한 체크

### 2. 학원 관리 (LMSContext)
- **강의 관리**: 강의 등록, 수정, 삭제
- **학생 관리**: 학생 정보, 등록 강의 관리
- **강사 관리**: 강사 정보 및 담당 강의

### 3. 출석 관리 (AttendanceContext)
- **일일 출석**: 실시간 출석 체크
- **월별 현황**: 출석률 통계 및 분석
- **학생별 히스토리**: 개별 출석 기록

### 4. 메시지 시스템
- SMS 발송 기능
- 템플릿 관리
- 그룹 메시지 발송

### 5. 계정 관리
- **SMS 서비스 설정**: 3단계 설정 프로세스
  - STEP 1: 서비스 충전
  - STEP 2: 발신번호 인증
  - STEP 3: 발신번호 입력
- **라이센스 관리**
- **결제 관리**
- **프로필 설정**

---

## 🔐 라우팅 구조

### 공개 페이지 (로그인 불필요)
- `/` - 로그인 페이지
- `/register` - 회원가입
- `/password-reset` - 비밀번호 재설정

### 관리자 페이지 (로그인 필요)
- `/dashboard` - 메인 대시보드
- `/attendance/daily` - 일일 출석 관리
- `/attendance/monthly` - 월별 출석 현황
- `/students` - 학생 관리
- `/teachers` - 강사 관리
- `/lectures` - 강의 관리
- `/messages` - 메시지 관리
- `/files` - 파일 관리
- `/account/*` - 계정 설정 페이지들

---

## 🛠 기술 스택

### Frontend
- **React 18**: 메인 프레임워크
- **React Router v6**: 라우팅
- **Material-UI v5**: UI 컴포넌트
- **React Query v3**: 서버 상태 관리
- **Axios**: HTTP 클라이언트
- **React Hook Form**: 폼 관리
- **Recharts**: 차트 라이브러리
- **date-fns**: 날짜 처리

### Dev Tools
- **Vite**: 빌드 도구
- **TypeScript**: 타입 시스템
- **Emotion**: CSS-in-JS

---

## 📊 데이터 구조

### 강의 (Lecture)
```javascript
{
  id: 'math_a',
  name: '수학 A반',
  teacher: '박선생',
  subject: '수학',
  schedule: '월,수,금 19:00-20:30',
  fee: 150000,
  capacity: 20,
  currentStudents: 0,
  description: '중학교 1-2학년 대상 기초 수학'
}
```

### 학생 (Student)
```javascript
{
  id: 'unique_id',
  name: '학생명',
  phone: '010-1234-5678',
  lectures: ['lecture_id'],
  registrationDate: Date,
  status: 'active'
}
```

### 출석 (Attendance)
```javascript
{
  id: 'attendance_id',
  studentId: 'student_id',
  lectureId: 'lecture_id',
  date: Date,
  status: 'present|absent|late',
  timestamp: Date
}
```

---

## 🎨 UI/UX 특징

### Material-UI 테마
- 일관된 디자인 시스템
- 반응형 레이아웃
- 다크/라이트 모드 지원 가능

### 레이아웃 구조
- **사이드바**: 주요 네비게이션
- **헤더**: 사용자 정보, 알림
- **메인 컨텐츠**: 각 페이지별 기능

### 최근 개선사항
- **SettingsPage SMS 설정 UI 개선** (2024-01-21)
  - 카드 높이 증가 (200px → 240px)
  - 단계별 배지 크기 향상 (32px → 36px)
  - 타이포그래피 개선 (body1 → h6)
  - 버튼 크기 향상 (small → large)

---

## 🔧 개발 가이드

### 새 페이지 추가 시
1. `pages/` 폴더에 컴포넌트 생성
2. `App.jsx`에 라우트 추가
3. 필요시 Context에 상태 추가
4. Layout 컴포넌트로 감싸기

### 새 기능 추가 시
1. 해당 Context에 상태/함수 추가
2. 컴포넌트에서 Context hook 사용
3. Material-UI 컴포넌트 활용
4. 기존 디자인 패턴 유지

### 스타일링 가이드
- Material-UI sx prop 사용
- 일관된 spacing 시스템
- 기존 color palette 활용

---

## 📝 최근 커밋 히스토리
- `feat: Enhanced account management system with SMS service configuration`
- `feat: Enhanced attendance management with real-time status updates`
- `feat: Enhanced message template system with admin editing`
- `feat: Enhanced message management with comprehensive template system`
- `feat: Enhanced student and lecture management with comprehensive features`

---

## 🚨 주의사항

### 보안
- 인증이 필요한 페이지는 AuthContext로 보호
- API 호출 시 적절한 에러 처리 필요

### 성능
- React Query를 활용한 효율적인 데이터 fetching
- 컴포넌트 최적화 (memo, callback 활용)

### 코딩 컨벤션
- 함수형 컴포넌트 사용
- React Hooks 활용
- Material-UI 디자인 시스템 준수

---

*이 문서는 Claude Code에 의해 자동 생성되었습니다. 프로젝트 변경 시 업데이트가 필요할 수 있습니다.*