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

    init() {
        do {
            container = try ModelContainer(for: MeetingNote.self)
        } catch {
            // 스키마 변경으로 마이그레이션 실패 시 기존 저장소 삭제 후 재생성
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first
            if let dir = appSupport,
               let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for file in files where file.lastPathComponent.hasPrefix("default.store") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            container = try! ModelContainer(for: MeetingNote.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
