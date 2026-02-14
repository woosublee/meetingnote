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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark) // 다크 모드 강제
        }
        .modelContainer(for: MeetingNote.self)
    }
}
