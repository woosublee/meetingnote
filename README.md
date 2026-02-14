# AI 미팅 노트

실시간 음성 전사와 Apple Intelligence 기반 AI 요약 기능을 제공하는 macOS/iOS 미팅 녹음 앱입니다.

## 주요 기능

- 🎙️ **실시간 녹음 및 전사** - 회의 중 자동으로 음성을 텍스트로 변환
- 🔊 **시스템 오디오 캡처** (macOS) - 마이크 + 시스템 오디오 통합 녹음, 화면 녹화 권한 없을 시 마이크 전용으로 자동 전환
- 🤖 **AI 처리** - Apple Intelligence(온디바이스 LLM)를 활용한 텍스트 후처리
  - **요약**: 핵심 내용 요약
  - **회의록**: 공식 회의록 형식으로 변환
  - **액션 아이템**: 할 일 및 담당자 자동 추출
  - **커스텀**: 원하는 프롬프트로 자유롭게 처리 (결과가 커스텀1, 커스텀2 탭으로 누적)
- 📂 **노트 관리** - 날짜별 그룹핑, 전체 노트 목록 관리
- 🔍 **검색** - 제목/내용 전체 텍스트 검색

## 시스템 요구사항

- macOS 26.0 이상 (Apple Intelligence 사용 시)
- Xcode 16.0 이상
- Apple Intelligence 지원 기기 + Apple Intelligence 활성화 필요

## 권한

앱 실행 시 다음 권한을 요청합니다:

- **마이크** - 녹음을 위해 필수
- **음성 인식** - 실시간 전사를 위해 필수
- **화면 녹화** (macOS, 선택사항) - 시스템 오디오 캡처용, 거부 시 마이크 전용으로 동작

## 기술 스택

- **UI**: SwiftUI
- **데이터**: SwiftData
- **녹음**: AVFoundation + AVAudioEngine
- **음성 인식**: Speech Framework (SFSpeechRecognizer)
- **시스템 오디오**: ScreenCaptureKit (macOS)
- **AI**: Apple FoundationModels (온디바이스 LLM)
- **언어**: Swift

## 개발 계획

- [ ] iCloud 동기화 (CloudKit + iCloud Drive)
- [ ] 화자 인식
- [ ] 캘린더 연동

---

**개발자**: WOOSUB LEE
**라이선스**: MIT
