//
//  DocumentView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

// MARK: - Document View (녹음 + 편집 통합)
struct DocumentView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var note: MeetingNote

    // 녹음 관련
    @State private var audioManager = AudioRecorderManager()
    @State private var permissionsChecked = false
    @State private var isPulsing = false
    private let openInRecordingMode: Bool

    // 문서 편집
    @State private var llmProcessor = LLMProcessor()
    @State private var selectedDocTab: DocTab = .original
    @State private var processingTabs: Set<DocTab> = []
    @State private var showingDeleteConfirmation = false
    @State private var customPromptInput = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    let onBack: () -> Void

    init(note: MeetingNote, openInRecordingMode: Bool = false, onBack: @escaping () -> Void) {
        self.note = note
        self.openInRecordingMode = openInRecordingMode
        self.onBack = onBack
    }

    private var isRecording: Bool { audioManager.isRecording }

    private enum DocTab: Hashable {
        case original, summary, minutes, actions
        case customResult(Int) // 생성된 커스텀 결과 (인덱스)
        case customNew         // 새 커스텀 생성 탭 (항상 마지막)

        var title: String {
            switch self {
            case .original:         return "원본"
            case .summary:          return "요약"
            case .minutes:          return "회의록"
            case .actions:          return "액션 아이템"
            case .customResult(let i): return "커스텀\(i + 1)"
            case .customNew:        return "커스텀"
            }
        }
        var icon: String {
            switch self {
            case .original:      return "text.alignleft"
            case .summary:       return "doc.text"
            case .minutes:       return "doc.richtext"
            case .actions:       return "checklist"
            case .customResult:  return "wand.and.stars"
            case .customNew:     return "plus"
            }
        }
    }

    // 현재 노트 상태에 따른 가시 탭 목록
    private var visibleTabs: [DocTab] {
        var tabs: [DocTab] = [.original]
        guard !note.transcribedText.isEmpty else { return tabs }
        tabs.append(contentsOf: [.summary, .minutes, .actions])
        for i in 0..<note.customResults.count {
            tabs.append(.customResult(i))
        }
        tabs.append(.customNew)
        return tabs
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                documentScrollView
                Color.clear.frame(height: isRecording ? 180 : 0)
            }

            if isRecording { recordingBar }
        }
        .alert("오류", isPresented: $showingError) {
            Button("확인", role: .cancel) {}
        } message: { Text(errorMessage) }
        .alert("노트 삭제", isPresented: $showingDeleteConfirmation) {
            Button("삭제", role: .destructive) { deleteNote() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("'\(note.title)' 노트와 관련된 모든 파일이 삭제됩니다.")
        }
        .onChange(of: note.title) { _, _ in note.updatedAt = Date(); try? modelContext.save() }
        .onChange(of: note.transcribedText) { _, newValue in
            if newValue.isEmpty, selectedDocTab != .original { selectedDocTab = .original }
        }
        .task {
            guard openInRecordingMode && !permissionsChecked else { return }
            permissionsChecked = true
            await audioManager.requestPermissions()
            guard audioManager.audioPermissionGranted else {
                errorMessage = "마이크 권한이 필요합니다.\n시스템 환경설정 > 보안 및 개인 정보 보호 > 마이크에서 앱을 허용해주세요."
                showingError = true
                return
            }
            guard audioManager.speechPermissionGranted else {
                errorMessage = "음성 인식 권한이 필요합니다.\n시스템 환경설정 > 보안 및 개인 정보 보호 > 음성 인식에서 앱을 허용해주세요."
                showingError = true
                return
            }
            do { try await audioManager.startRecording() } catch {
                errorMessage = error.localizedDescription; showingError = true
            }
        }
    }

    // MARK: - Document Scroll View
    private var documentScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 인라인 네비게이션 바 (툴바 대신)
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                                Text("목록").font(.system(size: 13))
                            }
                            .foregroundColor(.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if isRecording {
                            HStack(spacing: 6) {
                                PulseView(color: .appDanger)
                                Text(audioManager.recordingDuration.formattedDuration())
                                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                                    .foregroundColor(.appDanger)
                            }
                        } else if !processingTabs.isEmpty {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.65).frame(width: 14, height: 14)
                                Text("AI 처리 중...").font(.system(size: 12)).foregroundColor(.textSecondary)
                            }
                        }

                        if !isRecording {
                            Button(action: { showingDeleteConfirmation = true }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(height: 30)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                    // 제목
                    TextField("제목 없음", text: $note.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 48)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    // 메타데이터
                    HStack(spacing: 6) {
                        Text(DateFormatter.appDefault.string(from: note.createdAt))
                        if isRecording && audioManager.recordingDuration > 0 {
                            Text("·"); Text(audioManager.recordingDuration.formattedDuration()).monospacedDigit()
                        } else if note.duration > 0 {
                            Text("·"); Text(note.duration.formattedDuration()).monospacedDigit()
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.textTertiary)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 20)

                    if isRecording {
                        // 녹음 중: 구분선 + 실시간 전사
                        Rectangle().fill(Color.appBorder).frame(height: 1)
                            .padding(.horizontal, 48).padding(.bottom, 20)
                        if audioManager.transcribedText.isEmpty {
                            HStack(spacing: 10) {
                                LoadingDotsView()
                                Text("듣고 있는 중...").font(.system(size: 16)).foregroundColor(.textTertiary)
                            }
                            .padding(.horizontal, 48)
                        } else {
                            Text(audioManager.transcribedText)
                                .font(.system(size: 16)).foregroundColor(.textPrimary).lineSpacing(7)
                                .padding(.horizontal, 48).id("transcript")
                        }
                    } else if openInRecordingMode && note.transcribedText.isEmpty {
                        // 녹음 시작 전: 권한 확인 / 시작 로딩
                        HStack(spacing: 10) {
                            ProgressView().scaleEffect(0.75)
                            Text(permissionsChecked ? "녹음 시작 중..." : "권한 확인 중...")
                                .font(.system(size: 14)).foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, 48).padding(.top, 20)
                    } else {
                        // 편집 모드: 탭 바 항상 표시
                        docTabBar.padding(.bottom, 16)
                        Rectangle().fill(Color.appBorder).frame(height: 1)
                            .padding(.horizontal, 48).padding(.bottom, 20)
                        tabContentView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 40)
            }
            .onChange(of: audioManager.transcribedText) { _, _ in
                withAnimation { proxy.scrollTo("transcript", anchor: .bottom) }
            }
        }
    }

    private func tabTitle(for tab: DocTab) -> String {
        if case .customResult(let i) = tab,
           i < note.customResultNames.count,
           !note.customResultNames[i].isEmpty {
            return note.customResultNames[i]
        }
        return tab.title
    }

    // MARK: - Tab Bar (원본 항상 + 전사 텍스트 있을 때 AI 탭 표시)
    private var docTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedDocTab = tab } }) {
                        HStack(spacing: 5) {
                            if processingTabs.contains(tab) {
                                ProgressView().scaleEffect(0.65).frame(width: 11, height: 11)
                            } else {
                                Image(systemName: tab.icon).font(.system(size: 11))
                            }
                            Text(tabTitle(for: tab)).font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(selectedDocTab == tab ? .white : .textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(selectedDocTab == tab ? Color.appPrimary : Color.cardBg))
                        .overlay(Capsule().stroke(selectedDocTab == tab ? Color.clear : Color.appBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 48)
        }
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedDocTab {
        case .original:
            MarkdownEditor(
                text: Binding(
                    get: { note.transcribedText },
                    set: { note.transcribedText = $0; note.updatedAt = Date(); try? modelContext.save() }
                )
            )
            .padding(.horizontal, 48)

        case .summary:
            aiTabContent(
                tab: .summary,
                text: note.summaryText,
                icon: "doc.text", emptyTitle: "요약 없음",
                emptyDescription: "AI가 미팅 내용을 핵심 위주로 요약합니다",
                generateLabel: "요약 생성", onGenerate: processSummary,
                onUpdate: { note.summaryText = $0; note.updatedAt = Date(); try? modelContext.save() }
            )
        case .minutes:
            aiTabContent(
                tab: .minutes,
                text: note.minutesText,
                icon: "doc.richtext", emptyTitle: "회의록 없음",
                emptyDescription: "참석자, 안건, 결정 사항을 구조화된 형식으로 정리합니다",
                generateLabel: "회의록 생성", onGenerate: processAsMinutes,
                onUpdate: { note.minutesText = $0; note.updatedAt = Date(); try? modelContext.save() }
            )
        case .actions:
            aiTabContent(
                tab: .actions,
                text: note.actionItemsText,
                icon: "checklist", emptyTitle: "액션 아이템 없음",
                emptyDescription: "미팅에서 결정된 할 일과 담당자를 추출합니다",
                generateLabel: "액션 아이템 추출", onGenerate: extractActionItems,
                onUpdate: { note.actionItemsText = $0; note.updatedAt = Date(); try? modelContext.save() }
            )
        case .customResult(let i):
            customResultView(index: i)
        case .customNew:
            customNewTabContent
        }
    }

    // MARK: - AI Tab (없으면 생성 버튼 / 있으면 뷰어)
    @ViewBuilder
    private func aiTabContent(
        tab: DocTab,
        text: String?,
        icon: String, emptyTitle: String, emptyDescription: String,
        generateLabel: String,
        onGenerate: @escaping () -> Void,
        onUpdate: @escaping (String) -> Void
    ) -> some View {
        let isTabProcessing = processingTabs.contains(tab)
        if let content = text, !content.isEmpty {
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onGenerate) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                        Text("재생성").font(.system(size: 12))
                    }
                    .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain).disabled(isTabProcessing)
                .padding(.trailing, 48)

                MarkdownEditor(
                    text: Binding(get: { content }, set: { onUpdate($0) })
                )
                .padding(.horizontal, 48)
            }
        } else {
            VStack(spacing: 16) {
                Image(systemName: icon).font(.system(size: 40, weight: .light)).foregroundColor(.textTertiary)
                Text(emptyTitle).font(.system(size: 16, weight: .semibold)).foregroundColor(.textSecondary)
                Text(emptyDescription)
                    .font(.system(size: 13)).foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center).frame(maxWidth: 300)

                if !llmProcessor.isAvailable {
                    Text(llmProcessor.availabilityStatus)
                        .font(.system(size: 12)).foregroundColor(.appWarning)
                        .multilineTextAlignment(.center)
                } else {
                    Button(action: onGenerate) {
                        Label(isTabProcessing ? "생성 중..." : generateLabel, systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isTabProcessing)
                    .contentShape(Rectangle())
                }
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity).padding(.vertical, 60).padding(.horizontal, 48)
        }
    }

    // MARK: - 커스텀 결과 뷰어 (커스텀1, 커스텀2, ...)
    @ViewBuilder
    private func customResultView(index: Int) -> some View {
        if index < note.customResults.count {
            VStack(alignment: .leading, spacing: 0) {
                // 이름 편집 + 삭제 + 토글 버튼 행
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                    TextField(
                        "커스텀 이름",
                        text: Binding(
                            get: {
                                index < note.customResultNames.count
                                    ? note.customResultNames[index]
                                    : "커스텀\(index + 1)"
                            },
                            set: { newName in
                                while note.customResultNames.count <= index {
                                    note.customResultNames.append("")
                                }
                                note.customResultNames[index] = newName
                                note.updatedAt = Date()
                                try? modelContext.save()
                            }
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textSecondary)

                    Spacer()

                    Button(action: {
                        note.customResults.remove(at: index)
                        if index < note.customResultNames.count {
                            note.customResultNames.remove(at: index)
                        }
                        note.updatedAt = Date()
                        try? modelContext.save()
                        withAnimation { selectedDocTab = .original }
                    }) {
                        Label("삭제", systemImage: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.appDanger)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 12)

                MarkdownEditor(
                    text: Binding(
                        get: { note.customResults[index] },
                        set: { note.customResults[index] = $0; note.updatedAt = Date(); try? modelContext.save() }
                    )
                )
                .padding(.horizontal, 48)
            }
        }
    }

    // MARK: - 새 커스텀 생성 탭 (항상 마지막)
    private var customNewTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("원본 텍스트를 어떻게 처리할지 설명하세요")
                .font(.system(size: 13)).foregroundColor(.textSecondary)

            TextEditor(text: $customPromptInput)
                .font(.system(size: 15)).foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: AppDesign.cornerRadius).fill(Color.cardBg))
                .frame(minHeight: 80, maxHeight: 160)

            HStack {
                Spacer()
                Button(action: processWithCustomPrompt) {
                    Label(processingTabs.contains(.customNew) ? "생성 중..." : "생성", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(customPromptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || processingTabs.contains(.customNew))
            }
        }
        .padding(.horizontal, 48).padding(.bottom, 40)
    }

    // MARK: - Recording Bar
    private var recordingBar: some View {
        VStack(spacing: 12) {
            WaveformVisualizationView(levels: audioManager.audioLevels, color: .appDanger)
                .frame(height: 36).padding(.horizontal, 60)

            Button(action: stopRecording) {
                ZStack {
                    Circle()
                        .stroke(Color.appDanger.opacity(0.2), lineWidth: 3)
                        .frame(width: 90, height: 90)
                        .scaleEffect(isPulsing ? 1.45 : 1.0).opacity(isPulsing ? 0 : 0.8)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
                    Circle().fill(Color.appDanger).frame(width: 64, height: 64)
                        .shadow(color: Color.appDanger.opacity(0.35), radius: 12, x: 0, y: 4)
                    RoundedRectangle(cornerRadius: 5).fill(.white).frame(width: 22, height: 22)
                }
            }
            .buttonStyle(.plain)
            .onChange(of: isRecording) { _, v in withAnimation { isPulsing = v } }

            Text("탭하여 중지").font(.system(size: 12)).foregroundColor(.textTertiary)
        }
        .padding(.bottom, 36).padding(.top, 20).frame(maxWidth: .infinity)
        .background(LinearGradient(
            colors: [Color.appBackground.opacity(0), Color.appBackground, Color.appBackground],
            startPoint: .top, endPoint: .bottom
        ))
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }

    // MARK: - Actions
    private func stopRecording() {
        audioManager.stopRecording()
        let transcribed = audioManager.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalText = transcribed.isEmpty ? "녹음된 내용이 없습니다." : transcribed
        note.transcribedText = finalText
        note.editedMarkdown = finalText
        note.duration = audioManager.recordingDuration
        if let url = audioManager.currentRecordingURL { note.audioFileURL = url }
        note.updatedAt = Date()
        try? modelContext.save()
    }

    private func processSummary() {
        Task {
            processingTabs.insert(.summary); defer { processingTabs.remove(.summary) }
            do {
                let result = try await llmProcessor.summarize(text: note.transcribedText)
                await MainActor.run {
                    note.summaryText = result; note.updatedAt = Date(); try? modelContext.save()
                    withAnimation { selectedDocTab = .summary }
                }
            } catch { await MainActor.run { errorMessage = "요약 실패: \(error.localizedDescription)"; showingError = true } }
        }
    }

    private func processAsMinutes() {
        Task {
            processingTabs.insert(.minutes); defer { processingTabs.remove(.minutes) }
            do {
                let result = try await llmProcessor.formatAsMeetingMinutes(text: note.transcribedText)
                await MainActor.run {
                    note.minutesText = result; note.updatedAt = Date(); try? modelContext.save()
                    withAnimation { selectedDocTab = .minutes }
                }
            } catch { await MainActor.run { errorMessage = "회의록 작성 실패: \(error.localizedDescription)"; showingError = true } }
        }
    }

    private func extractActionItems() {
        Task {
            processingTabs.insert(.actions); defer { processingTabs.remove(.actions) }
            do {
                let items = try await llmProcessor.extractActionItems(text: note.transcribedText)
                var result = "# 액션 아이템\n\n"
                for (i, task) in items.tasks.enumerated() {
                    let assignee = i < items.assignees.count ? items.assignees[i] : "미정"
                    let due = i < items.dueDates.count ? items.dueDates[i] : "미정"
                    result += "- [ ] \(task) — 담당: \(assignee), 마감: \(due)\n"
                }
                await MainActor.run {
                    note.actionItemsText = result; note.updatedAt = Date(); try? modelContext.save()
                    withAnimation { selectedDocTab = .actions }
                }
            } catch { await MainActor.run { errorMessage = "액션 아이템 추출 실패: \(error.localizedDescription)"; showingError = true } }
        }
    }

    private func processWithCustomPrompt() {
        guard !customPromptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            processingTabs.insert(.customNew); defer { processingTabs.remove(.customNew) }
            do {
                let result = try await llmProcessor.processWithCustomPrompt(text: note.transcribedText, prompt: customPromptInput)
                await MainActor.run {
                    let newIndex = note.customResults.count
                    note.customResults.append(result)
                    note.customResultNames.append("커스텀\(newIndex + 1)")
                    note.updatedAt = Date()
                    try? modelContext.save()
                    customPromptInput = ""
                    withAnimation { selectedDocTab = .customResult(newIndex) }
                }
            } catch { await MainActor.run { errorMessage = "처리 실패: \(error.localizedDescription)"; showingError = true } }
        }
    }

    private func deleteNote() {
        if let audioURL = note.audioFileURL,
           FileManager.default.fileExists(atPath: audioURL.path) {
            try? FileManager.default.removeItem(at: audioURL)
        }
        modelContext.delete(note)
        try? modelContext.save()
        onBack()
    }
}
