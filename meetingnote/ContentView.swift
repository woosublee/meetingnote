//
//  ContentView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

// MARK: - Design System

// MARK: Color Extensions
extension Color {
    static let appBackground = Color(hex: "#0D0D0D")
    static let sidebarBg = Color(hex: "#1A1A1A")
    static let cardBg = Color(hex: "#202020")
    static let cardHover = Color(hex: "#2A2A2A")
    static let appBorder = Color(hex: "#2F2F2F")
    static let appPrimary = Color(hex: "#3B82F6")
    static let primaryHover = Color(hex: "#2563EB")
    static let appSuccess = Color(hex: "#10B981")
    static let appDanger = Color(hex: "#EF4444")
    static let appWarning = Color(hex: "#F59E0B")
    static let appSecondary = Color(hex: "#6B7280")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#9CA3AF")
    static let textTertiary = Color(hex: "#6B7280")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: Design Tokens
struct AppDesign {
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
    static let buttonCornerRadius: CGFloat = 6
    static let spacing: CGFloat = 12
    static let sidebarWidth: CGFloat = 176
    static let defaultPadding: CGFloat = 16
}

// MARK: Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(isEnabled ? Color.appPrimary : Color.appSecondary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(Color.cardBg)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.buttonCornerRadius)
                    .fill(Color.appDanger)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14))
            .foregroundColor(.textSecondary)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .fill(Color.cardBg)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

// MARK: UI Components
struct CardView<Content: View>: View {
    let content: Content
    let padding: CGFloat
    
    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.cornerRadius)
                    .fill(Color.cardBg)
            )
    }
}

struct AppDivider: View {
    var body: some View {
        Divider()
            .background(Color.appBorder)
    }
}

struct PulseView: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 1)

            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

struct WaveformVisualizationView: View {
    let levels: [Float]
    let color: Color

    var body: some View {
        Canvas { context, size in
            let count = levels.count
            guard count > 0 else { return }
            let totalSpacing = size.width * 0.4
            let barWidth = (size.width - totalSpacing) / CGFloat(count)
            let gapWidth = totalSpacing / CGFloat(count)

            for (index, level) in levels.enumerated() {
                let barHeight = max(4, CGFloat(level) * size.height * 0.9)
                let x = CGFloat(index) * (barWidth + gapWidth)
                let y = (size.height - barHeight) / 2
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                let path = Path(roundedRect: rect, cornerRadius: barWidth / 2)
                let opacity = Double(0.35 + 0.65 * min(CGFloat(level), 1.0))
                context.fill(path, with: .color(color.opacity(opacity)))
            }
        }
    }
}

struct LoadingDotsView: View {
    @State private var animatingDots: [Bool] = [false, false, false]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDots[index] ? 1.0 : 0.5)
                    .opacity(animatingDots[index] ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                animatingDots[index] = true
            }
        }
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void
    
    init(icon: String, title: String, isSelected: Bool = false, badge: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.cardBg)
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.smallCornerRadius)
                    .fill(isSelected ? Color.cardBg : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PageHeader: View {
    let icon: String
    let title: String
    let action: (() -> Void)?
    let actionLabel: String?
    let actionIcon: String?
    
    init(
        icon: String,
        title: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        actionIcon: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.action = action
        self.actionLabel = actionLabel
        self.actionIcon = actionIcon
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let action = action, let label = actionLabel {
                    Button(action: action) {
                        if let icon = actionIcon {
                            Label(label, systemImage: icon)
                                .font(.system(size: 13, weight: .medium))
                        } else {
                            Text(label)
                                .font(.system(size: 13, weight: .medium))
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal, AppDesign.defaultPadding)
            .padding(.vertical, 12)
            .background(Color.sidebarBg)
            
            AppDivider()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.textSecondary)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Label(buttonTitle, systemImage: "plus")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main Views

struct ContentView: View {
    @State private var selectedTab = "meetings"
    @State private var selectedNote: MeetingNote? = nil
    @State private var isNewRecording = false

    private var slideIn: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab, selectedNote: $selectedNote)
        } detail: {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if let note = selectedNote {
                    DocumentView(
                        note: note,
                        openInRecordingMode: isNewRecording,
                        onBack: {
                            withAnimation {
                                selectedNote = nil
                                isNewRecording = false
                            }
                        }
                    )
                    .transition(slideIn)
                } else if selectedTab == "meetings" {
                    MeetingsView(
                        onNewRecording: { note in
                            withAnimation {
                                isNewRecording = true
                                selectedNote = note
                            }
                        },
                        onOpenNote: { note in withAnimation { isNewRecording = false; selectedNote = note } }
                    )
                } else {
                    NotesListView(onOpenNote: { note in withAnimation { isNewRecording = false; selectedNote = note } })
                        .background(Color.appBackground)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: selectedNote?.id)
        }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var selectedTab: String
    @Binding var selectedNote: MeetingNote?

    var body: some View {
        ZStack {
            Color.sidebarBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.appPrimary)
                    Text("미팅 노트")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)

                AppDivider()

                ScrollView {
                    VStack(spacing: 2) {
                        SidebarItem(
                            icon: "mic.fill",
                            title: "미팅",
                            isSelected: selectedTab == "meetings"
                        ) {
                            withAnimation { selectedTab = "meetings"; selectedNote = nil }
                        }

                        SidebarItem(
                            icon: "note.text",
                            title: "노트",
                            isSelected: selectedTab == "notes"
                        ) {
                            withAnimation { selectedTab = "notes"; selectedNote = nil }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(width: AppDesign.sidebarWidth)
    }
}

// MARK: - Meetings View
struct MeetingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [MeetingNote]
    let onNewRecording: (MeetingNote) -> Void
    let onOpenNote: (MeetingNote) -> Void

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(
                icon: "mic.fill",
                title: "미팅",
                action: startNewRecording,
                actionLabel: "새 녹음",
                actionIcon: "plus"
            )

            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        if !notes.isEmpty {
                            Text("모든 미팅")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textSecondary)
                                .textCase(.uppercase)
                        }

                        if notes.isEmpty {
                            EmptyStateView(
                                icon: "waveform.badge.mic",
                                title: "첫 미팅을 시작하세요",
                                subtitle: "새 녹음 버튼을 눌러 시작하세요",
                                buttonTitle: "새 녹음"
                            ) { startNewRecording() }
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                                    MeetingListItem(note: note, onOpen: { onOpenNote(note) })
                                }
                            }
                        }
                    }
                }
                .padding(AppDesign.defaultPadding)
            }
        }
    }

    private func startNewRecording() {
        let title = "미팅 - \(Date().formatted(date: .abbreviated, time: .shortened))"
        let note = MeetingNote(title: title, transcribedText: "", editedMarkdown: "", duration: 0)
        modelContext.insert(note)
        try? modelContext.save()
        onNewRecording(note)
    }
}

// MARK: - Meeting List Item
struct MeetingListItem: View {
    let note: MeetingNote
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            CardView(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(note.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        // AI 처리 배지
                        if note.hasAIContent {
                            Label("AI", systemImage: "wand.and.stars")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(Color.appPrimary.opacity(0.15))
                                )
                        }
                    }

                    HStack(spacing: 12) {
                        if note.duration > 0 {
                            Label(formatDuration(note.duration), systemImage: "clock")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                        if !note.transcribedText.isEmpty {
                            Label("\(note.transcribedText.split(separator: " ").count)단어", systemImage: "text.alignleft")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    if !note.transcribedText.isEmpty {
                        Text(note.transcribedText)
                            .font(.system(size: 13))
                            .foregroundColor(.textTertiary)
                            .lineLimit(2)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}


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
    @State private var isProcessing = false
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
                                Text(formatDuration(audioManager.recordingDuration))
                                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                                    .foregroundColor(.appDanger)
                            }
                        } else if isProcessing {
                            HStack(spacing: 6) {
                                ProgressView().scaleEffect(0.65)
                                Text("AI 처리 중...").font(.system(size: 12)).foregroundColor(.textSecondary)
                            }
                        }
                    }
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
                        Text(note.createdAt, format: .dateTime.year().month().day())
                        if isRecording && audioManager.recordingDuration > 0 {
                            Text("·"); Text(formatDuration(audioManager.recordingDuration)).monospacedDigit()
                        } else if note.duration > 0 {
                            Text("·"); Text(formatDuration(note.duration)).monospacedDigit()
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
            }
            .onChange(of: audioManager.transcribedText) { _, _ in
                withAnimation { proxy.scrollTo("transcript", anchor: .bottom) }
            }
        }
    }

    // MARK: - Tab Bar (원본 항상 + 전사 텍스트 있을 때 AI 탭 표시)
    private var docTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(visibleTabs, id: \.self) { tab in
                    Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selectedDocTab = tab } }) {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon).font(.system(size: 11))
                            Text(tab.title).font(.system(size: 13, weight: .medium))
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
            TextEditor(text: Binding(
                get: { note.transcribedText },
                set: { note.transcribedText = $0; note.updatedAt = Date(); try? modelContext.save() }
            ))
            .font(.system(size: 16)).foregroundColor(.textPrimary).lineSpacing(7)
            .scrollContentBackground(.hidden).background(Color.appBackground)
            .padding(.horizontal, 44).frame(minHeight: 360)

        case .summary:
            aiTabContent(
                text: note.summaryText,
                icon: "doc.text", emptyTitle: "요약 없음",
                emptyDescription: "AI가 미팅 내용을 핵심 위주로 요약합니다",
                generateLabel: "요약 생성", onGenerate: processSummary,
                onUpdate: { note.summaryText = $0; note.updatedAt = Date(); try? modelContext.save() }
            )
        case .minutes:
            aiTabContent(
                text: note.minutesText,
                icon: "doc.richtext", emptyTitle: "회의록 없음",
                emptyDescription: "참석자, 안건, 결정 사항을 구조화된 형식으로 정리합니다",
                generateLabel: "회의록 생성", onGenerate: processAsMinutes,
                onUpdate: { note.minutesText = $0; note.updatedAt = Date(); try? modelContext.save() }
            )
        case .actions:
            aiTabContent(
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
        text: String?,
        icon: String, emptyTitle: String, emptyDescription: String,
        generateLabel: String,
        onGenerate: @escaping () -> Void,
        onUpdate: @escaping (String) -> Void
    ) -> some View {
        if let content = text, !content.isEmpty {
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: onGenerate) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 11))
                        Text("재생성").font(.system(size: 12))
                    }
                    .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain).disabled(isProcessing)
                .padding(.trailing, 48)

                TextEditor(text: Binding(get: { content }, set: { onUpdate($0) }))
                    .font(.system(size: 16)).foregroundColor(.textPrimary).lineSpacing(7)
                    .scrollContentBackground(.hidden).background(Color.appBackground)
                    .padding(.horizontal, 44).frame(minHeight: 360)
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
                        Label(isProcessing ? "생성 중..." : generateLabel, systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isProcessing)
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
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Spacer()
                    Button(action: {
                        note.customResults.remove(at: index)
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
                .padding(.trailing, 48)

                TextEditor(text: Binding(
                    get: { note.customResults[index] },
                    set: { note.customResults[index] = $0; note.updatedAt = Date(); try? modelContext.save() }
                ))
                .font(.system(size: 16)).foregroundColor(.textPrimary).lineSpacing(7)
                .scrollContentBackground(.hidden).background(Color.appBackground)
                .padding(.horizontal, 44).frame(minHeight: 360)
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
                    Label(isProcessing ? "생성 중..." : "생성", systemImage: "sparkles")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(customPromptInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
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
        note.transcribedText = audioManager.transcribedText
        note.editedMarkdown = audioManager.transcribedText
        note.duration = audioManager.recordingDuration
        if let url = audioManager.currentRecordingURL { note.audioFileURL = url }
        note.updatedAt = Date()
        try? modelContext.save()
    }

    private func processSummary() {
        Task {
            isProcessing = true; defer { isProcessing = false }
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
            isProcessing = true; defer { isProcessing = false }
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
            isProcessing = true; defer { isProcessing = false }
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
            isProcessing = true; defer { isProcessing = false }
            do {
                let result = try await llmProcessor.processWithCustomPrompt(text: note.transcribedText, prompt: customPromptInput)
                await MainActor.run {
                    note.customResults.append(result)
                    note.updatedAt = Date()
                    try? modelContext.save()
                    customPromptInput = ""
                    withAnimation { selectedDocTab = .customResult(note.customResults.count - 1) }
                }
            } catch { await MainActor.run { errorMessage = "처리 실패: \(error.localizedDescription)"; showingError = true } }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        return hours > 0
            ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MeetingNote.self, inMemory: true)
        .preferredColorScheme(.dark)
}
