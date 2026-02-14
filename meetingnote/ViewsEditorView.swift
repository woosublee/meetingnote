//
//  EditorView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var note: MeetingNote
    
    @State private var selectedTab: EditorTab = .transcription
    @State private var editedTranscription: String
    @State private var editedMarkdown: String
    @State private var llmProcessor = LLMProcessor()
    @State private var showingCustomPrompt = false
    @State private var customPrompt = ""
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false
    
    enum EditorTab {
        case transcription  // 전사 텍스트
        case processed      // 후처리 텍스트
    }
    
    init(note: MeetingNote) {
        self.note = note
        _editedTranscription = State(initialValue: note.transcribedText)
        _editedMarkdown = State(initialValue: note.processedText ?? note.editedMarkdown)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // LLM 비가용 배너
                    if !llmProcessor.isAvailable {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.appWarning)
                            Text(llmProcessor.availabilityStatus)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.appWarning.opacity(0.1))
                    }

                    // 탭 선택
                    Picker("보기", selection: $selectedTab) {
                        Text("전사 텍스트").tag(EditorTab.transcription)
                        Text("AI 결과").tag(EditorTab.processed)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    AppDivider()

                    // 탭 내용
                    TabView(selection: $selectedTab) {
                        TextEditor(text: $editedTranscription)
                            .font(.system(size: 15))
                            .scrollContentBackground(.hidden)
                            .background(Color.appBackground)
                            .padding(12)
                            .tag(EditorTab.transcription)

                        Group {
                            if note.processedText != nil || !editedMarkdown.isEmpty {
                                MarkdownEditorView(text: Binding(
                                    get: { AttributedString(editedMarkdown) },
                                    set: { editedMarkdown = String($0.characters) }
                                ))
                                .tag(EditorTab.processed)
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 52, weight: .ultraLight))
                                        .foregroundColor(.textTertiary)
                                    Text("아래 AI 버튼으로 텍스트를 정리해보세요")
                                        .font(.system(size: 15))
                                        .foregroundColor(.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .tag(EditorTab.processed)
                            }
                        }
                    }
                    #if os(iOS)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    #endif

                    // AI 액션 칩 영역 (공간 확보)
                    Color.clear.frame(height: 80)
                }

                // AI 액션 칩 바 (고정 하단)
                aiActionBar
            }
            .navigationTitle(note.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.appDanger)
                        }
                        Button("저장") {
                            saveNote()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        saveNote()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("삭제", systemImage: "trash")
                    }
                }
                #endif
            }
            .confirmationDialog("노트 삭제", isPresented: $showingDeleteConfirmation) {
                Button("삭제", role: .destructive) { deleteNote() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("이 노트와 관련된 녹음 파일을 모두 삭제하시겠습니까?")
            }
            .alert("커스텀 프롬프트", isPresented: $showingCustomPrompt) {
                TextField("프롬프트를 입력하세요", text: $customPrompt)
                Button("취소", role: .cancel) {}
                Button("처리") { processWithCustomPrompt() }
            } message: {
                Text("텍스트를 어떻게 처리할지 설명해주세요.")
            }
            .alert("오류", isPresented: $showingError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - AI Action Bar
    private var aiActionBar: some View {
        VStack(spacing: 0) {
            AppDivider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("AI 처리 중...")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        AIChipButton(
                            label: "요약",
                            icon: "doc.text",
                            isEnabled: llmProcessor.isAvailable,
                            action: processSummary
                        )
                        AIChipButton(
                            label: "회의록",
                            icon: "doc.richtext",
                            isEnabled: llmProcessor.isAvailable,
                            action: processAsMinutes
                        )
                        AIChipButton(
                            label: "액션 아이템",
                            icon: "checklist",
                            isEnabled: llmProcessor.isAvailable,
                            action: extractActionItems
                        )
                        AIChipButton(
                            label: "커스텀",
                            icon: "wand.and.stars",
                            isEnabled: llmProcessor.isAvailable,
                            action: { showingCustomPrompt = true }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.sidebarBg)
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        // 전사 텍스트 저장
        note.transcribedText = editedTranscription
        
        // 후처리 텍스트 저장
        if !editedMarkdown.isEmpty {
            note.processedText = editedMarkdown
            note.editedMarkdown = editedMarkdown
        }
        
        note.updatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "저장 실패: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteNote() {
        print("🗑️ 노트 삭제 시작: \(note.title)")
        
        // 1. 녹음 파일 삭제
        if let audioURL = note.audioFileURL {
            do {
                if FileManager.default.fileExists(atPath: audioURL.path) {
                    try FileManager.default.removeItem(at: audioURL)
                    print("✅ 녹음 파일 삭제됨: \(audioURL.lastPathComponent)")
                } else {
                    print("⚠️ 녹음 파일이 존재하지 않음: \(audioURL.lastPathComponent)")
                }
            } catch {
                print("❌ 녹음 파일 삭제 실패: \(error.localizedDescription)")
            }
        }
        
        // 2. 노트 객체 삭제 (전사문, 후처리 텍스트 모두 삭제됨)
        modelContext.delete(note)
        
        // 3. 변경사항 저장 및 화면 닫기
        do {
            try modelContext.save()
            print("✅ 노트 삭제 완료")
            dismiss()
        } catch {
            errorMessage = "삭제 실패: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func processSummary() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let summary = try await llmProcessor.summarize(text: editedTranscription)
                await MainActor.run {
                    editedMarkdown = summary
                    note.processedText = summary
                    selectedTab = .processed  // 후처리 탭으로 전환
                }
            } catch {
                await MainActor.run {
                    errorMessage = "요약 실패: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func processAsMinutes() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let minutes = try await llmProcessor.formatAsMeetingMinutes(text: editedTranscription)
                await MainActor.run {
                    editedMarkdown = minutes
                    note.processedText = minutes
                    selectedTab = .processed  // 후처리 탭으로 전환
                }
            } catch {
                await MainActor.run {
                    errorMessage = "회의록 작성 실패: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func extractActionItems() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let actionItems = try await llmProcessor.extractActionItems(text: editedTranscription)
                
                var result = "# 액션 아이템\n\n"
                for (index, task) in actionItems.tasks.enumerated() {
                    let assignee = index < actionItems.assignees.count ? actionItems.assignees[index] : "미정"
                    let dueDate = index < actionItems.dueDates.count ? actionItems.dueDates[index] : "미정"
                    result += "- [ ] \(task) - 담당: \(assignee), 마감: \(dueDate)\n"
                }
                
                await MainActor.run {
                    editedMarkdown = result
                    note.processedText = result
                    selectedTab = .processed  // 후처리 탭으로 전환
                }
            } catch {
                await MainActor.run {
                    errorMessage = "액션 아이템 추출 실패: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func processWithCustomPrompt() {
        guard !customPrompt.isEmpty else { return }
        
        Task {
            isProcessing = true
            defer { isProcessing = false }
            
            do {
                let result = try await llmProcessor.processWithCustomPrompt(
                    text: editedTranscription,
                    prompt: customPrompt
                )
                await MainActor.run {
                    editedMarkdown = result
                    note.processedText = result
                    selectedTab = .processed  // 후처리 탭으로 전환
                    customPrompt = ""
                }
            } catch {
                await MainActor.run {
                    errorMessage = "처리 실패: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - AI Chip Button
struct AIChipButton: View {
    let label: String
    let icon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isEnabled ? .appPrimary : .textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isEnabled ? Color.appPrimary.opacity(0.12) : Color.cardBg)
                )
                .overlay(
                    Capsule()
                        .stroke(isEnabled ? Color.appPrimary.opacity(0.3) : Color.appBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MeetingNote.self, configurations: config)
    
    let note = MeetingNote(
        title: "샘플 미팅",
        transcribedText: "이것은 샘플 전사 텍스트입니다.",
        editedMarkdown: "이것은 샘플 전사 텍스트입니다."
    )
    
    container.mainContext.insert(note)
    
    return EditorView(note: note)
        .modelContainer(container)
}
