//
//  MeetingsView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

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
        let title = "미팅 - \(DateFormatter.appDefault.string(from: Date()))"
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
                                .background(
                                    Capsule().fill(Color.appPrimary.opacity(0.15))
                                )
                        }
                    }

                    HStack(spacing: 12) {
                        if note.duration > 0 {
                            Label(note.duration.formattedDuration(), systemImage: "clock")
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
    }
}
