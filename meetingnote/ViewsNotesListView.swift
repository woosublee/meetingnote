//
//  NotesListView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit
#endif

// MARK: - Date Group Model
private struct DateGroup: Identifiable {
    let id: String
    let title: String
    let notes: [MeetingNote]
}

struct NotesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeetingNote.createdAt, order: .reverse) private var notes: [MeetingNote]

    @State private var searchText = ""
    var onOpenNote: (MeetingNote) -> Void = { _ in }
    var onSwitchToMeetings: () -> Void = {}

    var filteredNotes: [MeetingNote] {
        if searchText.isEmpty {
            return notes
        } else {
            return notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.transcribedText.localizedCaseInsensitiveContains(searchText) ||
                note.editedMarkdown.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private var groupedNotes: [DateGroup] {
        let calendar = Calendar.current
        var today: [MeetingNote] = []
        var yesterday: [MeetingNote] = []
        var thisWeek: [MeetingNote] = []
        var earlier: [MeetingNote] = []

        for note in filteredNotes {
            if calendar.isDateInToday(note.createdAt) {
                today.append(note)
            } else if calendar.isDateInYesterday(note.createdAt) {
                yesterday.append(note)
            } else {
                let diff = calendar.dateComponents([.day], from: note.createdAt, to: Date()).day ?? 0
                if diff < 7 {
                    thisWeek.append(note)
                } else {
                    earlier.append(note)
                }
            }
        }

        var groups: [DateGroup] = []
        if !today.isEmpty { groups.append(DateGroup(id: "today", title: "오늘", notes: today)) }
        if !yesterday.isEmpty { groups.append(DateGroup(id: "yesterday", title: "어제", notes: yesterday)) }
        if !thisWeek.isEmpty { groups.append(DateGroup(id: "thisWeek", title: "이번 주", notes: thisWeek)) }
        if !earlier.isEmpty { groups.append(DateGroup(id: "earlier", title: "이전", notes: earlier)) }
        return groups
    }

    var body: some View {
        #if os(macOS)
        contentView
        #else
        NavigationStack {
            contentView
        }
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            PageHeader(icon: "note.text", title: "노트")

            // 검색바
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                TextField("제목, 내용 검색", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .font(.system(size: 14))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.cardBg)
            .cornerRadius(AppDesign.smallCornerRadius)
            .padding(.horizontal, AppDesign.defaultPadding)
            .padding(.vertical, 12)

            if notes.isEmpty {
                EmptyStateView(
                    icon: "waveform.badge.mic",
                    title: "아직 노트가 없습니다",
                    subtitle: "미팅 탭에서 녹음을 시작하면\n노트가 자동으로 저장됩니다",
                    buttonTitle: "미팅 탭으로 이동"
                ) { onSwitchToMeetings() }
                .padding(.vertical, 60)
            } else if filteredNotes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.textTertiary)
                    Text("'\(searchText)'에 대한 결과 없음")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        ForEach(groupedNotes) { group in
                            Section {
                                VStack(spacing: 10) {
                                    ForEach(group.notes) { note in
                                        NoteCardView(note: note, onDelete: { deleteNote(note) }, onOpen: { onOpenNote(note) })
                                    }
                                }
                                .padding(.horizontal, AppDesign.defaultPadding)
                                .padding(.bottom, 20)
                            } header: {
                                HStack {
                                    Text(group.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                    Text("\(group.notes.count)개")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.horizontal, AppDesign.defaultPadding)
                                .padding(.vertical, 8)
                                .background(Color.appBackground)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func deleteNote(_ note: MeetingNote) {
        if let audioURL = note.audioFileURL {
            if FileManager.default.fileExists(atPath: audioURL.path) {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }
        modelContext.delete(note)
        try? modelContext.save()
    }
}

// MARK: - Note Row View
struct NoteCardView: View {
    let note: MeetingNote
    let onDelete: () -> Void
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

                            Text(DateFormatter.appDefault.string(from: note.createdAt))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }

                        Spacer()

                        if note.hasAIContent {
                            Label("AI", systemImage: "wand.and.stars")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.appPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.appPrimary.opacity(0.15)))
                        }
                    }

                    HStack(spacing: 14) {
                        if note.duration > 0 {
                            Label(note.duration.formattedDuration(), systemImage: "waveform")
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
                        Text(note.transcribedText.strippedMarkdown)
                            .font(.system(size: 13))
                            .foregroundColor(.textTertiary)
                            .lineLimit(2)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
        #if os(iOS)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("삭제", systemImage: "trash")
            }
        }
        #endif
    }

}

// MARK: - Legacy row (unused, kept for reference)
struct NoteRowView: View {
    let note: MeetingNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)

            Text(note.transcribedText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(DateFormatter.appDefault.string(from: note.createdAt), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                if note.duration > 0 {
                    Label(note.duration.formattedDuration(), systemImage: "waveform")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MeetingNote.self, configurations: config)

    let note1 = MeetingNote(
        title: "팀 회의",
        transcribedText: "오늘 팀 회의에서는 새로운 프로젝트에 대해 논의했습니다...",
        editedMarkdown: "# 팀 회의\n\n오늘 팀 회의에서는 새로운 프로젝트에 대해 논의했습니다...",
        duration: 1800
    )

    let note2 = MeetingNote(
        title: "클라이언트 미팅",
        transcribedText: "클라이언트와의 미팅에서 요구사항을 확인했습니다...",
        editedMarkdown: "# 클라이언트 미팅\n\n클라이언트와의 미팅에서 요구사항을 확인했습니다...",
        duration: 3600
    )

    container.mainContext.insert(note1)
    container.mainContext.insert(note2)

    return NotesListView()
        .modelContainer(container)
}
