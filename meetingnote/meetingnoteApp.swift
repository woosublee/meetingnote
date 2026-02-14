//
//  meetingnoteApp.swift
//  meetingnote
//
//  Created by WOOSUB LEE on 2/7/26.
//

import SwiftUI
import SwiftData

@main
struct meetingnoteApp: App {
    let container: ModelContainer

    @State private var showMigrationError = false

    init() {
        do {
            container = try ModelContainer(for: MeetingNote.self)
        } catch {
            // 마이그레이션 실패 시 빈 컨테이너로 시작하되 기존 데이터는 보존
            // 사용자에게 알림 후 수동 조치 유도
            print("⚠️ ModelContainer 초기화 실패: \(error)")
            container = try! ModelContainer(for: MeetingNote.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            _showMigrationError = State(initialValue: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .alert("데이터베이스 오류", isPresented: $showMigrationError) {
                    Button("확인", role: .cancel) {}
                } message: {
                    Text("데이터베이스 마이그레이션에 실패했습니다. 기존 데이터를 불러올 수 없어 임시 모드로 실행됩니다. 앱을 재설치하면 해결될 수 있습니다.")
                }
        }
        .modelContainer(container)
    }
}
