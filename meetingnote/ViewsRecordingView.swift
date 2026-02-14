//
//  RecordingView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var audioManager = AudioRecorderManager()
    @State private var showingEditor = false
    @State private var currentNote: MeetingNote?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var permissionsChecked = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 녹음 시간 표시
            Text(audioManager.recordingDuration.formattedDuration())
                .font(.system(size: 72, weight: .thin, design: .monospaced))
                .foregroundStyle(.primary)
            
            // 전사된 텍스트 표시
            // 전사된 텍스트 표시
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if audioManager.isRecording && audioManager.transcribedText.isEmpty {
                        // 녹음 중이지만 텍스트가 없을 때 도움말 표시
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🎤 녹음 중...")
                                .font(.headline)
                            
                            Text("실시간 전사를 위해 말씀해주세요.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Text("⚠️ 전사가 안 되나요?")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("1. 시스템 환경설정 > 사운드 > 입력에서\n   마이크 입력 레벨을 확인하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("2. 입력 볼륨이 낮거나 음소거되어 있지 않은지\n   확인하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("3. 올바른 마이크가 선택되어 있는지 확인하세요")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        Text(audioManager.transcribedText.isEmpty ? "녹음을 시작하면 실시간으로 전사됩니다..." : audioManager.transcribedText)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(maxHeight: 300)
            .background(.quaternary)
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // 녹음 버튼
            Button {
                if audioManager.isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                ZStack {
                    // 외곽 원 (녹음 중일 때만 펄스 효과)
                    if audioManager.isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                            .frame(width: 90, height: 90)
                            .scaleEffect(audioManager.isRecording ? 1.2 : 1.0)
                            .opacity(audioManager.isRecording ? 0 : 1)
                            .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: audioManager.isRecording)
                    }
                    
                    // 메인 버튼
                    Circle()
                        .fill(audioManager.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                    
                    // 아이콘
                    if audioManager.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // 상태 텍스트
            HStack(spacing: 4) {
                if audioManager.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    
                    Text("녹음 중")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("녹음 시작")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .navigationTitle("AI 미팅 노트")
        .alert("오류", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingEditor) {
            if let note = currentNote {
                EditorView(note: note)
            }
        }
        .task {
            if !permissionsChecked {
                await audioManager.requestPermissions()
                permissionsChecked = true
                
                // 권한 확인
                if !audioManager.audioPermissionGranted {
                    errorMessage = "마이크 권한이 필요합니다.\n\nmacOS: 시스템 환경설정 > 보안 및 개인 정보 보호 > 마이크에서 이 앱을 활성화하세요."
                    showingError = true
                } else if !audioManager.speechPermissionGranted {
                    errorMessage = "음성 인식 권한이 필요합니다.\n\n시스템 환경설정 > 보안 및 개인 정보 보호 > 음성 인식에서 이 앱을 활성화하세요."
                    showingError = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func startRecording() {
        Task {
            do {
                try await audioManager.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func stopRecording() {
        audioManager.stopRecording()
        
        // 녹음이 완료되면 새 노트 생성
        let note = MeetingNote(
            title: "미팅 노트 - \(Date().formatted(date: .abbreviated, time: .shortened))",
            audioFileURL: audioManager.currentRecordingURL,
            transcribedText: audioManager.transcribedText,
            editedMarkdown: audioManager.transcribedText,
            duration: audioManager.recordingDuration
        )
        
        modelContext.insert(note)
        
        do {
            try modelContext.save()
            currentNote = note
            showingEditor = true
        } catch {
            errorMessage = "노트 저장에 실패했습니다: \(error.localizedDescription)"
            showingError = true
        }
        
        // 리셋
        audioManager.reset()
    }
    
}

#Preview {
    RecordingView()
        .modelContainer(for: MeetingNote.self)
}
