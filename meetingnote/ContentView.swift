//
//  ContentView.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

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
                .navigationSplitViewColumnWidth(
                    min: AppDesign.sidebarWidth,
                    ideal: AppDesign.sidebarWidth,
                    max: AppDesign.sidebarWidth
                )
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
                    NotesListView(
                        onOpenNote: { note in withAnimation { isNewRecording = false; selectedNote = note } },
                        onSwitchToMeetings: { withAnimation { selectedTab = "meetings" } }
                    )
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

#Preview {
    ContentView()
        .modelContainer(for: MeetingNote.self, inMemory: true)
        .preferredColorScheme(.dark)
}
