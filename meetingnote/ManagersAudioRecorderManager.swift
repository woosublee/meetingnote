//
//  AudioRecorderManager.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import Foundation
import AVFoundation
import Speech

#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
import ScreenCaptureKit
#endif

@MainActor
@Observable
final class AudioRecorderManager {
    // 녹음 상태
    var isRecording = false
    var isPaused = false
    var recordingDuration: TimeInterval = 0

    // 전사 텍스트
    var transcribedText = ""

    // 오디오 레벨 (파형 시각화용)
    var audioLevel: Float = 0.0
    var audioLevels: [Float] = Array(repeating: 0, count: 40)
    
    // 권한 상태
    var audioPermissionGranted = false
    var speechPermissionGranted = false
    
    #if os(macOS)
    var screenCapturePermissionGranted = false
    #endif
    
    // 오디오 파일 작성
    private var audioFile: AVAudioFile?
    private var recordingTimer: Timer?
    
    // 디버깅: 오디오 입력 모니터링
    private var audioBufferCount = 0
    private var lastBufferTime = Date()
    
    // 음성 인식
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 현재 녹음 파일 URL
    private(set) var currentRecordingURL: URL?
    
    #if os(macOS)
    // 시스템 오디오 캡처 (macOS 전용)
    private var systemAudioStream: SCStream?
    private var systemAudioOutput: SystemAudioOutputHandler?
    private var systemAudioFile: AVAudioFile?
    private var systemAudioURL: URL?
    private var microphoneURL: URL?
    #endif
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
        
        // 음성 인식기가 사용 가능한지 확인
        if speechRecognizer == nil {
            print("⚠️ 한국어 음성 인식기를 사용할 수 없습니다.")
        }
        
        #if os(macOS)
        // macOS에서 오디오 입력 장치 정보 로깅
        logAvailableAudioDevices()
        #endif
    }
    
    #if os(macOS)
    private func logAvailableAudioDevices() {
        print("🔍 시스템 오디오 장치 확인 중...")
        
        // AVCaptureDevice로 오디오 장치 확인
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
        
        if devices.isEmpty {
            print("⚠️ AVCaptureDevice: 사용 가능한 오디오 입력 장치를 찾을 수 없습니다")
        } else {
            print("📱 AVCaptureDevice로 발견된 장치:")
            for device in devices {
                print("   - \(device.localizedName)")
            }
        }
    }
    #endif
    
    // MARK: - 권한 요청
    
    func requestPermissions() async {
        print("🔐 권한 요청 시작...")
        
        #if os(iOS)
        // 마이크 권한 (iOS)
        audioPermissionGranted = await AVAudioApplication.requestRecordPermission()
        #else
        // macOS에서 마이크 권한 확인
        audioPermissionGranted = await withCheckedContinuation { continuation in
            // AVCaptureDevice를 사용하여 실제 권한 확인
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .authorized:
                print("✅ macOS 마이크 권한: 이미 승인됨")
                continuation.resume(returning: true)
            case .notDetermined:
                print("⏳ macOS 마이크 권한: 요청 중...")
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    print("🎤 macOS 마이크 권한 응답: \(granted)")
                    continuation.resume(returning: granted)
                }
            case .denied, .restricted:
                print("❌ macOS 마이크 권한: 거부됨 또는 제한됨")
                continuation.resume(returning: false)
            @unknown default:
                print("⚠️ macOS 마이크 권한: 알 수 없는 상태")
                continuation.resume(returning: false)
            }
        }
        
        if !audioPermissionGranted {
            print("⚠️ macOS: 시스템 환경설정 > 보안 및 개인 정보 보호 > 마이크에서 앱 권한을 확인하세요.")
        }
        #endif
        
        print("🎤 마이크 권한: \(audioPermissionGranted)")
        
        // 음성 인식 권한
        speechPermissionGranted = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("🗣️ 음성 인식 권한 상태: \(status.rawValue)")
                continuation.resume(returning: status == .authorized)
            }
        }
        
        print("✅ 음성 인식 권한: \(speechPermissionGranted)")
        
        #if os(macOS)
        // 시스템 오디오 캡처용 화면 녹화 권한 (거부해도 마이크 전용으로 fallback)
        screenCapturePermissionGranted = await requestScreenCapturePermission()
        print("🖥️ 화면 녹화 권한: \(screenCapturePermissionGranted)")
        #endif

        // 음성 인식기 사용 가능 여부 확인
        if let recognizer = speechRecognizer {
            print("🌐 음성 인식기 사용 가능: \(recognizer.isAvailable)")
        }
    }
    
    #if os(macOS)
    private func requestScreenCapturePermission() async -> Bool {
        do {
            print("🔐 화면 녹화 권한 요청 중...")
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            if !content.displays.isEmpty {
                print("✅ 화면 녹화 권한: 승인됨 (디스플레이 \(content.displays.count)개 발견)")
                return true
            } else {
                print("⚠️ 화면 녹화 권한: 승인됨, 하지만 디스플레이를 찾을 수 없음")
                return false
            }
        } catch {
            let nsError = error as NSError
            print("❌ 화면 녹화 권한 오류:")
            print("   - 코드: \(nsError.code)")
            print("   - 설명: \(nsError.localizedDescription)")
            print("   - 도메인: \(nsError.domain)")
            
            // 권한 거부 vs 기타 오류 구분
            if nsError.domain == "com.apple.screencapturekit" && nsError.code == -3801 {
                print("   → 화면 녹화 권한이 거부되었습니다.")
                print("   → 시스템 환경설정 > 보안 및 개인 정보 보호 > 화면 녹화에서 앱을 허용해주세요.")
            }
            
            return false
        }
    }
    #endif

    // MARK: - 녹음 시작
    
    func startRecording() async throws {
        print("🎙️ 녹음 시작 시도...")
        
        guard audioPermissionGranted && speechPermissionGranted else {
            print("❌ 권한 없음 - 마이크: \(audioPermissionGranted), 음성인식: \(speechPermissionGranted)")
            throw RecordingError.permissionDenied
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ 음성 인식기를 사용할 수 없습니다.")
            throw RecordingError.recognitionUnavailable
        }
        
        #if os(iOS)
        // iOS에서만 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement)
        try audioSession.setActive(true)
        print("✅ iOS 오디오 세션 활성화")
        #else
        // macOS에서 기본 입력 장치 설정
        print("🎛️ macOS 오디오 입력 설정 중...")
        try setupMacOSAudioInput()
        #endif
        
        // 녹음 파일 URL 생성
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        currentRecordingURL = audioFilename
        
        print("📁 녹음 파일 경로: \(audioFilename)")
        
        // 음성 인식과 녹음을 AVAudioEngine으로 통합
        try startTranscription(recordingTo: audioFilename)
        
        isRecording = true
        recordingDuration = 0
        
        // 타이머 시작
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 1
            }
        }
        
        print("✅ 녹음 완전히 시작됨")
    }
    
    #if os(macOS)
    // macOS 전용: 오디오 입력 장치 설정
    private func setupMacOSAudioInput() throws {
        let inputNode = audioEngine.inputNode
        
        // 사용 가능한 입력 장치 확인
        #if os(macOS)
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
        
        print("📱 사용 가능한 오디오 입력 장치:")
        for device in devices {
            print("   - \(device.localizedName) (uniqueID: \(device.uniqueID))")
        }
        
        if devices.isEmpty {
            print("❌ 사용 가능한 오디오 입력 장치가 없습니다!")
        }
        
        // 기본 입력 장치 확인
        if let defaultDevice = AVCaptureDevice.default(for: .audio) {
            print("🎤 기본 입력 장치: \(defaultDevice.localizedName)")
        } else {
            print("⚠️ 기본 입력 장치를 찾을 수 없습니다")
        }
        #endif
        
        // 입력 노드의 볼륨 설정
        inputNode.volume = 1.0
        
        // 현재 입력 포맷 확인
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        print("🎙️ macOS 입력 노드 설정 완료")
        print("   - 입력 채널 수: \(inputFormat.channelCount)")
        print("   - 샘플레이트: \(inputFormat.sampleRate) Hz")
        
        // 샘플레이트가 0이면 입력 장치가 제대로 설정되지 않은 것
        if inputFormat.sampleRate == 0 {
            print("❌ 입력 장치의 샘플레이트가 0입니다. 마이크가 제대로 연결되지 않았습니다.")
            throw RecordingError.recognitionUnavailable
        }
    }
    #endif
    
    // MARK: - 녹음 중지
    
    func stopRecording() {
        print("🛑 녹음 중지...")
        
        // 순서가 중요함: 먼저 탭 제거, 그 다음 엔진 중지
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        
        #if os(macOS)
        // 시스템 오디오 스트림 중지
        if let stream = systemAudioStream {
            Task {
                do {
                    try await stream.stopCapture()
                    print("✅ 시스템 오디오 캡처 중지됨")
                } catch {
                    print("❌ 시스템 오디오 중지 오류: \(error)")
                }
            }
        }
        systemAudioStream = nil
        systemAudioOutput = nil
        #endif
        
        // 음성 인식 정리
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 오디오 파일 닫기
        audioFile = nil
        
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        #if os(iOS)
        // iOS에서만 오디오 세션 비활성화
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        
        print("✅ 녹음 중지 완료")
    }
    
    // MARK: - 음성 인식 시작 (마이크 + 시스템 오디오 믹싱)
    
    private func startTranscription(recordingTo fileURL: URL) throws {
        print("🗣️ 음성 인식 및 녹음 시작 (마이크 + 시스템 오디오)...")
        
        // 기존 작업 취소
        recognitionTask?.cancel()
        recognitionTask = nil
        transcribedText = ""
        
        // 인식 요청 생성
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("❌ 음성 인식 요청 생성 실패")
            throw RecordingError.recognitionUnavailable
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        if #available(macOS 13.0, iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        
        print("✅ 음성 인식 요청 생성 성공")
        
        #if os(macOS)
        // macOS: 화면 녹화 권한이 있으면 마이크 + 시스템 오디오 통합, 없으면 마이크만
        if screenCapturePermissionGranted {
            try startMixedAudioCapture(recognitionRequest: recognitionRequest, fileURL: fileURL)
        } else {
            print("⚠️ 화면 녹화 권한 없음 - 마이크만 사용")
            try startMicrophoneOnly(recognitionRequest: recognitionRequest, fileURL: fileURL)
        }
        #else
        // iOS: 마이크만 사용
        try startMicrophoneOnly(recognitionRequest: recognitionRequest, fileURL: fileURL)
        #endif
    }
    
    // MARK: - 마이크만 사용 (기존 방식)
    
    private func startMicrophoneOnly(recognitionRequest: SFSpeechAudioBufferRecognitionRequest, fileURL: URL) throws {
        print("🎤 마이크 전용 모드 시작...")
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        
        print("🎧 오디오 입력 형식: \(recordingFormat)")
        
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            print("❌ 유효하지 않은 오디오 입력 형식")
            throw RecordingError.recognitionUnavailable
        }
        
        // 오디오 파일 생성
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )!
        
        audioFile = try AVAudioFile(forWriting: fileURL, settings: outputFormat.settings)
        
        // 오디오 탭 설치
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, when in
            guard let self = self, buffer.frameLength > 0 else { return }

            // 음성 인식에 전달
            recognitionRequest.append(buffer)

            // 파일에 녹음
            do {
                if let monoBuffer = self.convertToMono(buffer: buffer, outputFormat: outputFormat) {
                    try self.audioFile?.write(from: monoBuffer)
                }
            } catch {
                print("❌ 녹음 쓰기 오류: \(error)")
            }

            // 오디오 레벨 업데이트 (파형 시각화)
            let level = self.calculateLevel(from: buffer)
            Task { @MainActor in
                self.audioLevel = level
                self.audioLevels.removeFirst()
                self.audioLevels.append(level)
            }
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        try audioEngine.start()
        
        print("✅ 마이크 녹음 시작됨")
        
        // 음성 인식 태스크 시작
        startRecognitionTask(request: recognitionRequest)
    }
    
    #if os(macOS)
    // MARK: - 마이크 + 시스템 오디오 별도 녹음 (macOS 전용)
    
    private func startMixedAudioCapture(recognitionRequest: SFSpeechAudioBufferRecognitionRequest, fileURL: URL) throws {
        print("🎙️🔊 마이크 + 시스템 오디오 별도 녹음 시작...")
        
        // 파일 URL 설정
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        microphoneURL = documentsPath.appendingPathComponent("mic_\(timestamp).m4a")
        systemAudioURL = documentsPath.appendingPathComponent("sys_\(timestamp).m4a")
        
        // 1. 마이크 녹음 시작 (기존 방식)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        print("🎧 오디오 입력 형식: \(inputFormat)")
        
        guard inputFormat.sampleRate > 0 && inputFormat.channelCount > 0 else {
            throw RecordingError.recognitionUnavailable
        }
        
        // 마이크 파일 생성
        let micSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: inputFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000
        ]
        
        if let micURL = microphoneURL {
            audioFile = try AVAudioFile(forWriting: micURL, settings: micSettings)
        }
        
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44100,
            channels: 1,
            interleaved: false
        )!
        
        // 마이크 탭 설치
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, when in
            guard let self = self, buffer.frameLength > 0 else { return }
            
            // 음성 인식에 전달 (마이크 음성만)
            recognitionRequest.append(buffer)
            
            // 마이크 파일에 저장
            do {
                if let monoBuffer = self.convertToMono(buffer: buffer, outputFormat: outputFormat) {
                    try self.audioFile?.write(from: monoBuffer)
                }
            } catch {
                print("❌ 마이크 녹음 오류: \(error)")
            }
        }
        
        // 오디오 엔진 시작
        audioEngine.prepare()
        try audioEngine.start()
        
        print("✅ 마이크 녹음 시작됨")
        
        // 2. 시스템 오디오 캡처 시작
        Task {
            await self.startSystemAudioCaptureToFile()
        }
        
        // 3. 음성 인식 태스크 시작
        startRecognitionTask(request: recognitionRequest)
    }
    
    // MARK: - 시스템 오디오를 파일로 직접 저장
    
    private func startSystemAudioCaptureToFile() async {
        do {
            print("🔊 시스템 오디오 캡처 시작...")
            
            guard let sysURL = systemAudioURL else { return }
            
            // ScreenCaptureKit 설정
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = content.displays.first else {
                print("❌ 디스플레이를 찾을 수 없음")
                return
            }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            
            let streamConfig = SCStreamConfiguration()
            streamConfig.capturesAudio = true
            streamConfig.excludesCurrentProcessAudio = false
            streamConfig.sampleRate = 48000
            streamConfig.channelCount = 2
            
            // 비디오 비활성화
            streamConfig.width = 1
            streamConfig.height = 1
            streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 1)
            
            // 시스템 오디오 파일 생성
            let sysSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: 2,
                AVEncoderBitRateKey: 128000
            ]
            
            systemAudioFile = try AVAudioFile(forWriting: sysURL, settings: sysSettings)
            
            // 시스템 오디오 출력 핸들러
            systemAudioOutput = SystemAudioOutputHandler { [weak self] sampleBuffer in
                self?.writeSystemAudioToFile(sampleBuffer)
            }
            
            systemAudioStream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
            
            if let stream = systemAudioStream, let output = systemAudioOutput {
                try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
                try await stream.startCapture()
                
                print("✅ 시스템 오디오 캡처 시작됨 → \(sysURL.lastPathComponent)")
            }
            
        } catch {
            print("❌ 시스템 오디오 캡처 실패: \(error)")
        }
    }
    
    // CMSampleBuffer를 파일에 쓰기
    private func writeSystemAudioToFile(_ sampleBuffer: CMSampleBuffer) {
        guard let audioFile = systemAudioFile else { return }
        
        // CMSampleBuffer를 AVAudioPCMBuffer로 변환
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else {
            return
        }
        
        // 포인터를 사용하여 AVAudioFormat 생성
        var mutableASBD = asbd.pointee
        guard let format = AVAudioFormat(streamDescription: &mutableASBD) else {
            return
        }
        
        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(numSamples)
        
        // AudioBufferList 가져오기
        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        // 데이터 복사
        let audioBuffer = audioBufferList.mBuffers
        if let data = audioBuffer.mData {
            let channelData = buffer.floatChannelData?[0]
            let byteCount = Int(audioBuffer.mDataByteSize)
            let floatCount = byteCount / MemoryLayout<Float>.size
            
            data.withMemoryRebound(to: Float.self, capacity: floatCount) { floatPtr in
                channelData?.update(from: floatPtr, count: min(floatCount, Int(buffer.frameLength)))
            }
        }
        
        // 파일에 쓰기
        do {
            try audioFile.write(from: buffer)
        } catch {
            // 에러를 너무 자주 출력하지 않도록 조용히 처리
        }
    }
    
    #endif
    
    // MARK: - 음성 인식 태스크 시작
    
    private func startRecognitionTask(request: SFSpeechAudioBufferRecognitionRequest) {
        guard let recognizer = speechRecognizer else { return }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                let nsError = error as NSError
                if nsError.code != 216 { // 216 = "No speech detected" (무시 가능)
                    print("❌ 음성 인식 오류: \(error.localizedDescription)")
                }
            }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.transcribedText = transcription
                }
                
                if result.isFinal {
                    print("✅ 최종 인식: \(transcription)")
                }
            }
        }
        
        print("✅ 음성 인식 태스크 시작됨")
    }
    
    // 스테레오를 모노로 변환
    private func convertToMono(buffer: AVAudioPCMBuffer, outputFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
            return nil
        }
        
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * outputFormat.sampleRate / buffer.format.sampleRate)
        guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            return nil
        }
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            print("❌ 변환 오류: \(error)")
            return nil
        }
        
        return convertedBuffer
    }
    
    // MARK: - 유틸리티
    
    func reset() {
        transcribedText = ""
        recordingDuration = 0
        currentRecordingURL = nil
        audioBufferCount = 0
        lastBufferTime = Date()
        audioLevel = 0.0
        audioLevels = Array(repeating: 0, count: 40)
    }

    // MARK: - 오디오 레벨 계산

    private func calculateLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        return min(rms * 10, 1.0)
    }
}

// MARK: - 에러 타입

enum RecordingError: LocalizedError {
    case permissionDenied
    case recognitionUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "마이크 또는 음성 인식 권한이 필요합니다."
        case .recognitionUnavailable:
            return "음성 인식을 사용할 수 없습니다."
        }
    }
}
#if os(macOS)
// MARK: - System Audio Output Handler
class SystemAudioOutputHandler: NSObject, SCStreamOutput {
    let sampleHandler: @Sendable (CMSampleBuffer) -> Void
    
    init(sampleHandler: @escaping @Sendable (CMSampleBuffer) -> Void) {
        self.sampleHandler = sampleHandler
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        sampleHandler(sampleBuffer)
    }
}
#endif

